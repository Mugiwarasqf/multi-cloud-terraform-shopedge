
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0" # ✅ Latest stable version
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "8cffa789-f3b1-4e18-96e8-81c438681119"
  tenant_id =  ""

}