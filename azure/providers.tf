terraform {
  required_version = ">= 1.11"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.30.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

# Credentials are optional variables. When they are null the provider reads the
# ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_SUBSCRIPTION_ID and ARM_TENANT_ID
# environment variables, or the signed-in Azure CLI session.
provider "azurerm" {
  features {}

  resource_provider_registrations = var.resource_provider_registrations
  client_id                       = var.client_id
  client_secret                   = var.client_secret
  subscription_id                 = var.subscription_id
  tenant_id                       = var.tenant_id
}
