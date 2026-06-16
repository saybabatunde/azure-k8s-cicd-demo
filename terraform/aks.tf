# Azure Kubernetes Service cluster
resource "azurerm_kubernetes_cluster" "main" {
  name                = var.cluster_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = var.cluster_name

  kubernetes_version = var.kubernetes_version

  # Default node pool
  default_node_pool {
    name           = "default"
    node_count     = var.node_count
    vm_size        = var.vm_size
    vnet_subnet_id = azurerm_subnet.aks.id

    enable_auto_scaling = var.enable_auto_scaling
    min_count          = var.min_node_count
    max_count          = var.max_node_count

    tags = local.common_tags
  }

  # Kubelet identity for managed identity
  identity {
    type = "SystemAssigned"
  }

  # Network profile
  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    service_cidr      = var.service_cidr
    dns_service_ip    = var.dns_service_ip
    docker_bridge_cidr = var.docker_bridge_cidr

    load_balancer_sku = "standard"
  }

  # Enable monitoring
  oms_agent {
    msi_auth_for_monitoring_enabled = true
    log_analytics_workspace_id      = azurerm_log_analytics_workspace.main.id
  }

  # RBAC enabled by default
  role_based_access_control_enabled = true

  tags = local.common_tags

  depends_on = [
    azurerm_role_assignment.aks_subnet
  ]
}

# Log Analytics Workspace for monitoring
resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.cluster_name}-logs"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = local.common_tags
}

# Role assignment for AKS to use subnet
resource "azurerm_role_assignment" "aks_subnet" {
  scope              = azurerm_subnet.aks.id
  role_definition_name = "Network Contributor"
  principal_id       = azurerm_kubernetes_cluster.main.identity[0].principal_id
}

# Kubernetes namespace for the app
resource "azurerm_kubernetes_cluster_node_pool" "optional" {
  count                 = var.enable_optional_node_pool ? 1 : 0
  name                  = "optional"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = var.optional_vm_size
  node_count            = var.optional_node_count

  tags = local.common_tags
}
