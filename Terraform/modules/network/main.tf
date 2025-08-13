resource "google_compute_network" "vpc" {
  project = var.project_id
  name                    = "secure-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  project       = var.project_id
  name          = "secure-subnet"
  ip_cidr_range = "10.10.0.0/16"
  region        = var.region
  network       = google_compute_network.vpc.id
  private_ip_google_access = true

  # ضروري لإضافة secondary IP ranges لـ GKE pods و services
  secondary_ip_range {
    range_name    = "pods-range"
    ip_cidr_range = "10.21.0.0/16"
  }
  

  secondary_ip_range {
    range_name    = "services-range"
    ip_cidr_range = "10.22.0.0/16"
  }

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}
/* 
resource "google_compute_firewall" "allow_health_and_ssh" {
  project = var.project_id
  name    = "allow-health-and-ssh"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["22", "443"]
  }

  # concat يجمع قائمتين أو أكثر، لازم var.trusted_ip تكون قائمة من السلاسل
  source_ranges = concat(
    [
      "35.191.0.0/16",  # GKE health checks
      "130.211.0.0/22"  # GKE control plane
    ],
    var.trusted_ip
  )

  direction = "INGRESS"
} */
resource "google_compute_global_address" "private_ip_range" {
  name          = "private-ip-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc.id
  project       = var.project_id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc.self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_range.name]

  depends_on = [google_compute_global_address.private_ip_range]
}

resource "google_compute_router" "gke_nat_router" {
  project = var.project_id
  name    = "gke-nat-router"
  network = google_compute_network.vpc.id
  region  = var.region
}
resource "google_compute_router_nat" "gke_nat" {
  project = var.project_id
  name                               = "gke-nat"
  router                             = google_compute_router.gke_nat_router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY" # automatically allocates external IPs
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}
