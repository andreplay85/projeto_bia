## Projeto base para o evento Imersão AWS & IA que irei realizar.

### Período do evento: 27/09 e 28/09/2025 (Online e ao Vivo às 20h)

[>> Página de Inscrição do evento](https://org.imersaoaws.com.br/github/readme)

#### Para rodar as migrations no container ####
```
docker compose exec server bash -c 'npx sequelize db:migrate'
```

---

## 🚀 Deploy Automatizado com IA

### Scripts de Deploy

#### `deploy-ia.sh` - Deploy Completo com Monitoramento
Script inteligente que executa todo o fluxo de deploy automaticamente:

**Funcionalidades:**
- 🔍 Identifica ALB automaticamente na AWS
- 📝 Atualiza Dockerfile com URL do ALB
- 🔨 Build da imagem Docker com versionamento (timestamp)
- ⬆️ Push para ECR (versão específica + latest)
- 🚀 Atualiza serviço ECS com force-new-deployment
- ⏳ Monitora deployment por até 10 minutos
- 🧪 Testa aplicação via endpoint `/api/versao`

**Uso:**
```bash
./deploy-ia.sh
```

**Quando executar:**
- Após criar um novo ALB
- Sempre que quiser fazer deploy de uma nova versão da aplicação

#### `deploy.sh` - Deploy Simples
Script básico de deploy sem monitoramento:

**Funcionalidades:**
- 📦 Autenticação no ECR
- 🔨 Build da imagem
- ⬆️ Push para ECR

**Uso:**
```bash
./deploy.sh
```

---

### ⚠️ Importante

**Execução Manual Necessária:**
Os scripts precisam ser executados manualmente. Não há automação via EventBridge/Lambda configurada devido a requisitos de permissões IAM.

**Versionamento:**
Cada deploy gera uma versão única no formato `YYYYMMDD-HHMMSS` (ex: `20260214-142747`), permitindo rastreabilidade e rollback se necessário.

**Requisitos:**
- AWS CLI configurado
- Docker instalado
- Permissões para ECR e ECS
- ALB criado e ativo

