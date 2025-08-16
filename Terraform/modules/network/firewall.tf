variable "network_name" {
  description = "اسم الشبكة اللي عايز تعمل عليها قواعد الفايروول"
  type        = string
}

variable "internal_cidr" {
  description = "نطاق IP للسماح بالتواصل الداخلي"
  type        = string
  default     = "10.0.0.0/8"
}

resource "google_compute_firewall" "allow_internal" {
  name    = "allow-internal"
  network = google_compute_network.vpc.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = ["10.0.0.0/8"]
  direction     = "INGRESS"
  priority      = 1000
}

resource "google_compute_firewall" "allow_health_checks" {
  project= var.project_id
  name    = "allow-health-checks"
  network = var.network_name

  allow {
    protocol = "tcp"
    ports    = ["10250"]
  }

  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  direction     = "INGRESS"
  priority      = 1000
}

resource "google_compute_firewall" "allow_ssh" {
  project = var.project_id
  name    = "allow-ssh"
  network = var.network_name
  depends_on = [
    google_compute_network.vpc
  ]
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }
  source_ranges = var.trusted_ip # أو يمكنك تحديد نطاق IP محدد
  direction     = "INGRESS"
  priority      = 1000
  target_tags = ["allow-ssh"]
}
resource "google_compute_firewall" "allow_https" {
  name    = "allow-https"
  network = var.network_name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = var.trusted_ip # or load balancer IP ranges
  direction     = "INGRESS"
}
resource "google_compute_firewall" "allow_redis" {
  project = var.project_id
  name    = "allow-redis"
  network = var.network_name

  allow {
    protocol = "tcp"
    ports    = ["6379"]
  }

  source_ranges = var.trusted_ip # أو نطاقات داخلية محددة جدًا (مثل subnet الخاص بالخدمات)
  direction     = "INGRESS"
  priority      = 1000
}
resource "google_compute_firewall" "allow_jenkins_1" {
  name    = "allow-jenkins-1"
  network = var.network_name
  project=var.project_id  
  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }

  target_tags   = ["jenkins"]
  source_ranges = var.trusted_ip # Or your IP range
}
