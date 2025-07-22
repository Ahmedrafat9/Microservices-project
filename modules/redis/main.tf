resource "google_redis_instance" "redis" {
  name               = "secure-redis"
  tier               = var.tier
  memory_size_gb     = var.memory_size_gb
  region             = var.region
  authorized_network = var.network
  redis_version      = "REDIS_6_X"
  display_name       = "Secure Redis"
  project            = var.project_id

  maintenance_policy {
    weekly_maintenance_window {
      day  = "SATURDAY"
      start_time {
        hours   = 2
        minutes = 0
        seconds = 0
        nanos   = 0
      }
    }
  }

  transit_encryption_mode = "SERVER_AUTHENTICATION"

  auth_enabled = true  # إضافة هذا السطر لتفعيل AUTH
}
