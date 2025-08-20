terraform {
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.42.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}
provider "google-beta" {
  project = var.project_id
  region  = var.region
}
provider "google" {
  project = "my-project"
  region  = "us-central1"
}

# -------- KMS Key Ring (in bucket region) --------
resource "google_kms_key_ring" "terraform_keyring" {
  name     = "terraform-keyring"
  location = "us-central1"  # must match bucket region
  project  = var.project_id
}

# -------- KMS Crypto Key --------
resource "google_kms_crypto_key" "terraform_key" {
  name     = "terraform-key"
  key_ring = google_kms_key_ring.terraform_keyring.id
  purpose  = "ENCRYPT_DECRYPT"
  rotation_period = "7776000s"  # 90 days
  lifecycle {
    prevent_destroy = true
  }
}

# -------- GCS Bucket for Terraform State --------
resource "google_storage_bucket" "terraform_state" {
  name                        = "my-project-tf-state"
  location                    = "US-CENTRAL1"  # must match KMS region
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = true
  }

  encryption {
    default_kms_key_name = google_kms_crypto_key.terraform_key.id
  }
}

# -------- Terraform Service Account --------
locals {
  terraform_sa_email = "terraform-sa@task-464917.iam.gserviceaccount.com"
}

# -------- Grant SA access to the bucket --------
resource "google_storage_bucket_iam_member" "terraform_sa_access" {
  bucket = google_storage_bucket.terraform_state.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${local.terraform_sa_email}"
}


resource "google_project_service" "compute" {
  project = var.project_id
  service = "compute.googleapis.com"
}
module "apis" {
  source = "./modules/apis"
  project_id = var.project_id
}

resource "google_project_service" "sqladmin" {
  project = var.project_id
  service = "sqladmin.googleapis.com"
}

resource "google_project_service" "secretmanager" {
  project = var.project_id
  service = "secretmanager.googleapis.com"
}

resource "google_project_service" "servicenetworking" {
  project = var.project_id
  service = "servicenetworking.googleapis.com"
}

resource "google_project_service" "container" {
  project = var.project_id
  service = "container.googleapis.com"
}

resource "google_project_service" "redis" {
  project = var.project_id
  service = "redis.googleapis.com"
}
# Network module
module "network" {
  source     = "./modules/network"
  project_id = var.project_id
  region     = var.region
  network_name = "secure-vpc"  
  trusted_ip = [var.trusted_ip] 
  #depends_on = [google_project_service.compute]
  depends_on = [module.apis]


}

# GKE module
module "gke" {
  source       = "./modules/gke"
  project_id   = var.project_id
  region       = var.region
  network      = module.network.network_name
  subnetwork   = module.network.subnet_name
  master_cidr  = var.master_cidr
  trusted_ip   = var.trusted_ip
  node_count   = var.node_count
  machine_type = var.machine_type

  depends_on = [google_project_service.compute]
}

# Generate secure DB password
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!@#$%^&*()"
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  min_special      = 1
}

# Store password in Secret Manager
resource "google_secret_manager_secret" "db_password" {
  project   = var.project_id
  secret_id = "db-password"

  replication {
    auto {} # ✅ corrected here
  }

  depends_on = [google_project_service.secretmanager]
}

resource "google_secret_manager_secret_version" "db_password" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = random_password.db_password.result
}

# Cloud SQL module
module "cloudsql" {
  source           = "./modules/sql"
  project_id       = var.project_id
  region           = var.region
  db_instance      = "my-postgres-db"
  database         = "app_db"
  db_user          = "admin"
  db_password      = random_password.db_password.result
  db_tier          = "db-custom-1-3840"
  db_disk_size     = 20
  private_network  = module.network.network_self_link
  authorized_cidr  = "10.10.0.0/16"

  depends_on = [
    google_project_service.sqladmin,
    google_project_service.servicenetworking
  ]
}

# Redis module
module "redis" {
  source         = "./modules/redis"
  project_id     = var.project_id
  region         = var.region
  network        = module.network.network_self_link
  tier           = var.redis_tier
  memory_size_gb = var.redis_memory

  depends_on = [google_project_service.compute]
}

# Jenkins module
module "jenkins" {
  source                 = "./modules/jenkins"
  project_id             = var.project_id
  zone                   = var.zone
  network               = module.network.network_name
  subnet                = module.network.subnet_name
  machine_type           = var.jenkins_machine_type
  trusted_ip = var.trusted_ip
  disk_size             = var.jenkins_disk_size
  instance_name          = "jenkinsvm"
  jenkins_instance_image = var.jenkins_instance_image
  kms_key_self_link      = var.kms_key_self_link
  environment            = "production"

  # Remove extra disk since we only need one
  

  depends_on = [google_project_service.compute]
}








