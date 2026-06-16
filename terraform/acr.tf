# Azure Container Registry for storing Docker images
resource "azurerm_container_registry" "main" {
  name                = replace("${var.cluster_name}acr", "-", "")
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  admin_enabled = true
  sku           = var.acr_sku

  network_rule_bypass_option = "AzureServices"

  tags = local.common_tags
}

# ACR role assignment for AKS to pull images
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope              = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id       = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id

  depends_on = [azurerm_kubernetes_cluster.main]
}

# Output ACR admin credentials for GitHub Actions
resource "azurerm_container_registry_managed_identity_credential" "main" {
  container_registry_id = azurerm_container_registry.main.id
  name                  = "github-actions"
}
