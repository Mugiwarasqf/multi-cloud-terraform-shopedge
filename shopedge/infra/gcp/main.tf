


#################################
# 3. GKE Cluster + Node Pool
#################################
resource "google_container_cluster" "gke" {
  name     = "shopedge-cluster"
  location = var.region
  deletion_protection = false  # ✅ Allow deletion

  remove_default_node_pool = true
  initial_node_count       = 1

  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.private_subnet.name

  ip_allocation_policy {}

  release_channel {
    channel = "REGULAR"
  }

  # Secure: No username/password, no client cert
  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }
}


# Managed Node Pool
resource "google_container_node_pool" "primary_nodes" {
  name       = "default-node-pool"
  location   = var.region
  cluster    = google_container_cluster.gke.name

  node_count = 2

  node_config {
    machine_type = "e2-medium"

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]

    labels = {
      role = "worker"
    }

    tags = ["gke-node"]
  }

  autoscaling {
    min_node_count = 1
    max_node_count = 3
  }
}

# Artifact Registry (Docker Repo)

resource "google_artifact_registry_repository" "app_repo" {
  location      = var.region
  repository_id = "shop-edge"
  description   = "Docker images for ShopEdge app"
  format        = "DOCKER"
}


#  Outputs

output "cluster_name" {
  value = google_container_cluster.gke.name
}

output "cluster_endpoint" {
  value = google_container_cluster.gke.endpoint
}

output "artifact_registry_repo" {
  value = google_artifact_registry_repository.app_repo.id
}
