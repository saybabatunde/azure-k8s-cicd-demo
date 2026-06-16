terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  # Uncomment and configure for remote state storage
  # backend "azurerm" {
  #   resource_group_name  = "terraform-state"
  #   storage_account_name = "terraformstate"
  #   container_name       = "tfstate"
  #   key                  = "azure-k8s-cicd.tfstate"
  # }
}

provider "azurerm" {
  features {}

  subscription_id = var.azure_subscription_id
}

# Get current Azure context
data "azurerm_client_config" "current" {}


# Create resource group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location

  tags = local.common_tags
}

# Create virtual network
resource "azurerm_virtual_network" "main" {
  name                = "${var.cluster_name}-vnet"
  address_space       = [var.vnet_cidr]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = local.common_tags
}

# Create subnet for AKS
resource "azurerm_subnet" "aks" {
  name                 = "${var.cluster_name}-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnet_cidr]
}

# Local variables
locals {
  common_tags = {
    environment = var.environment
    project     = var.project_name
    created_by  = "terraform"
    created_at  = timestamp()
  }
}
