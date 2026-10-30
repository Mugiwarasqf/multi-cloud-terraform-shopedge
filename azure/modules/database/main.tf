# Private DNS Zone for MySQL Flexible Server
resource "azurerm_private_dns_zone" "mysql" {
  name                = "${var.project_name}.mysql.database.azure.com"
  resource_group_name = var.resource_group_name

  tags = var.common_tags
}

# Link Private DNS Zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "mysql" {
  name                  = "${var.project_name}-mysql-dns-link"
  private_dns_zone_name = azurerm_private_dns_zone.mysql.name
  virtual_network_id    = var.vnet_id
  resource_group_name   = var.resource_group_name

  tags = var.common_tags
}

# MySQL Flexible Server
resource "azurerm_mysql_flexible_server" "main" {
  name                   = "${var.project_name}-mysql-server"
  resource_group_name    = var.resource_group_name
  location               = var.location
  administrator_login    = var.db_username
  administrator_password = var.db_password

  # Place in delegated subnet + link DNS
  delegated_subnet_id = var.database_subnet_id
  private_dns_zone_id = azurerm_private_dns_zone.mysql.id

  # SKU must follow Flexible Server naming, e.g. "B_Standard_B1ms", "GP_Standard_D2s_v3"
  sku_name = var.db_sku_name

  version = "8.0.21"

  storage {
    size_gb = var.db_storage_mb / 1024
  }

  backup_retention_days        = var.db_backup_retention_days
  geo_redundant_backup_enabled = var.db_geo_redundant_backup_enabled

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-mysql-server"
    Tier = "Database"
  })

  depends_on = [azurerm_private_dns_zone_virtual_network_link.mysql]
}

# MySQL Flexible Database
resource "azurerm_mysql_flexible_database" "main" {
  name                = var.db_name
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_flexible_server.main.name
  charset             = "utf8"
  collation           = "utf8_unicode_ci"
}

# MySQL Flexible Server Configuration (optional)
resource "azurerm_mysql_flexible_server_configuration" "innodb_buffer_pool_size" {
  name                = "innodb_buffer_pool_size"
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_flexible_server.main.name
  value               = "134217728"
}
