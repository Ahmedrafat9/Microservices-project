output "jenkins_internal_ip" {
  value = google_compute_instance.jenkins.network_interface[0].network_ip
}

output "jenkins_external_ip" {
  value = google_compute_instance.jenkins.network_interface[0].access_config[0].nat_ip
}

output "jenkins_instance_name" {
  value = google_compute_instance.jenkins.name
}

output "jenkins_zone" {
  value = google_compute_instance.jenkins.zone
}
