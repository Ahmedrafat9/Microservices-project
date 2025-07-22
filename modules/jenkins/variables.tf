variable "jenkins_instance_image" {
  description = "The Google Compute Engine image to use for the Jenkins instance."
  type        = string
  default     = "projects/debian-cloud/global/images/family/debian-11"
}

variable "project_id" {
  description = "The GCP project ID."
  type        = string
}

variable "region" {
  description = "The GCP region for the Jenkins instance."
  type        = string
}

variable "zone" {
  description = "The GCP zone for the Jenkins instance."
  type        = string
}

variable "machine_type" {
  description = "The machine type for the Jenkins instance."
  type        = string
  default     = "e2-medium"
}

variable "network" {
  description = "The VPC network self_link for the Jenkins instance."
  type        = string
}

variable "subnet" {
  description = "The subnetwork self_link for the Jenkins instance."
  type        = string
}


variable "trusted_ip" {
  description = "Trusted IP for firewall rule to access Jenkins"
  type        = string
}

variable "disk_size_gb" {
  description = "Boot disk size for Jenkins VM"
  type        = number
  default     = 20
}

variable "kms_key_self_link" {
  description = "KMS key self link for disk encryption"
  type        = string
}

variable "service_account_email" {
  description = "Service account email to attach to the Jenkins VM"
  type        = string
}
variable "kms_location" {
  description = "Location of the KMS KeyRing"
  type        = string
  default     = "global"
}


variable "disk_size" {
  description = "Size of the Jenkins disk in GB"
  type        = number
  default     = 20
}

variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
  default     = "dev"
}
variable "ssh_public_key_path" {
  description = "Path to the SSH public key to access the Jenkins instance"
  type        = string
  default     = "~/.ssh/jenkins.pub"
}
