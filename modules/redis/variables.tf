variable "project_id" {
  type = string
  description = "The ID of the project in which the Redis instance will be created"
  default = "task-464917"
}
variable "region" {
  type = string
  description = "The region in which the Redis instance will be created"
  default = "us-central1"
}
variable "network" {
  type = string
  description = "The name of the network in which the Redis instance will be created"
  default = "secure-vpc"
}
variable "tier" {
  default = "STANDARD_HA"
}
variable "memory_size_gb" {
  default = 2
}