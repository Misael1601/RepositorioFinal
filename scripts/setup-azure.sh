#!/usr/bin/env bash
# ============================================================
# setup-azure.sh — Configuración inicial ONE-TIME
# Ejecutar UNA SOLA VEZ antes de usar el pipeline.
# Uso: ./scripts/setup-azure.sh <TU_ORG> <TU_REPO>
# Ejemplo: ./scripts/setup-azure.sh JonathanStudent lab-terraform
# ============================================================
set -euo pipefail

ORG="${1:?Uso: $0 <github_org_o_usuario> <nombre_repo>}"
REPO="${2:?Uso: $0 <github_org_o_usuario> <nombre_repo>}"

# ── Configuración ─────────────────────────────────────────────
TFSTATE_RG="rg-tfstate"
TFSTATE_SA="sttfstate$(openssl rand -hex 4)"   # nombre único global
LOCATION="eastus2"
APP_NAME="github-terraform-${REPO}"

echo "=================================================="
echo " SETUP INICIAL — Terraform + GitHub Actions"
echo "  Org/Usuario : $ORG"
echo "  Repositorio : $REPO"
echo "  Backend RG  : $TFSTATE_RG"
echo "  Backend SA  : $TFSTATE_SA"
echo "=================================================="
echo ""

# 1. Verificar login en Azure
echo "▶ [1/6] Verificando autenticación en Azure..."
az account show --output table
SUB_ID=$(az account show --query id --output tsv)
TENANT_ID=$(az account show --query tenantId --output tsv)
echo "   Suscripción: $SUB_ID"
echo "   Tenant:      $TENANT_ID"
echo ""

# 2. Crear backend remoto para el estado de Terraform
echo "▶ [2/6] Creando backend remoto para estado Terraform..."
az group create --name "$TFSTATE_RG" --location "$LOCATION" --output none
az storage account create \
  --name "$TFSTATE_SA" \
  --resource-group "$TFSTATE_RG" \
  --sku Standard_LRS \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false \
  --output none
az storage container create \
  --name tfstate \
  --account-name "$TFSTATE_SA" \
  --auth-mode login \
  --output none
echo "   ✅ Backend: $TFSTATE_SA / container: tfstate"
echo ""

# 3. Crear App Registration y Service Principal
echo "▶ [3/6] Creando App Registration para OIDC..."
APP_ID=$(az ad app create --display-name "$APP_NAME" --query appId --output tsv)
SP_ID=$(az ad sp create --id "$APP_ID" --query id --output tsv)
echo "   ✅ APP_ID = $APP_ID"
echo "   ✅ SP_ID  = $SP_ID"
echo ""

# 4. Asignar rol Contributor
echo "▶ [4/6] Asignando rol Contributor sobre la suscripción..."
az role assignment create \
  --assignee "$APP_ID" \
  --role Contributor \
  --scope "/subscriptions/$SUB_ID" \
  --output none
echo "   ✅ Rol asignado"
echo ""

# 5. Crear Federated Credentials (OIDC)
echo "▶ [5/6] Creando Federated Credentials para GitHub Actions..."

# Para push a main
az ad app federated-credential create --id "$APP_ID" --parameters "{
  \"name\": \"github-main\",
  \"issuer\": \"https://token.actions.githubusercontent.com\",
  \"subject\": \"repo:${ORG}/${REPO}:ref:refs/heads/main\",
  \"audiences\": [\"api://AzureADTokenExchange\"]
}" --output none

# Para pull requests
az ad app federated-credential create --id "$APP_ID" --parameters "{
  \"name\": \"github-pr\",
  \"issuer\": \"https://token.actions.githubusercontent.com\",
  \"subject\": \"repo:${ORG}/${REPO}:pull_request\",
  \"audiences\": [\"api://AzureADTokenExchange\"]
}" --output none

# Para el environment production (job apply)
az ad app federated-credential create --id "$APP_ID" --parameters "{
  \"name\": \"github-env-production\",
  \"issuer\": \"https://token.actions.githubusercontent.com\",
  \"subject\": \"repo:${ORG}/${REPO}:environment:production\",
  \"audiences\": [\"api://AzureADTokenExchange\"]
}" --output none

echo "   ✅ 3 Federated Credentials creadas (main, pr, production)"
echo ""

# 6. Mostrar resumen de secrets para GitHub
echo "▶ [6/6] Secrets para configurar en GitHub:"
echo "   Settings → Secrets and variables → Actions → New repository secret"
echo ""
echo "   ┌─────────────────────────┬──────────────────────────────────────────┐"
echo "   │ Secret Name             │ Valor                                    │"
echo "   ├─────────────────────────┼──────────────────────────────────────────┤"
printf "   │ AZURE_CLIENT_ID         │ %-40s │\n" "$APP_ID"
printf "   │ AZURE_TENANT_ID         │ %-40s │\n" "$TENANT_ID"
printf "   │ AZURE_SUBSCRIPTION_ID   │ %-40s │\n" "$SUB_ID"
printf "   │ TFSTATE_RG              │ %-40s │\n" "$TFSTATE_RG"
printf "   │ TFSTATE_SA              │ %-40s │\n" "$TFSTATE_SA"
echo "   │ SQL_ADMIN_USER          │ (el usuario que elijas)                  │"
echo "   │ SQL_ADMIN_PASSWORD      │ (una contraseña segura)                  │"
echo "   └─────────────────────────┴──────────────────────────────────────────┘"
echo ""
echo "   ⚠️  Los últimos 2 secrets (SQL_ADMIN_USER y SQL_ADMIN_PASSWORD)"
echo "      debes ingresarlos manualmente en GitHub con los valores que quieras."
echo ""
echo "=================================================="
echo " ✅ Setup completo. Próximo paso:"
echo "    git add -A && git commit -m 'feat: terraform pipeline setup'"
echo "    git push origin main"
echo "=================================================="
