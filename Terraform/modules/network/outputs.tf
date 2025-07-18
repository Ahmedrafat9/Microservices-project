output "network_name" {
  value = google_compute_network.vpc.name
}

output "subnet_name" {
  value = google_compute_subnetwork.subnet.name
}

output "network_self_link" {
  value = google_compute_network.vpc.self_link
}
output "private_network_self_link" {
  value       = google_compute_subnetwork.subnet.self_link
  description = "Self link of the private subnet"
}
