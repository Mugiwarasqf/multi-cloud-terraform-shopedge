#################################
# GKE Cluster + Node Pool
#################################

# One zone for the nodes. A regional cluster otherwise runs the node pool in every
# zone of the region, which triples the node count and cost.
data "google_compute_zones" "available" {
  region = var.region
  status = "UP"

  depends_on = [google_project_service.apis]
}

resource "google_container_cluster" "gke" {
  name                = "shopedge-cluster"
  location            = var.region
  node_locations      = [data.google_compute_zones.available.names[0]]
  deletion_protection = false # Allow terraform destroy

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
  name     = "default-node-pool"
  location = var.region
  cluster  = google_container_cluster.gke.name

  # Starting size only; the autoscaler owns the count after that
  initial_node_count = 2

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

  depends_on = [google_project_service.apis]
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
