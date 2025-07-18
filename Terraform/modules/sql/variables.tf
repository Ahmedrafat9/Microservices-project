variable "project_id" {
  description = "The GCP project ID."
  type        = string
}

variable "db_instance" {
  description = "The name of the Cloud SQL instance."
  type        = string
}

variable "region" {
  description = "The GCP region for the Cloud SQL instance."
  type        = string
}

variable "private_network" {
  description = "The VPC network self_link for private IP connectivity."
  type        = string
}

variable "database" {
  description = "The name of the database to create."
  type        = string
}

variable "db_user" {
  description = "The username for the Cloud SQL database."
  type        = string/*  */
}

variable "db_tier" {
  description = "Database tier"
  type        = string
  default     = "db-f1-micro"
}

variable "db_disk_size" {
  description = "Database disk size in GB"
  type        = number
  default     = 20
}

variable "authorized_cidr" {
  description = "Authorized CIDR block for database access"
  type        = string
}
variable "db_password" {
  description = "Database password passed from root module"
  type        = string
}

