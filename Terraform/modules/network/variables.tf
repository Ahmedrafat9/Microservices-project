variable "project_id" {
  type        = string
  description = "The ID of the project in which the network will be created"
  default     = "task-464917"
}

variable "region" {
  type        = string
  description = "The region in which the network will be created"
  default     = "us-central1"
}

variable "trusted_ip" {
  type        = list(string)
  description = "List of trusted IP CIDR blocks allowed to SSH or access health checks"
}