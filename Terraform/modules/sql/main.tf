resource "random_password" "cloudsql_password" {
  length  = 16
  special = true
}

resource "google_secret_manager_secret" "db_password_secret" {
  project   = var.project_id
  secret_id = "cloudsql-db-password"

  replication {
    auto {}
  }

  labels = {
    service = "cloudsql"
  }
}
resource "google_compute_global_address" "private_ip_address" {
  name          = "google-managed-services-vpc"
  purpose       = "VPC_PEERING"
  network       = var.private_network   # ✅ use input variable
  project       = var.project_id   # ✅ make sure project is set

  address_type  = "INTERNAL"
  prefix_length = 16
  
}




resource "google_secret_manager_secret_version" "db_password_secret_version" {
  secret      = google_secret_manager_secret.db_password_secret.id
  secret_data = random_password.cloudsql_password.result
}
resource "google_sql_database_instance" "postgres" {
  project          = var.project_id
  name             = var.db_instance
  database_version = "POSTGRES_17"
  region           = var.region

  settings {
    # Add edition configuration to match tier requirements
   
    tier              =  "db-perf-optimized-N-2"
    availability_type = "ZONAL"  # or "REGIONAL" for HA
    
    backup_configuration {
      enabled                        = true
      start_time                     = "03:00"
      point_in_time_recovery_enabled = true
      location                       = var.region
      transaction_log_retention_days = 7
      backup_retention_settings {
        retained_backups = 30
        retention_unit   = "COUNT"
      }
    }

    ip_configuration {
      ipv4_enabled                                  = false
      private_network                              = var.private_network
      enable_private_path_for_google_cloud_services = true
      ssl_mode = "TRUSTED_CLIENT_CERTIFICATE_REQUIRED"
      # Add authorized networks if needed for specific access
      # authorized_networks {
      #   name  = "internal-network"
      #   value = "10.0.0.0/16"
      # }
    }

    disk_autoresize       = true
    disk_autoresize_limit = 100
    disk_size             = var.db_disk_size
    disk_type             = "PD_SSD"

    # Maintenance window
    maintenance_window {
      day          = 7  # Sunday
      hour         = 3  # 3 AM
      update_track = "stable"
    }

    # Query insights
    insights_config {
      query_insights_enabled  = true
      query_string_length    = 1024
      record_application_tags = true
      record_client_address  = true
    }
    database_flags{
        name  = "cloudsql.enable_pgaudit"
        value = "on"
    }
    
    # 2. Then configure pgaudit settings
    database_flags {
      name  = "pgaudit.log"
      value = "all"
    }
    
    
    # Standard PostgreSQL logging flags
    database_flags {
      name  = "log_duration"
      value = "on"
    }

    database_flags {
      name  = "log_statement"
      value = "all"
    }

    database_flags {
      name  = "log_min_error_statement"
      value = "error"
    }

    database_flags {
      name  = "log_hostname"
      value = "on"
    }

    database_flags {
      name  = "log_connections"
      value = "on"
    }

    database_flags {
      name  = "log_disconnections"
      value = "on"
    }

    database_flags {
      name  = "log_checkpoints"
      value = "on"
    }

    database_flags {
      name  = "log_lock_waits"
      value = "on"
    }

    # Additional security flags
    database_flags {
      name  = "log_min_duration_statement"
      value = "-1"  # Disabled - logs all statements regardless of duration
    }

    # SSL enforcement through database flags
       
    database_flags {
      name  = "ssl_min_protocol_version"
      value = "TLSv1.2"
    }

    # Additional security hardening flags
    database_flags {
      name  = "password_encryption"
      value = "scram-sha-256"
    }
    
    database_flags {
      name  = "log_statement_stats"
      value = "off"
    }
    
    database_flags {
      name  = "log_parser_stats"
      value = "off"
    }
    
    database_flags {
      name  = "log_planner_stats"
      value = "off"
    }
    
    database_flags {
      name  = "log_executor_stats"
      value = "off"
    }
    
  } 
 
  deletion_protection = false

  #depends_on = [google_service_networking_connection.private_vpc_connection]
}


resource "google_sql_database" "default" {
  project  = var.project_id
  name     = var.database
  instance = google_sql_database_instance.postgres.name
  
}

resource "google_sql_user" "default" {
  project  = var.project_id
  name     = var.db_user
  instance = google_sql_database_instance.postgres.name
  password = random_password.cloudsql_password.result
  
}