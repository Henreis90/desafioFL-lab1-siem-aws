data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
  numeric = true
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_s3_bucket" "cloudtrail" {
  bucket        = lower("${var.project_name}-cloudtrail-${random_string.suffix.result}")
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "trail" {
  name              = "/${var.project_name}/cloudtrail"
  retention_in_days = 7
}

resource "aws_iam_role" "cloudtrail_to_cw" {
  name = "${var.project_name}-cloudtrail-to-cw-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "cloudtrail_to_cw" {
  name = "${var.project_name}-cloudtrail-to-cw-policy"
  role = aws_iam_role.cloudtrail_to_cw.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.trail.arn}:*"
      }
    ]
  })
}

resource "aws_cloudtrail" "main" {
  name                          = "${var.project_name}-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail.id
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.trail.arn}:*"
  cloud_watch_logs_role_arn     = aws_iam_role.cloudtrail_to_cw.arn
  is_multi_region_trail         = true
  include_global_service_events = true
  enable_log_file_validation    = true

  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }

  depends_on = [
    aws_s3_bucket_policy.cloudtrail,
    aws_iam_role_policy.cloudtrail_to_cw
  ]
}

resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_security_group" "opensearch" {
  count       = var.enable_opensearch ? 1 : 0
  name        = "${var.project_name}-opensearch-sg"
  description = "SG para OpenSearch"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ip_cidr]
  }

  egress {
    description = "Saida"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

locals {
  opensearch_domain_name = replace(lower("${var.project_name}-${random_string.suffix.result}"), "_", "-")
}

resource "aws_opensearch_domain" "this" {
  count          = var.enable_opensearch ? 1 : 0
  domain_name = local.opensearch_domain_name
  engine_version = "OpenSearch_2.11"

  cluster_config {
    instance_type  = "t3.small.search"
    instance_count = 1
  }

  ebs_options {
    ebs_enabled = true
    volume_type = "gp3"
    volume_size = 10
  }

  encrypt_at_rest {
    enabled = true
  }

  node_to_node_encryption {
    enabled = true
  }

  domain_endpoint_options {
    enforce_https = true
  }

 # vpc_options {
 #   subnet_ids         = [data.aws_subnets.default.ids[0]]
 #   security_group_ids = [aws_security_group.opensearch[0].id]
 # }

  access_policies = jsonencode({
  Version = "2012-10-17"
  Statement = [
    {
      Effect = "Allow"
      Principal = "*"
      Action = "es:ESHttp*"
      Resource = "arn:aws:es:${var.aws_region}:${data.aws_caller_identity.current.account_id}:domain/${local.opensearch_domain_name}/*"
      Condition = {
        IpAddress = {
          "aws:SourceIp" = var.allowed_ip_cidr
        }
      }
    }
  ]
})
}

data "aws_ami" "amazon_linux" {
  count       = var.enable_ec2_generator ? 1 : 0
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_iam_role" "ec2_ssm" {
  count = var.enable_ec2_generator ? 1 : 0
  name  = "${var.project_name}-ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Effect = "Allow"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_ssm_core" {
  count      = var.enable_ec2_generator ? 1 : 0
  role       = aws_iam_role.ec2_ssm[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "ec2_event_generation" {
  count = var.enable_ec2_generator ? 1 : 0
  name  = "${var.project_name}-ec2-event-generation"
  role  = aws_iam_role.ec2_ssm[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sts:GetCallerIdentity",
          "s3:ListAllMyBuckets",
          "iam:ListUsers"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_ssm" {
  count = var.enable_ec2_generator ? 1 : 0
  name  = "${var.project_name}-ec2-ssm-profile"
  role  = aws_iam_role.ec2_ssm[0].name
}

resource "aws_security_group" "ec2" {
  count       = var.enable_ec2_generator ? 1 : 0
  name        = "${var.project_name}-ec2-sg"
  description = "Sem SSH; acesso via SSM"
  vpc_id      = data.aws_vpc.default.id

  egress {
    description = "Saida"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "generator" {
  count                  = var.enable_ec2_generator ? 1 : 0
  ami                    = data.aws_ami.amazon_linux[0].id
  instance_type          = var.instance_type
  subnet_id              = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.ec2[0].id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_ssm[0].name

  user_data = <<-EOF
              #!/bin/bash
              dnf install -y awscli
              echo "Lab EC2 pronta para gerar eventos via SSM." > /etc/motd
              EOF

  tags = {
    Name = "${var.project_name}-event-generator"
  }
}
