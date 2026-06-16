output "resource_group_name" {
  description = "Name of the created Resource Group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_id" {
  description = "ID of the created Resource Group"
  value       = azurerm_resource_group.main.id
}

# AKS Outputs
output "kubernetes_cluster_name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.name
}

output "kubernetes_cluster_id" {
  description = "ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.id
}

output "kube_config" {
  description = "Kubernetes configuration for kubectl"
  value       = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive   = true
}

output "kube_config_context" {
  description = "Kubernetes context name"
  value       = azurerm_kubernetes_cluster.main.kube_config[0].context[0].name
}

# ACR Outputs
output "container_registry_name" {
  description = "Name of the Azure Container Registry"
  value       = azurerm_container_registry.main.name
}

output "container_registry_id" {
  description = "ID of the Azure Container Registry"
  value       = azurerm_container_registry.main.id
}

output "container_registry_login_server" {
  description = "Login server URL for ACR (use in GitHub Secrets as ACR_LOGIN_SERVER)"
  value       = azurerm_container_registry.main.login_server
}

output "container_registry_admin_username" {
  description = "Admin username for ACR (use in GitHub Secrets as ACR_USERNAME)"
  value       = azurerm_container_registry.main.admin_username
  sensitive   = true
}

output "container_registry_admin_password" {
  description = "Admin password for ACR (use in GitHub Secrets as ACR_PASSWORD)"
  value       = azurerm_container_registry.main.admin_password
  sensitive   = true
}

# Network Outputs
output "virtual_network_id" {
  description = "ID of the Virtual Network"
  value       = azurerm_virtual_network.main.id
}

output "subnet_id" {
  description = "ID of the AKS subnet"
  value       = azurerm_subnet.aks.id
}

# Monitoring Outputs
output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.id
}

output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.name
}

# Next Steps
output "next_steps" {
  description = "Instructions for using the created resources"
  value = <<-EOT

    ✅ Infrastructure provisioning complete!

    📝 Next steps:

    1. Configure kubectl:
       az account set --subscription ${var.azure_subscription_id}
       az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${azurerm_kubernetes_cluster.main.name}

    2. Verify cluster connection:
       kubectl get nodes

    3. Add ACR credentials to GitHub:
       - Go to your GitHub repo → Settings → Secrets
       - Add these secrets:
         ACR_LOGIN_SERVER=${azurerm_container_registry.main.login_server}
         ACR_USERNAME=${azurerm_container_registry.main.admin_username}
         ACR_PASSWORD=${azurerm_container_registry.main.admin_password}

    4. Push code to trigger GitHub Actions pipeline

    5. Verify image in ACR:
       az acr repository list --name ${azurerm_container_registry.main.name}

    6. Deploy to AKS (Phase 4):
       kubectl apply -f k8s/namespace.yaml
       kubectl apply -f k8s/deployment.yaml
       kubectl apply -f k8s/service.yaml

    7. Check deployment status:
       kubectl get deployments -n azure-k8s-cicd
       kubectl get pods -n azure-k8s-cicd
       kubectl get svc -n azure-k8s-cicd
  EOT
}
