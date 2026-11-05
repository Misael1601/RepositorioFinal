# ============================================================
# dev.tfvars — Valores del ambiente dev. NUNCA secrets aquí.
# Sensibles: GitHub Secrets (SQL_ADMIN_*) y Variables (MY_IP, ALERT_EMAIL)
# ============================================================

resource_group_name  = "rg-misael-final"
location             = "westus"
storage_account_name = "staccmisael16"
environment          = "dev"
project_name         = "datalake-lab"

sql_server_name   = "sqjona01"
sql_database_name = "Online_Retail"
sql_sku_name      = "S0"

data_factory_name = "dfmisael01"

budget_amount         = 20
backup_retention_days = 7

# verificacion del pipeline con policies y lock activos