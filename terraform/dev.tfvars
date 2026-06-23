# ============================================================
# dev.tfvars — Valores para el ambiente dev
# ⚠️  NUNCA incluir passwords ni secrets aquí.
#     Las variables sensibles se pasan como:
#       - GitHub Secrets → variables de entorno TF_VAR_*
#       - Local: export TF_VAR_sql_admin_password="tu_pass"
# ============================================================

# Infraestructura base
resource_group_name  = "rg-jonathan-adlg2"
location             = "West US"
storage_account_name = "staccjona1"
environment          = "dev"
project_name         = "datalake-lab"

# SQL Server
sql_server_name   = "sqjonathan01"
sql_database_name = "db_Dengue"

# Data Factory
data_factory_name = "dfjonathanlab01"

# ── Variables sensibles (NO van aquí) ────────────────────────
# sql_admin_user     → GitHub Secret: TF_VAR_SQL_ADMIN_USER
# sql_admin_password → GitHub Secret: TF_VAR_SQL_ADMIN_PASSWORD
# my_ip_address      → se calcula automático en el pipeline

# pipeline trigger
