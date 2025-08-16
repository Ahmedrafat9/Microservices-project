# Add your SSH public key to a Terraform local variable


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

  metadata = {
    "block-project-ssh-keys" = "true"
  }
  network_interface {
    subnetwork         = var.subnet
    subnetwork_project = var.project_id
    #checkov:skip=CKV_GCP_40 Reason: Jenkins needs a public IP for external access
    
    access_config {} # Add public IP
  }

  

  

  tags = ["jenkins-server", "allow-ssh"]

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