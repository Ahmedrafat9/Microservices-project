# modules/apis/main.tf
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "apis" {
  description = "List of APIs to enable"
  type        = list(string)
  default = [
    "compute.googleapis.com",                    # Compute Engine
    "servicenetworking.googleapis.com",          # Service Networking
    "sqladmin.googleapis.com",                   # Cloud SQL
    "container.googleapis.com",                  # GKE
    "cloudresourcemanager.googleapis.com",       # Resource Manager
    "iam.googleapis.com",                        # IAM
    "redis.googleapis.com",                      # Memorystore
    "dns.googleapis.com",                        # Cloud DNS
    "storage.googleapis.com",                    # Cloud Storage
    "monitoring.googleapis.com",                 # Cloud Monitoring
    "logging.googleapis.com",                    # Cloud Logging
    "cloudbuild.googleapis.com",                 # Cloud Build
    "secretmanager.googleapis.com",              # Secret Manager
    "cloudkms.googleapis.com",                   # KMS
    "file.googleapis.com",                       # Filestore
    "vpcaccess.googleapis.com",                  # VPC Access
    "run.googleapis.com",                        # Cloud Run
    "cloudfunctions.googleapis.com",             # Cloud Functions
    "pubsub.googleapis.com",                     # Pub/Sub
    "artifactregistry.googleapis.com"            # Artifact Registry
  ]
}

resource "google_project_service" "apis" {
  for_each = toset(var.apis)
  
  project = var.project_id
  service = each.value
  
  disable_on_destroy = false
  disable_dependent_services = false
  
  timeouts {
    create = "30m"
    update = "40m"
  }
}

output "enabled_apis" {
  value = google_project_service.apis
}