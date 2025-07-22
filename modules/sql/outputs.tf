output "db_password_secret_id" {
  description = "Secret Manager secret ID for database password"
  value       = google_secret_manager_secret.db_password_secret.id
}

output "db_password_secret_version" {
  description = "Secret version ID for database password"
  value       = google_secret_manager_secret_version.db_password_secret_version.name
}

output "db_instance_name" {
  description = "Name of the Cloud SQL instance"
  value       = google_sql_database_instance.postgres.name
}

output "sql_database_name" {
  description = "Name of the default database created inside the instance"
  value       = google_sql_database.default.name
}

output "db_connection_name" {
  description = "Cloud SQL instance connection name (project:region:instance)"
  value       = google_sql_database_instance.postgres.connection_name
}

output "db_private_ip" {
  description = "Private IP address of the database instance"
  value       = google_sql_database_instance.postgres.private_ip_address
}

output "db_public_ip" {
  description = "Public IP address of the database instance (will be null if public disabled)"
  value       = google_sql_database_instance.postgres.public_ip_address
}

output "db_username" {
  description = "Database username used to connect"
  value       =  google_sql_user.default.name
}
