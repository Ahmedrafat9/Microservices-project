# Add your SSH public key to a Terraform local variable
locals {
  jenkins_ssh_key = "jenkins:${file("~/.ssh/jenkins.pub")}"
}

# Generate random encryption key for the disk
resource "random_id" "disk_encryption_key" {
  byte_length = 32
}

# Create Jenkins boot disk encrypted with CSEK
resource "google_compute_disk" "jenkins_disk" {
  name    = "jenkins-disk"
  type    = "pd-ssd"
  zone    = var.zone
  size    = var.disk_size
  project = var.project_id

  image = var.jenkins_instance_image

  disk_encryption_key {
    raw_key = random_id.disk_encryption_key.b64_std
  }

  labels = {
    environment = var.environment
    purpose     = "jenkins"
  }
}

# Create Jenkins service account
resource "google_service_account" "jenkins_sa" {
  account_id   = "jenkins-sa"
  display_name = "Jenkins Service Account"
  project      = var.project_id
}

# Assign IAM roles to Jenkins service account
resource "google_project_iam_member" "jenkins_compute_admin" {
  project = var.project_id
  role    = "roles/compute.admin"
  member  = "serviceAccount:${google_service_account.jenkins_sa.email}"
}

resource "google_project_iam_member" "jenkins_storage_admin" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.jenkins_sa.email}"
}

# checkov:skip=CKV_GCP_40 reason="Public IP is intentionally used to access Jenkins for initial setup"
resource "google_compute_instance" "jenkins" {
  name         = "jenkins-vm"
  machine_type = var.machine_type
  zone         = var.zone
  project      = var.project_id

  boot_disk {
    source                    = google_compute_disk.jenkins_disk.id
    auto_delete               = true
    disk_encryption_key_raw   = random_id.disk_encryption_key.b64_std
  }

  network_interface {
    subnetwork         = var.subnet
    subnetwork_project = var.project_id

    #access_config {} # Add public IP
  }

  metadata = {
    "ssh-keys"               = local.jenkins_ssh_key
    "block-project-ssh-keys" = "true"
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    apt-get update && apt-get install -y openjdk-17-jdk git curl gnupg2
    curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io.key | tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
    echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | tee /etc/apt/sources.list.d/jenkins.list > /dev/null
    apt-get update && apt-get install -y jenkins
    systemctl enable jenkins && systemctl start jenkins
  EOT

  tags = ["jenkins"]

  service_account {
    email  = google_service_account.jenkins_sa.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  labels = {
    environment = var.environment
    purpose     = "jenkins"
  }
}
