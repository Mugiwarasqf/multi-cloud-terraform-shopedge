# Resource group: deploy into an existing one when resource_group_name is set,
# otherwise create <project_name>-<environment>-rg.
data "azurerm_resource_group" "existing" {
  count = var.resource_group_name == null ? 0 : 1
  name  = var.resource_group_name
}

resource "azurerm_resource_group" "main" {
  count    = var.resource_group_name == null ? 1 : 0
  name     = "${var.project_name}-${var.environment}-rg"
  location = var.azure_region

  tags = local.common_tags
}

locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Owner       = var.owner
    CostCenter  = var.cost_center
  }

  resource_group_name = var.resource_group_name == null ? azurerm_resource_group.main[0].name : data.azurerm_resource_group.existing[0].name
  location            = var.resource_group_name == null ? azurerm_resource_group.main[0].location : data.azurerm_resource_group.existing[0].location
}

# Random password for database
resource "random_password" "db_password" {
  length  = 16
  special = true
}

# Network Module
module "network" {
  source = "./modules/network"

  project_name         = var.project_name
  common_tags          = local.common_tags
  location             = local.location
  resource_group_name  = local.resource_group_name
  vnet_cidr            = var.vnet_cidr
  public_subnet_cidr   = var.public_subnet_cidr
  private_subnet_cidr  = var.private_subnet_cidr
  database_subnet_cidr = var.database_subnet_cidr
}

# Security Module
module "security" {
  source = "./modules/security"

  project_name        = var.project_name
  common_tags         = local.common_tags
  location            = local.location
  resource_group_name = local.resource_group_name
  vnet_cidr           = var.vnet_cidr
  public_subnet_cidr  = var.public_subnet_cidr
  private_subnet_cidr = var.private_subnet_cidr
  public_subnet_id    = module.network.public_subnet_id
  private_subnet_id   = module.network.private_subnet_id
  database_subnet_id  = module.network.database_subnet_id
}

# Database Module
module "database" {
  source = "./modules/database"

  project_name                    = var.project_name
  common_tags                     = local.common_tags
  location                        = local.location
  resource_group_name             = local.resource_group_name
  vnet_id                         = module.network.vnet_id
  database_subnet_id              = module.network.database_subnet_id
  db_sku_name                     = var.db_sku_name
  db_storage_mb                   = var.db_storage_mb
  db_name                         = var.db_name
  db_username                     = var.db_username
  db_password                     = random_password.db_password.result
  db_backup_retention_days        = var.db_backup_retention_days
  db_geo_redundant_backup_enabled = var.db_geo_redundant_backup_enabled
}

# Compute Module
module "compute" {
  source = "./modules/compute"

  project_name        = var.project_name
  common_tags         = local.common_tags
  location            = local.location
  resource_group_name = local.resource_group_name
  public_subnet_id    = module.network.public_subnet_id
  private_subnet_id   = module.network.private_subnet_id
  web_vm_size         = var.web_vm_size
  app_vm_size         = var.app_vm_size
  web_vm_count        = var.web_vm_count
  app_vm_count        = var.app_vm_count
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  database_fqdn       = module.database.database_fqdn
}
