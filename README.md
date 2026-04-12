# Lab 1 - SIEM Base AWS

Este laboratório cria uma base de detecção com:
- CloudTrail
- CloudWatch Logs
- SNS (alertas)

## Execução

1. terraform init
2. terraform plan
3. terraform apply

Depois gere eventos:
aws sts get-caller-identity
aws s3 ls
aws iam list-users
