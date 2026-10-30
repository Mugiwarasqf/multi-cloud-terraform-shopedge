

resource "azurerm_resource_group" "rg" {
  name     = "shopedge-rg"
  location = var.location
}





resource "azurerm_kubernetes_cluster" "aks" {
  name                = "shopedge-aks"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "shopedge"

  default_node_pool {
    name           = "default"
    node_count     = 2
    vm_size        = var.node_vm_size
    vnet_subnet_id = azurerm_subnet.aks_subnet.id
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure" # recommended for production
    network_policy = "azure"

    # Must not overlap the VNet (10.0.0.0/16). The AKS default, 10.0.0.0/16, does,
    # and AKS rejects the cluster for it.
    service_cidr   = "172.16.0.0/16"
    dns_service_ip = "172.16.0.10"
  }

  role_based_access_control_enabled = true
}

# Azure Container Registry (ACR)

resource "azurerm_container_registry" "acr" {
  name                = "shopedgeacr${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = false
}

# Random string to avoid ACR name collisions (ACR names must be globally unique)
resource "random_string" "suffix" {
  length  = 5
  upper   = false
  lower   = true
  special = false
  numeric = true
}

# Role Assignment (AKS -> ACR)

resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name = "AcrPull"
  scope                = azurerm_container_registry.acr.id
}

#output
output "cluster_name" {
  value = azurerm_kubernetes_cluster.aks.name
}

output "cluster_fqdn" {
  value = azurerm_kubernetes_cluster.aks.fqdn
}

output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}


