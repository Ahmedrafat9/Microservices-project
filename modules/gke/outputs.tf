
output "cluster_name" {
  value = google_container_cluster.gke.name
}

output "cluster_endpoint" {
  value = google_container_cluster.gke.endpoint
}

output "workload_identity_pool" {
  value = google_container_cluster.gke.workload_identity_config[0].workload_pool
}


