# Cloud SQL Instance
resource "google_sql_database_instance" "main" {
  name             = "${var.project_name}-mysql-instance"
  database_version = var.db_version
  region           = var.gcp_region

  settings {
    tier              = var.db_tier
    availability_type = "ZONAL"
    disk_size         = var.db_disk_size
    disk_type         = var.db_disk_type
    disk_autoresize   = true

    backup_configuration {
      enabled                        = var.db_backup_enabled
      start_time                     = var.db_backup_start_time
      location                       = var.gcp_region
      binary_log_enabled             = true
      transaction_log_retention_days = 7
    }

    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = var.network_id
      enable_private_path_for_google_cloud_services = true
    }

    user_labels = var.common_labels
  }

  deletion_protection = false

  depends_on = [var.private_vpc_connection]
}

# Database
resource "google_sql_database" "main" {
  name      = var.db_name
  instance  = google_sql_database_instance.main.name
  charset   = "utf8"
  collation = "utf8_general_ci"
}

# Database User
resource "google_sql_user" "main" {
  name     = var.db_username
  instance = google_sql_database_instance.main.name
  password = var.db_password
}
