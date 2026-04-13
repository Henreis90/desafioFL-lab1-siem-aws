variable "aws_region" {
  description = "Região AWS"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefixo do projeto"
  type        = string
  default     = "lab1-siem"
}

variable "alert_email" {
  default = "expert.its90@gmail.com"
  type        = string
}

variable "enable_opensearch" {
  description = "Habilita o OpenSearch"
  type        = bool
  default     = true
}

variable "enable_ec2_generator" {
  description = "Habilita a EC2 geradora de eventos"
  type        = bool
  default     = true
}

variable "allowed_ip_cidr" {
  description = "CIDR permitido para acesso HTTPS ao OpenSearch"
  type        = string
  default     = "0.0.0.0/0"
}

variable "instance_type" {
  description = "Tipo da instância EC2 do gerador de eventos"
  type        = string
  default     = "t3.micro"
}
