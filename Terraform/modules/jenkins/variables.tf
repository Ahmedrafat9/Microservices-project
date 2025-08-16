variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "zone" {
  description = "GCP zone"
  type        = string
}

variable "network" {
  description = "VPC network name"
  type        = string
}

variable "subnet" {
  description = "Subnetwork name"
  type        = string
}

variable "machine_type" {
  description = "Machine type for Jenkins VM"
  type        = string
}

variable "trusted_ip" {
  description = "IP allowed to SSH into Jenkins"
  type        = string
}

variable "instance_name" {
  description = "Name of the Jenkins instance"
  type        = string
}

variable "disk_size" {
  description = "Boot disk size in GB"
  type        = number
}



variable "kms_key_self_link" {
  description = "Self-link of KMS key for disk encryption"
  type        = string
}



variable "jenkins_instance_image" {
  description = "OS image for Jenkins VM"
  type        = string
}

variable "environment" {
  description = "Environment label for resources (e.g., dev, prod)"
  type        = string
}
