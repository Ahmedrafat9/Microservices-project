

variable "region" {
  description = "GCP region"
  type        = string
}

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "network" {
  description = "VPC network name"
  type        = string
}

variable "subnetwork" {
  description = "Subnetwork name"
  type        = string
}

variable "master_cidr" {
  description = "CIDR range for GKE master authorized networks"
  type        = string
}

variable "trusted_ip" {
  description = "Trusted CIDR for GKE master access"
  type        = string
}

variable "node_count" {
  description = "Number of nodes in the node pool"
  type        = number
}

variable "machine_type" {
  description = "Machine type for GKE nodes"
  type        = string
}
variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
  default     = "secure-gke-cluster"  # أو سيبه بدون default لو عايز تمرره دايمًا
}
variable "environment" {
  description = "Environment label for resources"
  type        = string
  default     = "dev"  # أو أي قيمة تناسبك
}
