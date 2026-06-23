# Pipeline Terraform + GitHub Actions — Data Lake en Azure

Despliega infraestructura de datos en Azure usando Terraform con CI/CD en GitHub Actions y autenticación OIDC (sin contraseñas almacenadas).

## Infraestructura que despliega

```
Resource Group: rg-jonathan-adlg2
├── Storage Account ADLS Gen2 (staccjona1)
│   ├── Filesystem: raw
│   ├── Filesystem: processed
│   └── Filesystem: curated
├── SQL Server (sqjonathan01)
│   └── Base de datos: db_Dengue
└── Azure Data Factory (dfjonathanlab01)
    └── Role: Storage Blob Data Contributor → ADLS
```

## Estructura del repositorio

```
├── .github/workflows/
│   └── terraform.yml        # Pipeline: plan en PR, apply en merge a main
├── scripts/
│   └── setup-azure.sh       # Script de configuración inicial (ejecutar 1 vez)
├── terraform/
│   ├── provider.tf          # Provider azurerm + backend remoto + OIDC
│   ├── variables.tf         # Definición de variables
│   ├── main.tf              # Recursos Azure
│   ├── outputs.tf           # Outputs del deploy
│   └── dev.tfvars           # Valores dev (sin secrets)
├── .gitignore
└── README.md
```

## Paso 1 — Prerrequisitos

```bash
az --version          # Azure CLI >= 2.50
terraform -version    # >= 1.9.0
git --version
```

## Paso 2 — Setup inicial (una sola vez)

```bash
chmod +x scripts/setup-azure.sh
./scripts/setup-azure.sh TU_USUARIO_GITHUB TU_REPO
```

El script crea automáticamente:
- Resource Group + Storage Account para el estado de Terraform
- App Registration con Federated Credentials (OIDC)
- Imprime en pantalla los 7 secrets que debes agregar en GitHub

## Paso 3 — Configurar secrets en GitHub

En **Settings → Secrets and variables → Actions** agregar:

| Secret | Descripción |
|---|---|
| `AZURE_CLIENT_ID` | App ID del App Registration (lo muestra el script) |
| `AZURE_TENANT_ID` | ID del tenant (lo muestra el script) |
| `AZURE_SUBSCRIPTION_ID` | ID de la suscripción (lo muestra el script) |
| `TFSTATE_RG` | `rg-tfstate` |
| `TFSTATE_SA` | Nombre del storage account del estado (lo muestra el script) |
| `SQL_ADMIN_USER` | Usuario admin que elijas para SQL Server |
| `SQL_ADMIN_PASSWORD` | Contraseña segura para SQL Server |

## Paso 4 — Configurar environment con aprobación manual

En **Settings → Environments** crear `production` y agregar *Required reviewers* (tu usuario). Esto hace que el `apply` espere tu aprobación antes de ejecutarse.

## Paso 5 — Uso local (opcional)

```bash
cd terraform

# Exportar variables sensibles
export TF_VAR_sql_admin_user="admon140972"
export TF_VAR_sql_admin_password="TuPasswordSegura123!"

terraform init \
  -backend-config="resource_group_name=rg-tfstate" \
  -backend-config="storage_account_name=TU_STORAGE_SA" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=pipeline-demo.tfstate"

terraform plan \
  -var-file=dev.tfvars \
  -var="my_ip_address=$(curl -s https://api.ipify.org)"

terraform apply -var-file=dev.tfvars \
  -var="my_ip_address=$(curl -s https://api.ipify.org)"
```

## Flujo del pipeline

```
Pull Request → fmt -check → init → validate → plan → (comenta el plan en el PR)
      ↓
Merge a main → plan → [aprobación manual] → apply
```

## Limpieza de recursos

```bash
cd terraform
terraform destroy -var-file=dev.tfvars \
  -var="my_ip_address=$(curl -s https://api.ipify.org)"
```

<!-- trigger pipeline -->
