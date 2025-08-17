# ====================================================================
# ENABLE REQUIRED APIS FIRST
# ====================================================================
resource "google_project_service" "compute_api" {
  project = var.project_id
  service = "compute.googleapis.com"
  
  disable_dependent_services = true
  disable_on_destroy         = false
}

resource "google_project_service" "cloudkms_api" {
  project = var.project_id
  service = "cloudkms.googleapis.com"
  
  disable_dependent_services = true
  disable_on_destroy         = false
}

# ====================================================================
# CREATE JENKINS SERVICE ACCOUNT
# ====================================================================
resource "google_service_account" "jenkins_sa" {
  account_id   = "jenkins-sa"
  display_name = "Jenkins Service Account"
  project      = var.project_id
  
  depends_on = [google_project_service.compute_api]
}

# ====================================================================
# GRANT IAM ROLES TO JENKINS SERVICE ACCOUNT
# ====================================================================
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

# ====================================================================
# COMPUTE ENGINE SERVICE AGENT (needed for CMEK disk creation)
# ====================================================================
data "google_project" "current" {
  project_id = var.project_id
}

# Create a dummy compute resource to trigger service account creation
resource "google_compute_address" "dummy_trigger" {
  name    = "dummy-address-trigger"
  project = var.project_id
  region  = substr(var.zone, 0, length(var.zone) - 2)  # Extract region from zone
  
  depends_on = [google_project_service.compute_api]
  
  lifecycle {
    ignore_changes = all
  }
}

# Wait for the service account to be created
resource "time_sleep" "wait_for_service_account" {
  depends_on      = [google_compute_address.dummy_trigger]
  create_duration = "30s"
}

# ====================================================================
# GIVE KMS PERMISSIONS
# ====================================================================
# Grant Jenkins SA and Compute Engine service agent the cryptoKeyDecrypter role
resource "google_kms_crypto_key_iam_binding" "jenkins_kms_decrypter" {
  crypto_key_id = "projects/${var.project_id}/locations/global/keyRings/terraform-keyring/cryptoKeys/jenkins-key"
  role          = "roles/cloudkms.cryptoKeyDecrypter"
  members = [
    "serviceAccount:jenkins-sa@${var.project_id}.iam.gserviceaccount.com",
    "serviceAccount:service-${data.google_project.current.number}@compute-system.iam.gserviceaccount.com"
  ]

  depends_on = [google_project_service.cloudkms_api]
}

# Jenkins SA Encrypter/Decrypter (optional)
resource "google_kms_crypto_key_iam_binding" "jenkins_kms_binding" {
  crypto_key_id = "projects/${var.project_id}/locations/global/keyRings/terraform-keyring/cryptoKeys/jenkins-key"
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  members       = [
    "serviceAccount:${google_service_account.jenkins_sa.email}"
  ]
  
  depends_on = [google_project_service.cloudkms_api]
}

# ====================================================================
# WAIT FOR KMS POLICY PROPAGATION
# ====================================================================
resource "time_sleep" "wait_for_kms" {
  depends_on      = [
    google_kms_crypto_key_iam_binding.jenkins_kms_decrypter,
    google_kms_crypto_key_iam_binding.jenkins_kms_binding
  ]
  create_duration = "10s"
}

# ====================================================================
# CREATE JENKINS BOOT DISK WITH CMEK
# ====================================================================
resource "google_compute_disk" "jenkins_disk" {
  depends_on = [time_sleep.wait_for_kms]
  
  name    = "jenkins-disk"
  type    = "pd-ssd"
  zone    = var.zone
  size    = var.disk_size
  project = var.project_id
  image   = var.jenkins_instance_image

  disk_encryption_key {
    kms_key_self_link = "projects/${var.project_id}/locations/global/keyRings/terraform-keyring/cryptoKeys/jenkins-key"
  }
  
  labels = {
    environment = var.environment
    purpose     = "jenkins"
  }
}

# ====================================================================
# CREATE JENKINS VM WITH CMEK-ENCRYPTED BOOT DISK
# ====================================================================
resource "google_compute_instance" "jenkins" {
  name         = "jenkins-vm"
  machine_type = var.machine_type
  zone         = var.zone
  project      = var.project_id
  
  boot_disk {
    source      = google_compute_disk.jenkins_disk.id
    auto_delete = true
  }
  
  metadata = {
    "block-project-ssh-keys" = "true"
    "enable-oslogin"         = "TRUE"
  }

  network_interface {
    subnetwork         = var.subnet
    subnetwork_project = var.project_id
    access_config {}  # Public IP
  }
  
  tags = ["jenkins-server", "allow-ssh", "allow-jenkins"]
  
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
