output "jenkins_internal_ip" {
  description = "Internal IP address of the Jenkins instance"
  value       = google_compute_instance.jenkins.network_interface[0].network_ip
}

output "jenkins_external_ip" {
  description = "External IP address of the Jenkins instance (if available)"
  value       = length(google_compute_instance.jenkins.network_interface[0].access_config) > 0 ? google_compute_instance.jenkins.network_interface[0].access_config[0].nat_ip : null
}

output "jenkins_instance_name" {
  description = "Name of the Jenkins instance"
  value       = google_compute_instance.jenkins.name
}

output "jenkins_zone" {
  description = "Zone where Jenkins instance is deployed"
  value       = google_compute_instance.jenkins.zone
}
output "jenkins_public_ip" {
  value       = google_compute_instance.jenkins.network_interface[0].access_config[0].nat_ip
  description = "Public IP address to access Jenkins"
}
