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

data "google_iam_policy" "kms_compute_agent" {
  binding {
    role = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
    members = [
      "serviceAccount:service-${data.google_project.current.number}@compute-system.iam.gserviceaccount.com"
    ]
  }
}

resource "google_kms_crypto_key_iam_policy" "compute_agent_binding" {
  crypto_key_id = "projects/${var.project_id}/locations/global/keyRings/terraform-keyring/cryptoKeys/jenkins-key"
  policy_data   = data.google_iam_policy.kms_compute_agent.policy_data
  
  depends_on = [
    time_sleep.wait_for_service_account,
    google_project_service.cloudkms_api
  ]
}

# ====================================================================
# BIND KMS KEY ROLE TO JENKINS SERVICE ACCOUNT (optional)
# ====================================================================
resource "google_kms_crypto_key_iam_binding" "jenkins_kms_binding" {
  crypto_key_id = "projects/${var.project_id}/locations/global/keyRings/terraform-keyring/cryptoKeys/jenkins-key"
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  members       = [
    "serviceAccount:${google_service_account.jenkins_sa.email}"
  ]
  
  depends_on = [google_project_service.cloudkms_api]
}

# ====================================================================
# USING CMEK FOR BETTER KEY MANAGEMENT
# ====================================================================
# CMEK is managed through the KMS key defined elsewhere in your infrastructure
# This provides better key management, rotation, and access control than CSEK

# ====================================================================
# WAIT FOR KMS POLICY PROPAGATION
# ====================================================================
resource "time_sleep" "wait_for_kms" {
  depends_on      = [google_kms_crypto_key_iam_policy.compute_agent_binding]
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
  #checkov:skip=CKV_GCP_38:CMEK is used instead of CSEK (preferred for key rotation and security)
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
  #checkov:skip=CKV_GCP_38:CMEK is used instead of CSEK (preferred for key rotation and security)
  
  boot_disk {
    source      = google_compute_disk.jenkins_disk.id
    auto_delete = true
    # Boot disk inherits CMEK encryption from the source disk
  }
  
  metadata = {
    "block-project-ssh-keys" = "true"
    "enable-oslogin"         = "TRUE"  # Enhanced security with OS Login
  }
  #checkov:skip=CKV_GCP_40:Jenkins requires a public IP, risk mitigated with firewall rules
  network_interface {
    subnetwork         = var.subnet
    subnetwork_project = var.project_id
    access_config {}  # Public IP - but restricted by firewall
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
