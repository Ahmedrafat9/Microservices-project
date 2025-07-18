resource "google_container_cluster" "gke" {
  project  = var.project_id
  name     = var.cluster_name
  location = var.region

  release_channel {
    channel = "REGULAR"
  }
# checkov:skip=CKV_GCP_65 reason="Google Groups for RBAC is not used in this setup"

  remove_default_node_pool = true
  initial_node_count       = 1

  networking_mode = "VPC_NATIVE"
  network         = var.network
  subnetwork      = var.subnetwork

  enable_shielded_nodes       = true
  enable_intranode_visibility = true

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods-range"
    services_secondary_range_name = "services-range"
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = true
    master_ipv4_cidr_block  = var.master_cidr
  }

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "10.0.0.0/8"     # Private range
      display_name = "Internal Network"
    }
    # Or use your VPC's CIDR range
    # cidr_blocks {
    #   cidr_block   = "10.1.0.0/16"
    #   display_name = "VPC Network"
    # }
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  
  binary_authorization {
    evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
  }

  network_policy {
    enabled  = true
    provider = "CALICO"
  }

  # Enable GKE Metadata Server (CKV_GCP_69) + Shielded Instance Config
  node_config {
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
    
    # ADD THIS: Shielded instance configuration for the cluster
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }
  }
  deletion_protection = false
  resource_labels = {
    environment = var.environment
    team        = "devops"
  }

  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }
}

resource "google_container_node_pool" "primary_nodes" {
  provider   = google-beta
  name       = "primary-node-pool"
  cluster    = google_container_cluster.gke.name
  location   = var.region
  initial_node_count = 1
  project    = var.project_id

  management {
    auto_upgrade = true
    auto_repair  = true
  }
  autoscaling {
    min_node_count = 1
    max_node_count = var.node_count
  }

  node_config {
    machine_type    = var.machine_type
    disk_size_gb    = 40
    disk_type       = "pd-ssd"

    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    sandbox_config {
      sandbox_type = "gvisor"
    }


    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}

