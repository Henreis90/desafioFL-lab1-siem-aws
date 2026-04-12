# Lab 1 - SIEM Base AWS (v3)

## Objetivo

Esta versão do lab sobe a infraestrutura base em Terraform e deixa a parte mais didática para fazer pela console:

- OpenSearch Dashboards
- Metric Filters
- CloudWatch Alarms

## O que o Terraform cria

- S3 para logs do CloudTrail
- CloudTrail
- CloudWatch Logs
- IAM Role do CloudTrail para CloudWatch Logs
- SNS Topic + subscription por e-mail
- Amazon OpenSearch Service
- EC2 pequena para gerar eventos via Session Manager

## O que você vai configurar manualmente na console

- explorar o OpenSearch Dashboards
- criar dashboards de investigação
- criar Metric Filter no CloudWatch Logs
- criar CloudWatch Alarm apontando para o SNS Topic

## Atenção a custo

Este lab pode gerar custo, principalmente por causa do OpenSearch.
Sugestão:
- subir
- validar
- destruir no mesmo dia

## Execução

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

## Exemplo inicial de terraform.tfvars

```hcl
project_name         = "lab1-siem"
aws_region           = "sa-east-1"
alert_email          = "SEU_EMAIL_AQUI"
enable_opensearch    = true
enable_ec2_generator = true
allowed_ip_cidr      = "0.0.0.0/0"
instance_type        = "t3.micro"
```

## Testes iniciais

### 1. Gerar eventos pela sua máquina local

```bash
aws sts get-caller-identity
aws s3 ls
aws iam list-users
```

### 2. Gerar eventos pela EC2 via Session Manager

- EC2
- selecione a instância do lab
- Connect
- Session Manager

Depois rode:

```bash
aws sts get-caller-identity
aws s3 ls
aws iam list-users
```

## Parte manual na console

### SNS
Depois do apply, confirme o e-mail da subscription do SNS.

### CloudWatch Logs
Verifique o log group criado e confirme se os eventos do CloudTrail estão chegando.

### Metric Filter sugerido
Crie um filtro para detectar falha de login no console:
- campo eventName = ConsoleLogin
- campo errorMessage = Failed authentication

### Alarm sugerido
Crie um alarme com:
- threshold >= 1
- período de 5 minutos
- ação = SNS Topic do lab

### OpenSearch Dashboards
Use a URL de output para abrir o Dashboards e montar visualizações simples:
- ações por usuário
- eventos por horário
- chamadas IAM
- acessos S3
- falhas de login

## Destruição

```bash
terraform destroy
```
