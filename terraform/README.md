# Terraform Infrastructure as Code

This directory contains Terraform configuration to provision the complete Azure infrastructure for the CI/CD pipeline demo.

## What Gets Provisioned

✅ **Azure Resource Group** — Container for all resources  
✅ **Virtual Network & Subnet** — Networking for AKS  
✅ **Azure Kubernetes Service (AKS)** — Managed Kubernetes cluster  
✅ **Azure Container Registry (ACR)** — Docker image repository  
✅ **Log Analytics Workspace** — Monitoring and logging  
✅ **RBAC & Role Assignments** — Security and access control  

## Architecture

```
Resource Group
├── Virtual Network (10.0.0.0/16)
│   └── AKS Subnet (10.0.1.0/24)
│       └── AKS Cluster
│           ├── Default Node Pool (2 nodes, auto-scaling)
│           ├── Control Plane (managed by Azure)
│           └── Add-ons (monitoring, networking)
├── Container Registry
│   └── Stores Docker images from CI/CD pipeline
└── Log Analytics Workspace
    └── Collects logs and metrics
```

## Prerequisites

1. **Azure CLI** installed and authenticated
   ```bash
   az login
   az account set --subscription YOUR_SUBSCRIPTION_ID
   ```

2. **Terraform** installed (>= 1.0)
   ```bash
   terraform version
   ```

3. **Azure Subscription** with sufficient permissions to create resources

## Quick Start

### 1. Setup Terraform Variables

Copy the example file and fill in your Azure subscription ID:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and set:
```hcl
azure_subscription_id = "your-subscription-id-here"
```

### 2. Initialize Terraform

```bash
cd terraform
terraform init
```

### 3. Plan the Deployment

Review what will be created:

```bash
terraform plan -out=tfplan
```

### 4. Apply the Configuration

Create the resources:

```bash
terraform apply tfplan
```

This will take **5-10 minutes** to complete. Terraform will output important values like:
- ACR login server
- Kubernetes config
- Resource IDs

### 5. Save the Output

Save sensitive outputs (ACR credentials) for later:

```bash
terraform output -json > outputs.json
```

## File Structure

```
terraform/
├── main.tf                      # Provider, resource group, networking
├── aks.tf                       # AKS cluster and monitoring
├── acr.tf                       # Azure Container Registry
├── variables.tf                 # Input variables with defaults
├── outputs.tf                   # Output values for next phases
├── terraform.tfvars.example    # Example variable values
└── README.md                    # This file
```

## Important Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `azure_subscription_id` | Required | Your Azure subscription ID |
| `location` | `eastus` | Azure region |
| `cluster_name` | `azure-k8s-cicd` | AKS cluster name |
| `node_count` | `2` | Initial number of nodes |
| `vm_size` | `Standard_B2s` | VM size (cost-effective for dev) |
| `kubernetes_version` | `1.28` | K8s version |
| `enable_auto_scaling` | `true` | Auto-scale nodes based on demand |

## Cost Considerations

**Estimated Monthly Cost** (dev environment):
- AKS cluster: ~$70 (per cluster)
- 2 x Standard_B2s nodes: ~$30/month each
- Container Registry (Standard): ~$10
- Log Analytics: ~$5

**Total**: ~$150/month (varies by region)

### Cost Optimization Tips:
- Use `Standard_B2s` for development (burstable, cheaper)
- Set `max_node_count = 3` to limit auto-scaling
- Use spot instances (add `priority = "Spot"` to node pool)
- Delete cluster when not in use

## Deploying to AKS

After infrastructure is created:

### 1. Get Kubernetes Credentials

```bash
az aks get-credentials \
  --resource-group $(terraform output -raw resource_group_name) \
  --name $(terraform output -raw kubernetes_cluster_name)
```

### 2. Verify Connection

```bash
kubectl get nodes
kubectl get pods --all-namespaces
```

### 3. Create Namespace for App

```bash
kubectl create namespace azure-k8s-cicd
kubectl label namespace azure-k8s-cicd name=azure-k8s-cicd
```

### 4. Deploy Application

```bash
kubectl apply -f ../k8s/deployment.yaml
kubectl apply -f ../k8s/service.yaml
```

## GitHub Actions Integration

After provisioning, add ACR credentials to GitHub Secrets:

```bash
# Get credentials from Terraform output
terraform output container_registry_login_server
terraform output container_registry_admin_username
terraform output container_registry_admin_password

# OR
terraform output -json | jq '.container_registry_*'
```

Then add to GitHub repo → Settings → Secrets:
- `ACR_LOGIN_SERVER` = login server URL
- `ACR_USERNAME` = admin username
- `ACR_PASSWORD` = admin password

GitHub Actions pipeline will now successfully push images to ACR.

## Destroying Resources

To delete all resources and stop incurring costs:

```bash
terraform destroy
```

**⚠️ WARNING:** This will delete everything including:
- AKS cluster
- Container Registry
- Virtual Network
- All running applications

## Troubleshooting

**Error: "subscription not found"**
```bash
az account list --output table
az account set --subscription <your-subscription-id>
```

**Error: "Insufficient permissions"**
- Ensure your Azure account has owner/contributor role on the subscription

**AKS provisioning fails**
- Check quota limits: `az vm list-usage --location eastus`
- Try different region if quota exceeded

**Can't pull images from ACR**
- Verify role assignment: `kubectl get rolebindings -A`
- Check ACR permissions: `az role assignment list --scope $(terraform output container_registry_id)`

## Next Steps

- ✅ Phase 3: Infrastructure provisioned
- ⏳ Phase 4: Configure Kubernetes deployments
- ⏳ Phase 5: Setup Azure Monitor observability

## Resources

- [Terraform Azure Provider Docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest)
- [AKS Best Practices](https://learn.microsoft.com/en-us/azure/aks/best-practices)
- [Terraform Best Practices](https://www.terraform.io/language/settings/backends/azurerm)
