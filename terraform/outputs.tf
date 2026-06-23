output "resource_group_name" {
  description = "Nombre del resource group creado"
  value       = azurerm_resource_group.rg.name
}

output "storage_account_name" {
  description = "Nombre del Data Lake Storage Gen2"
  value       = azurerm_storage_account.adls.name
}

output "datalake_raw" {
  description = "Filesystem 'raw' del Data Lake"
  value       = azurerm_storage_data_lake_gen2_filesystem.raw.name
}

output "datalake_processed" {
  description = "Filesystem 'processed' del Data Lake"
  value       = azurerm_storage_data_lake_gen2_filesystem.processed.name
}

output "datalake_curated" {
  description = "Filesystem 'curated' del Data Lake"
  value       = azurerm_storage_data_lake_gen2_filesystem.curated.name
}

output "sql_server_fqdn" {
  description = "FQDN del servidor SQL (para conectarse con SSMS o DBeaver)"
  value       = azurerm_mssql_server.sql_server.fully_qualified_domain_name
}

output "sql_server_name" {
  description = "Nombre del servidor SQL"
  value       = azurerm_mssql_server.sql_server.name
}

output "sql_database_name" {
  description = "Nombre de la base de datos"
  value       = azurerm_mssql_database.sql_db.name
}

output "data_factory_name" {
  description = "Nombre del Azure Data Factory"
  value       = azurerm_data_factory.adf.name   # corregido: faltaba .name
}

output "data_factory_identity" {
  description = "Principal ID de la identidad administrada del ADF"
  value       = azurerm_data_factory.adf.identity[0].principal_id
}
