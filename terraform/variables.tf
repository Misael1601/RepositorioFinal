variable "location" {
  description = "Ubicación de los recursos en Azure"
  type        = string
  default     = "westus"
}

variable "resource_group_name" {
  description = "Nombre del resource group"
  type        = string
}

variable "storage_account_name" {
  description = "Nombre del Data Lake Storage Gen2"
  type        = string

  validation {
    condition     = length(var.storage_account_name) >= 3 && length(var.storage_account_name) <= 24
    error_message = "El nombre de la storage account debe tener entre 3 y 24 caracteres."
  }
}

variable "environment" {
  description = "Ambiente de despliegue (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
  default     = "datalake-lab"
}

# ── SQL Server ────────────────────────────────────────────────

variable "sql_server_name" {
  description = "Nombre del servidor Azure SQL"
  type        = string
}

variable "sql_admin_user" {
  description = "Usuario administrador del SQL Server"
  type        = string
  sensitive   = true
}

variable "sql_admin_password" {
  description = "Contraseña del administrador SQL (via TF_VAR o secret)"
  type        = string
  sensitive   = true
}

variable "sql_database_name" {
  description = "Nombre de la base de datos SQL"
  type        = string
}

variable "sql_sku_name" {
  description = "SKU de la BD (Basic, S0, S1...). Basic solo permite 7 días de retención PITR"
  type        = string
  default     = "S0"
}

variable "backup_retention_days" {
  description = "Días de retención de backups (PITR) y soft delete del lake. Máx 7 en Basic"
  type        = number
  default     = 7
}

# ── Data Factory ─────────────────────────────────────────────

variable "data_factory_name" {
  description = "Nombre del Azure Data Factory"
  type        = string
}

# ── Red / Firewall ────────────────────────────────────────────

variable "my_ip_address" {
  description = "Tu IP pública para la regla de firewall de SQL. En el pipeline viene de la variable MY_IP"
  type        = string
}

# ── Costos ────────────────────────────────────────────────────

variable "enable_budget" {
  description = "Crear presupuesto con alertas (desactivar si la suscripción no lo soporta)"
  type        = bool
  default     = true
}

variable "budget_amount" {
  description = "Presupuesto mensual en USD"
  type        = number
  default     = 20
}

variable "alert_email" {
  description = "Correo que recibe las alertas de costo (en el pipeline viene de la variable ALERT_EMAIL)"
  type        = string
  default     = ""
}