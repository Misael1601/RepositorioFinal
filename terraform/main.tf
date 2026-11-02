locals {
  tags = {
    environment = var.environment
    project     = var.project_name
    managed_by  = "terraform"
  }
}

# ── Resource Group ────────────────────────────────────────────
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.tags
}

# ── ADLS Gen2 (Storage Account con HNS habilitado) ────────────
resource "azurerm_storage_account" "adls" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = true # Activa Data Lake Gen2

  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false

  # Backup del lake: soft delete (versioning no es compatible con HNS)
  blob_properties {
    delete_retention_policy {
      days = var.backup_retention_days
    }
    container_delete_retention_policy {
      days = var.backup_retention_days
    }
  }

  tags = local.tags
}

# ── Filesystems del Data Lake ─────────────────────────────────
resource "azurerm_storage_data_lake_gen2_filesystem" "raw" {
  name               = "raw"
  storage_account_id = azurerm_storage_account.adls.id
}

resource "azurerm_storage_data_lake_gen2_filesystem" "processed" {
  name               = "processed"
  storage_account_id = azurerm_storage_account.adls.id
}

resource "azurerm_storage_data_lake_gen2_filesystem" "curated" {
  name               = "curated"
  storage_account_id = azurerm_storage_account.adls.id
}

# ── Azure SQL Server ──────────────────────────────────────────
resource "azurerm_mssql_server" "sql_server" {
  name                         = var.sql_server_name
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_user
  administrator_login_password = var.sql_admin_password
  minimum_tls_version          = "1.2"

  tags = local.tags
}

# ── Base de datos SQL (con backups automáticos) ───────────────
resource "azurerm_mssql_database" "sql_db" {
  name      = var.sql_database_name
  server_id = azurerm_mssql_server.sql_server.id
  sku_name  = var.sql_sku_name

  storage_account_type = "Local" # backups LRS: más barato para el lab

  # Point-in-time restore
  short_term_retention_policy {
    retention_days = var.backup_retention_days
  }

  # Retención de largo plazo (semanal y mensual)
  long_term_retention_policy {
    weekly_retention  = "P2W"
    monthly_retention = "P1M"
  }

  tags = local.tags
}

# ── Reglas de Firewall SQL ────────────────────────────────────

# Tu IP personal (variable MY_IP en GitHub)
resource "azurerm_mssql_firewall_rule" "my_ip" {
  name             = "AllowMyIP"
  server_id        = azurerm_mssql_server.sql_server.id
  start_ip_address = var.my_ip_address
  end_ip_address   = var.my_ip_address
}

# Permite servicios Azure (ADF, etc.). Aceptable en lab; no en producción
resource "azurerm_mssql_firewall_rule" "allow_azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.sql_server.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# ── Azure Data Factory ────────────────────────────────────────
resource "azurerm_data_factory" "adf" {
  name                = var.data_factory_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  identity {
    type = "SystemAssigned"
  }

  tags = local.tags
}

# ── Permisos: ADF puede leer/escribir en el Data Lake ─────────
resource "azurerm_role_assignment" "adf_storage_contributor" {
  scope                = azurerm_storage_account.adls.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_data_factory.adf.identity[0].principal_id
}

# ── Alerta de costos ──────────────────────────────────────────
resource "azurerm_consumption_budget_resource_group" "budget" {
  count = var.enable_budget ? 1 : 0

  name              = "budget-${var.project_name}"
  resource_group_id = azurerm_resource_group.rg.id
  amount            = var.budget_amount
  time_grain        = "Monthly"

  time_period {
    start_date = "2026-11-01T00:00:00Z"
  }

  notification {
    enabled        = true
    threshold      = 80
    operator       = "GreaterThan"
    threshold_type = "Actual"
    contact_emails = [var.alert_email]
  }

  notification {
    enabled        = true
    threshold      = 100
    operator       = "GreaterThan"
    threshold_type = "Forecasted"
    contact_emails = [var.alert_email]
  }
}

