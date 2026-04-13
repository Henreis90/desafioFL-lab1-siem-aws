# 🚀 AWS SIEM Lab with OpenSearch (Terraform)

![Terraform](https://img.shields.io/badge/IaC-Terraform-623CE4?logo=terraform\&logoColor=white)
![AWS](https://img.shields.io/badge/Cloud-AWS-232F3E?logo=amazon-aws\&logoColor=white)
![OpenSearch](https://img.shields.io/badge/Search-OpenSearch-005EB8?logo=opensearch\&logoColor=white)
![Security](https://img.shields.io/badge/Security-SIEM-red)
![License](https://img.shields.io/badge/License-MIT-green)

---

## 🎯 Objetivo

Este projeto demonstra como construir um **SIEM funcional na AWS utilizando serviços nativos**, com foco em:

* 📊 Observabilidade de segurança
* 🔍 Threat hunting
* 🛡️ Detecção de anomalias
* ⚙️ Infraestrutura como código (Terraform)

---

## 🧱 Arquitetura

```text
                  ┌──────────────┐
                  │   CloudTrail │
                  └──────┬───────┘
                         │
                         ▼
              ┌────────────────────┐
              │ CloudWatch Logs    │
              └─────────┬──────────┘
                        │ (Subscription Filter)
                        ▼
             ┌───────────────────────┐
             │  OpenSearch Service   │
             └─────────┬─────────────┘
                       │
         ┌─────────────┴─────────────┐
         ▼                           ▼
┌───────────────┐           ┌────────────────┐
│ Dashboards    │           │ Alerting (SNS) │
│ (Discover)    │           │                │
└───────────────┘           └────────────────┘

             ▲
             │
      ┌────────────────┐
      │ EC2 (optional) │
      │ Event generator│
      └────────────────┘
```

---

## 🛠️ Tecnologias utilizadas

* Terraform
* AWS CloudTrail
* AWS CloudWatch Logs
* Amazon OpenSearch Service
* AWS IAM
* AWS SNS
* EC2 (opcional para geração de eventos)

---

## 🚀 Deploy da infraestrutura

```bash
terraform init
terraform plan
terraform apply
```

---

## 🌐 Como acessar o OpenSearch Dashboards

Após o `terraform apply`, você terá um output com a URL do OpenSearch.

### 🔍 Opção 1 — via Terraform output

```bash
terraform output opensearch_dashboards_url
```

Exemplo:

```text
https://search-lab1-siem-xxxx.us-east-1.es.amazonaws.com/_dashboards/
```

---

### 🔍 Opção 2 — via console AWS

1. Acesse:

   * **Amazon OpenSearch Service**
2. Clique no domínio criado
3. Copie:

   * **Dashboards URL**

---

### ⚠️ Possíveis erros de acesso

Se aparecer:

```text
User: anonymous is not authorized
```

👉 Ajuste a **Access Policy do domínio** para permitir acesso ao seu usuário ou IP.

---

## 🔗 Configurar envio de logs para OpenSearch

1. Acesse:

   * CloudWatch → Log Groups

2. Selecione o log group do CloudTrail

3. Vá em:

   * **Actions → Subscription filters → Create Amazon OpenSearch Service subscription filter**

4. Configure:

   * Destino: OpenSearch
   * Role IAM (Lambda execution role)
   * Filter pattern: vazio

5. Clique em:

   * **Start streaming**

---

## 📦 Validar ingestão

No OpenSearch (Dev Tools):

```json
GET _cat/indices?v
```

Você verá algo como:

```text
cwl-2026.04.13
```

---

## 📊 Criar Index Pattern

* Vá em: Dashboards Management → Index Patterns
* Nome:

```text
cwl-*
```

* Campo de tempo:

```text
@timestamp
```

---

## 🔍 Exploração (Discover)

Exemplos de queries:

```text
eventSource: "sts.amazonaws.com"
eventSource: "s3.amazonaws.com"
eventName: "AssumeRole"
sourceIPAddress: "10."
```

---

## 📊 Dashboards sugeridos

### 🔐 1. Atividade por identidade

* Eventos por usuário
* Tipo de identidade (IAMUser / AssumedRole / AWSService)

---

### 🧠 2. Uso de serviços

* Top serviços acessados
* Ações críticas (STS, IAM, S3)

---

### 🌐 3. Origem de acesso

* Top IPs
* Interno vs externo
* Timeline por IP

---

### ⏱️ 4. Timeline de eventos

* Volume ao longo do tempo
* Identificação de picos

---

## 🚨 Alertas sugeridos

* 🔥 Uso excessivo de STS (`AssumeRole`)
* 🚨 Acesso de IP desconhecido
* 📈 Pico de eventos por usuário
* 🔓 Ações administrativas IAM
* 📦 Acesso massivo ao S3

---

## 🧪 Gerar eventos

Execute:

```bash
aws sts get-caller-identity
aws s3 ls
aws iam list-users
```

Ou use a EC2 criada no lab.

---

## 🧠 Casos de uso

* Threat Hunting
* Insider Threat Detection
* Auditoria (CVM, LGPD)
* Investigação de incidentes
* Monitoramento comportamental

---

## ⚠️ Custos

* OpenSearch pode gerar custo relevante
* CloudWatch Logs ingest + streaming também

👉 Use apenas para lab e destrua após uso:

```bash
terraform destroy
```

---

## 🚀 Próximos passos

* OpenSearch Alerting
* Integração com SOAR
* Enriquecimento de logs
* Playbooks de resposta

---

## 🤝 Contribuição

Contribuições são bem-vindas!

---

## ⭐ Se esse projeto te ajudou

Deixe uma estrela ⭐ no repositório!
