variable "location" {
  description = "Ubicación de los recursos en Azure"
  type        = string
  default     = "West US"
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
  sensitive   = true   # no se imprime en logs del pipeline
}

variable "sql_admin_password" {
  description = "Contraseña del administrador SQL (pasar via TF_VAR o secret)"
  type        = string
  sensitive   = true   # nunca se muestra en outputs ni logs
}

variable "sql_database_name" {
  description = "Nombre de la base de datos SQL"
  type        = string
}

# ── Data Factory ─────────────────────────────────────────────

variable "data_factory_name" {
  description = "Nombre del Azure Data Factory"
  type        = string
}

# ── Red / Firewall ────────────────────────────────────────────

variable "my_ip_address" {
  description = "Tu IP pública para la regla de firewall de SQL (nunca hardcodear en código)"
  type        = string
  # Se pasa como variable de entorno TF_VAR_my_ip_address en el pipeline
  # o como -var en local: terraform plan -var="my_ip_address=$(curl -s https://api.ipify.org)"
}
