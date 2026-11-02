#!/usr/bin/env bash
# ============================================================
# setup-azure.sh — Configuración inicial (una vez por cuenta/proyecto)
# Uso: ./scripts/setup-azure.sh <ORG_O_USUARIO_GITHUB> <REPO>
# En Windows ejecútalo desde Git Bash o WSL.
# Usa Managed Identity (no requiere App Registration en Entra ID).
# ============================================================
set -euo pipefail
export MSYS_NO_PATHCONV=1 

ORG="${1:?Uso: $0 <github_org_o_usuario> <nombre_repo>}"
REPO="${2:?Uso: $0 <github_org_o_usuario> <nombre_repo>}"

TFSTATE_RG="rg-tfstate"
TFSTATE_SA="sttfstate$(openssl rand -hex 4)"   # nombre único global
LOCATION="westus"                               # región permitida por la política de la suscripción
IDENTITY_NAME="id-github-terraform-${REPO}"

echo "▶ [1/6] Verificando autenticación en Azure..."
az account show --output table
SUB_ID=$(az account show --query id --output tsv)
TENANT_ID=$(az account show --query tenantId --output tsv)

echo "▶ [2/6] Creando backend remoto para el estado de Terraform..."
az group create --name "$TFSTATE_RG" --location "$LOCATION" --output none
az storage account create \
  --name "$TFSTATE_SA" \
  --resource-group "$TFSTATE_RG" \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false \
  --output none
az storage account blob-service-properties update \
  --account-name "$TFSTATE_SA" \
  --resource-group "$TFSTATE_RG" \
  --enable-versioning true \
  --output none
az storage container create \
  --name tfstate \
  --account-name "$TFSTATE_SA" \
  --auth-mode key \
  --output none
echo "   ✅ Backend: $TFSTATE_SA / container: tfstate (con versioning)"

echo "▶ [3/6] Creando Managed Identity para OIDC..."
az identity create \
  --name "$IDENTITY_NAME" \
  --resource-group "$TFSTATE_RG" \
  --location "$LOCATION" \
  --output none
CLIENT_ID=$(az identity show --name "$IDENTITY_NAME" --resource-group "$TFSTATE_RG" --query clientId --output tsv)
PRINCIPAL_ID=$(az identity show --name "$IDENTITY_NAME" --resource-group "$TFSTATE_RG" --query principalId --output tsv)
echo "   ✅ CLIENT_ID = $CLIENT_ID"

echo "▶ [4/6] Asignando roles sobre la suscripción..."
echo "   (esperando 30s a que la identidad se propague)"
sleep 30
# Contributor: crea recursos. User Access Administrator: permite los
# azurerm_role_assignment (ADF y usuarios de RBAC).
for ROLE in "Contributor" "User Access Administrator"; do
  az role assignment create \
    --assignee-object-id "$PRINCIPAL_ID" \
    --assignee-principal-type ServicePrincipal \
    --role "$ROLE" \
    --scope "/subscriptions/$SUB_ID" \
    --output none
  echo "   ✅ $ROLE"
done

echo "▶ [5/6] Creando Federated Credentials (OIDC)..."
create_cred () {
  az identity federated-credential create \
    --name "$1" \
    --identity-name "$IDENTITY_NAME" \
    --resource-group "$TFSTATE_RG" \
    --issuer "https://token.actions.githubusercontent.com" \
    --subject "$2" \
    --audiences "api://AzureADTokenExchange" \
    --output none
}
create_cred "github-main"           "repo:${ORG}/${REPO}:ref:refs/heads/main"
create_cred "github-pr"             "repo:${ORG}/${REPO}:pull_request"
create_cred "github-env-production" "repo:${ORG}/${REPO}:environment:production2"
echo "   ✅ 3 credenciales creadas (main, pr, production)"

echo "▶ [6/6] Configura en GitHub (Settings → Secrets and variables → Actions)"
echo ""
echo "   SECRETS:"
echo "     AZURE_CLIENT_ID        = $CLIENT_ID"
echo "     AZURE_TENANT_ID        = $TENANT_ID"
echo "     AZURE_SUBSCRIPTION_ID  = $SUB_ID"
echo "     TFSTATE_RG             = $TFSTATE_RG"
echo "     TFSTATE_SA             = $TFSTATE_SA"
echo "     SQL_ADMIN_USER         = (el que elijas)"
echo "     SQL_ADMIN_PASSWORD     = (contraseña segura)"
echo ""
echo "   VARIABLES (pestaña Variables):"
echo "     MY_IP        = tu IP pública (curl https://api.ipify.org)"
echo "     ALERT_EMAIL  = correo para alertas de costo"