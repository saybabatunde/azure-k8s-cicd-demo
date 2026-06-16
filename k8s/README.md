
# Kubernetes Manifests

This directory contains Kubernetes deployment manifests for the Flask application on AKS.

## Manifest Files

### `namespace.yaml`
Creates a dedicated namespace `azure-k8s-cicd` for the application.

```bash
kubectl apply -f k8s/namespace.yaml
```

### `serviceaccount.yaml`
Creates:
- **ServiceAccount** — Identity for the pod
- **Role** — Permissions to read pods and configmaps
- **RoleBinding** — Links ServiceAccount to Role

```bash
kubectl apply -f k8s/serviceaccount.yaml
```

### `deployment.yaml`
Kubernetes Deployment with production-ready configuration:

**Key Features:**
- ✅ 2 replicas (high availability)
- ✅ Rolling update strategy (zero downtime)
- ✅ Liveness probe (`/health`) — Restarts failed pods
- ✅ Readiness probe (`/readiness`) — Removes unhealthy from load balancer
- ✅ Resource requests/limits — CPU: 100m-500m, Memory: 128-512Mi
- ✅ Non-root security context (runs as user 1000)
- ✅ Pod anti-affinity — Spreads across nodes for resilience
- ✅ Termination grace period — Graceful shutdown (30s)

```bash
kubectl apply -f k8s/deployment.yaml
```

### `service.yaml`
Kubernetes Service of type `LoadBalancer`:
- Exposes the app on public IP
- Port 80 → Pod port 5000
- Load balancer distributes traffic across replicas

```bash
kubectl apply -f k8s/service.yaml
```

## Deployment Architecture

```
┌─────────────────────────────────────────┐
│       Kubernetes Namespace              │
│       azure-k8s-cicd                    │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │  LoadBalancer Service           │   │
│  │  Port 80 → Pod Port 5000        │   │
│  │  External IP: xxx.xxx.xxx.xxx   │   │
│  └─────────────────────────────────┘   │
│          │                              │
│          ▼                              │
│  ┌──────────────────────────────────┐  │
│  │  Deployment                      │  │
│  │  azure-k8s-cicd-app (2 replicas) │  │
│  │                                  │  │
│  │  ┌────────────┐  ┌────────────┐ │  │
│  │  │    Pod 1   │  │    Pod 2   │ │  │
│  │  │  Flask App │  │  Flask App │ │  │
│  │  │  Port 5000 │  │  Port 5000 │ │  │
│  │  └────────────┘  └────────────┘ │  │
│  │                                  │  │
│  │  Rolling Update Strategy:        │  │
│  │  - maxSurge: 1                   │  │
│  │  - maxUnavailable: 0             │  │
│  └──────────────────────────────────┘  │
│                                         │
└─────────────────────────────────────────┘
```

## Health Probes

### Liveness Probe
- **Endpoint:** `GET /health`
- **Check Interval:** Every 30 seconds
- **Failure Threshold:** 3 failures = pod restart
- **Timeout:** 5 seconds

Purpose: Detect stuck/dead pods and restart them.

### Readiness Probe
- **Endpoint:** `GET /readiness`
- **Check Interval:** Every 10 seconds
- **Failure Threshold:** 2 failures = remove from load balancer
- **Timeout:** 3 seconds

Purpose: Keep unhealthy pods from receiving traffic.

## Resource Management

**Requests** (guaranteed):
- CPU: 100m (0.1 core)
- Memory: 128Mi

**Limits** (maximum allowed):
- CPU: 500m (0.5 core)
- Memory: 512Mi

These limits keep cost low for dev/staging while preventing resource hogging.

## Security Features

✅ **Non-root user** — Runs as UID 1000  
✅ **No privilege escalation** — `allowPrivilegeEscalation: false`  
✅ **Dropped capabilities** — Removes unnecessary Linux capabilities  
✅ **Read-only root filesystem** — Can't modify system files  
✅ **Service account with limited RBAC** — Only reads pods/configmaps  

## Deploying Manifests

### Option 1: Apply One by One
```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/serviceaccount.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
```

