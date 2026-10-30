locals {
  common_labels = {
    environment = var.environment
    project     = var.project_name
    managed_by  = "terraform"
    owner       = replace(lower(var.owner), " ", "-")
    cost_center = replace(lower(var.cost_center), " ", "-")
  }
}

# Enable required APIs. They stay enabled on destroy so other resources in the
# project that rely on them keep working.
resource "google_project_service" "compute" {
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "sql" {
  service            = "sqladmin.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "servicenetworking" {
  service            = "servicenetworking.googleapis.com"
  disable_on_destroy = false
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
  gcp_region           = var.gcp_region
  public_subnet_cidr   = var.public_subnet_cidr
  private_subnet_cidr  = var.private_subnet_cidr
  database_subnet_cidr = var.database_subnet_cidr

  depends_on = [
    google_project_service.compute,
    google_project_service.servicenetworking
  ]
}

# Security Module
module "security" {
  source = "./modules/security"

  project_name = var.project_name
  network_name = module.network.network_name
  vpc_cidr     = var.vpc_cidr
}

# Database Module
module "database" {
  source = "./modules/database"

  project_name           = var.project_name
  common_labels          = local.common_labels
  gcp_region             = var.gcp_region
  network_id             = module.network.network_id
  private_vpc_connection = module.network.private_vpc_connection
  db_version             = var.db_version
  db_tier                = var.db_tier
  db_disk_size           = var.db_disk_size
  db_disk_type           = var.db_disk_type
  db_backup_enabled      = var.db_backup_enabled
  db_backup_start_time   = var.db_backup_start_time
  db_name                = var.db_name
  db_username            = var.db_username
  db_password            = random_password.db_password.result

  depends_on = [google_project_service.sql]
}

# Compute Module
module "compute" {
  source = "./modules/compute"

  project_name        = var.project_name
  common_labels       = local.common_labels
  gcp_region          = var.gcp_region
  gcp_zone            = var.gcp_zone
  public_subnet_id    = module.network.public_subnet_id
  private_subnet_id   = module.network.private_subnet_id
  web_machine_type    = var.web_machine_type
  app_machine_type    = var.app_machine_type
  web_instance_count  = var.web_instance_count
  app_instance_count  = var.app_instance_count
  database_private_ip = module.database.database_private_ip_address
}
