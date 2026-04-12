output "cloudtrail_bucket_name" {
  value = aws_s3_bucket.cloudtrail.bucket
}

output "cloudwatch_log_group_name" {
  value = aws_cloudwatch_log_group.trail.name
}

output "sns_topic_arn" {
  value = aws_sns_topic.alerts.arn
}

output "opensearch_domain_endpoint" {
  value       = var.enable_opensearch ? aws_opensearch_domain.this[0].endpoint : null
  description = "Endpoint do OpenSearch"
}

output "opensearch_dashboards_url" {
  value       = var.enable_opensearch ? "https://${aws_opensearch_domain.this[0].endpoint}/_dashboards/" : null
  description = "URL do OpenSearch Dashboards"
}

output "ec2_instance_id" {
  value       = var.enable_ec2_generator ? aws_instance.generator[0].id : null
  description = "Instância EC2 para geração de eventos"
}