### Option 2: Apply All at Once
```bash
kubectl apply -f k8s/
```

### Option 3: Using Kustomization
Create `k8s/kustomization.yaml`:
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: azure-k8s-cicd

resources:
  - namespace.yaml
  - serviceaccount.yaml
  - deployment.yaml
  - service.yaml

commonLabels:
  app: azure-k8s-cicd
  managed-by: kustomize
```

Then:
```bash
kubectl apply -k k8s/
```

## Verifying Deployment

### Check Deployment Status
```bash
kubectl get deployments -n azure-k8s-cicd
kubectl get pods -n azure-k8s-cicd
kubectl get svc -n azure-k8s-cicd
```

### Watch Rollout
```bash
kubectl rollout status deployment/azure-k8s-cicd-app -n azure-k8s-cicd
```

### Get Service IP (may take 1-2 minutes)
```bash
kubectl get svc azure-k8s-cicd-service -n azure-k8s-cicd

# Or with external IP
kubectl get svc -n azure-k8s-cicd -o wide
```

### Test the App
```bash
# Port forward (local testing)
kubectl port-forward svc/azure-k8s-cicd-service 8080:80 -n azure-k8s-cicd

# Then visit: http://localhost:8080
```

### View Logs
```bash
# Latest logs from all pods
kubectl logs -f deployment/azure-k8s-cicd-app -n azure-k8s-cicd

# Logs from specific pod
kubectl logs pod-name -n azure-k8s-cicd

# Previous logs (if pod crashed)
kubectl logs pod-name -n azure-k8s-cicd --previous
```

### Describe Resources
```bash
# Full deployment details
kubectl describe deployment azure-k8s-cicd-app -n azure-k8s-cicd

# Pod details and events
kubectl describe pod pod-name -n azure-k8s-cicd
```

## Troubleshooting

### Pod Won't Start
```bash
# Check events
kubectl get events -n azure-k8s-cicd --sort-by='.lastTimestamp'

# Check pod details
kubectl describe pod pod-name -n azure-k8s-cicd

# Check logs
kubectl logs pod-name -n azure-k8s-cicd
```

### CrashLoopBackOff
Pod is crashing and restarting. Check logs:
```bash
kubectl logs pod-name -n azure-k8s-cicd --previous
```

### Service Not Getting External IP
May take 1-2 minutes. Check status:
```bash
kubectl get svc -n azure-k8s-cicd
# If stuck on <pending>, check cluster has available load balancer capacity
```

### Image Pull Errors
```bash
# Verify image exists in ACR
az acr repository list --name your-acr-name

# Check image pull secret (if using private registry)
kubectl get secrets -n azure-k8s-cicd
```

## Updating the Deployment

### Update Image (GitHub Actions does this automatically)
```bash
kubectl set image deployment/azure-k8s-cicd-app \
  app=your-registry.azurecr.io/azure-k8s-cicd-demo:v2.0 \
  -n azure-k8s-cicd
```

### Scale Replicas
```bash
kubectl scale deployment azure-k8s-cicd-app --replicas=3 -n azure-k8s-cicd
```

### Update Resource Limits
Edit deployment.yaml and apply:
```bash
kubectl apply -f k8s/deployment.yaml
```

## Rolling Back

```bash
# View rollout history
kubectl rollout history deployment/azure-k8s-cicd-app -n azure-k8s-cicd

# Rollback to previous version
kubectl rollout undo deployment/azure-k8s-cicd-app -n azure-k8s-cicd
```

## Cleanup

```bash
# Delete entire namespace (removes all resources)
kubectl delete namespace azure-k8s-cicd

# Or delete individual resources
kubectl delete deployment azure-k8s-cicd-app -n azure-k8s-cicd
kubectl delete svc azure-k8s-cicd-service -n azure-k8s-cicd
```

## Resources

- [Kubernetes Deployment Docs](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [Kubernetes Probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)
- [Kubernetes RBAC](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [AKS Best Practices](https://learn.microsoft.com/en-us/azure/aks/best-practices)
