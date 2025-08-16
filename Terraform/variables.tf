variable "project_id" {
  description = "The ID of the project in which the resources will be created"
  type        = string
}

variable "region" {
  description = "The region in which the resources will be created"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The zone in which the resources will be created"
  type        = string
  default     = "us-central1-a"
}

variable "master_cidr" {
  type        = string
  description = "CIDR range for GKE master authorized networks"
  default     = "172.16.0.0/28"
}

variable "trusted_ip" {
  default = "197.49.66.118/32"
}


variable "node_count" {
  type        = number
  description = "Number of nodes in the GKE cluster"
  default     = 3
}

variable "machine_type" {
  type        = string
  description = "Machine type for GKE nodes"
  default     = "e2-standard-2"
}

variable "db_user" {
  type        = string
  description = "Cloud SQL DB user"
  default     = "app_user"
}

variable "database" {
  type        = string
  description = "Cloud SQL database name"
  default     = "app_db"
}

variable "redis_tier" {
  type        = string
  description = "Redis tier"
  default     = "BASIC"
}

variable "redis_memory" {
  type        = number
  description = "Redis memory size in GB"
  default     = 1
}

variable "jenkins_machine_type" {
  type        = string
  description = "Machine type for Jenkins instance"
  default     = "e2-medium"
}

variable "jenkins_disk_size" {
  type        = number
  description = "Disk size for Jenkins instance (GB)"
  default     = 60
}
variable "db_instance" {
  description = "Cloud SQL instance name"
  type        = string
}

variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
}

variable "service_account_email" {
  description = "Service account email for Jenkins"
  type        = string
}
variable "kms_key_self_link" {
  description = "Self link of the KMS key used to encrypt resources like disks or secrets"
  type        = string
}

variable "tf_state_bucket" {
  description = "Name of the GCS bucket used for storing the Terraform state"
  type        = string
}
variable "cloudsql_instance_name" {
  description = "The name for the Google Cloud SQL instance."
  type        = string
  default     = "my-app-db-instance" 
}


variable "subnet" {
  description = "Subnetwork self_link to deploy Jenkins into"
  type        = string
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key file for Jenkins VM"
  type        = string
}
variable "instance_name" {
  description = "Name of the Jenkins VM instance"
  type        = string
  default     = "jenkins-server"
}



variable "environment" {
  description = "Environment label for Jenkins resources"
  type        = string
  default     = "dev"
}
variable "jenkins_instance_image" {
  description = "Image to use for Jenkins VM"
  type        = string
  default     = "projects/ubuntu-os-cloud/global/images/ubuntu-2204-lts"
}

variable "jenkins_instance_image_family" {
  description = "Image family to use for Jenkins VM"
  type        = string
  default     = "ubuntu-2204-lts"
}
