# Azure Monitor & Application Insights Setup

Phase 5: Complete observability stack for the CI/CD pipeline.

## What Gets Provisioned

✅ **Application Insights** — Real-time monitoring and diagnostics  
✅ **Action Group** — Alert routing (email notifications)  
✅ **3 Alert Rules** — Automatic alerts for:
   - High response time (> 500ms)
   - High error rate (> 5%)
   - Low availability (< 95%)
✅ **Diagnostic Settings** — AKS logs sent to Log Analytics  
✅ **Azure Portal Dashboard** — Visual monitoring dashboard  

## Architecture

```
Application
     │
     ▼
┌──────────────────────┐
│ Application Insights │
│  (Monitoring)        │
└──────────────────────┘
     │
     ├─ Tracks requests, errors, performance
     ├─ Collects logs and metrics
     └─ Triggers alerts
     
     ▼
┌──────────────────────┐
│  Alert Rules         │
│  (Thresholds)        │
└──────────────────────┘
     │
     ├─ Response Time > 500ms
     ├─ Error Rate > 5%
     └─ Availability < 95%
     
     ▼
┌──────────────────────┐
│  Action Group        │
│  (Email Alerts)      │
└──────────────────────┘
     │
     └─ Sends email to admin
```

## Configuration

### Alert Thresholds

| Alert | Condition | Threshold | Action |
|-------|-----------|-----------|--------|
| Response Time | Average > | 500ms | Email |
| Error Rate | Total > | 5 errors | Email |
| Availability | Average < | 95% | Email |

### Setting Alert Email

In `terraform.tfvars`:
```hcl
alert_email = "your-email@example.com"
```

Replace with your actual email address to receive alerts.

## Deploying Phase 5

### 1. Update terraform.tfvars

```bash
# Add/update:
alert_email = "your-email@example.com"
```

### 2. Plan Changes

```bash
cd terraform
terraform plan -out=tfplan
```

### 3. Apply

```bash
terraform apply tfplan
```

This adds:
- Application Insights
- Alert rules
- Action group
- Dashboard

### 4. Get Dashboard URL

```bash
terraform output dashboard_url
```

Visit the URL to see your monitoring dashboard in Azure Portal.

## Monitoring Your Deployment

### 1. View Real-time Metrics

```bash
# Get instrumentation key
terraform output -json | jq '.application_insights_instrumentation_key'

# Add to Flask app (optional):
# from opencensus.ext.flask.flask_middleware import FlaskMiddleware
# from opencensus.ext.azure.trace_exporter import AzureExporter
```

### 2. Check Application Insights in Azure Portal

1. Go to Azure Portal
2. Search for "Application Insights"
3. Select your instance: `azure-k8s-cicd-ai`
4. View:
   - **Performance** — Response times
   - **Failures** — Error rates
   - **Users** — Traffic patterns
   - **Availability** — Uptime %

### 3. View Alerts

1. Azure Portal → Monitor → Alerts
2. See all triggered alerts
3. View alert history and notifications

### 4. View Dashboard

```bash
# Get dashboard URL
terraform output dashboard_url

# Or navigate in Portal:
# Home → Dashboards → azure-k8s-cicd-dashboard
```

Dashboard shows:
- AKS cluster status
- Application Insights overview
- Performance metrics
- Container Registry info

## Testing Alerts

### Trigger High Response Time Alert

```bash
# Port-forward to the app
kubectl port-forward svc/azure-k8s-cicd-service 8080:80 -n azure-k8s-cicd

# Simulate slow requests (in another terminal)
for i in {1..10}; do
  curl -X GET http://localhost:8080/api/v1/status &
done
```

This generates enough traffic to potentially trigger the response time alert.

### Trigger Error Alert

```bash
# Make requests to non-existent endpoint
for i in {1..10}; do
  curl -X GET http://localhost:8080/nonexistent 2>/dev/null &
done
```

### Check Email

If thresholds are exceeded, you'll receive alert emails.

## Integrating Application Insights with Flask App

To send detailed metrics to Application Insights:

### 1. Install Dependencies

```bash
pip install opencensus-ext-flask opencensus-ext-azure
```

### 2. Update app.py

```python
from opencensus.ext.flask.flask_middleware import FlaskMiddleware
from opencensus.ext.azure.trace_exporter import AzureExporter
from opencensus.trace.samplers import ProbabilitySampler

# Initialize Application Insights
def initialize_insights(app):
    exporter = AzureExporter(
        connection_string=os.getenv('APPLICATIONINSIGHTS_CONNECTION_STRING')
    )
    middleware = FlaskMiddleware(
        app,
        exporter=exporter,
        sampler=ProbabilitySampler(rate=1.0)
    )

app = Flask(__name__)
initialize_insights(app)
```

### 3. Set Environment Variable

In deployment.yaml:
```yaml
env:
- name: APPLICATIONINSIGHTS_CONNECTION_STRING
  valueFrom:
    secretKeyRef:
      name: app-insights-secret
      key: connection-string
```

## Metrics You'll See

- **Requests** — Total requests, response times
- **Errors** — Failed requests, exception rates
- **Performance** — CPU, memory, response times
- **Availability** — % uptime, health checks
- **Dependencies** — Database, API calls
- **Logs** — Application logs, traces

## Customizing Alerts

To modify alert thresholds, edit `terraform/monitoring.tf`:

```hcl
# High Response Time Alert
threshold = 500  # Change to 1000 for 1 second

# High Error Rate
threshold = 5    # Change to 10 for 10 errors

# Low Availability
threshold = 95   # Change to 99 for 99% availability
```

Then apply:
```bash
terraform plan
terraform apply
```

## Viewing Logs

### AKS Control Plane Logs

```bash
# View in Log Analytics
# Azure Portal → Log Analytics → Run query:

AzureDiagnostics
| where ResourceType == "CLUSTERS"
| where TimeGenerated > ago(24h)
| project TimeGenerated, OperationName, Message
```

### Application Logs

```bash
# Kubernetes logs
kubectl logs -f deployment/azure-k8s-cicd-app -n azure-k8s-cicd

# Or in Application Insights:
# Azure Portal → Application Insights → Logs → Run query:

traces
| where timestamp > ago(24h)
| project timestamp, message
```

## Troubleshooting

**No metrics appearing?**
- Wait 5-10 minutes for data to be ingested
- Verify pod is running: `kubectl get pods -n azure-k8s-cicd`
- Check logs: `kubectl logs -n azure-k8s-cicd -l app=azure-k8s-cicd-app`

**Alerts not triggering?**
- Check thresholds are realistic
- Generate test traffic to trigger alerts
- Verify action group email is correct

**Dashboard not showing data?**
- Ensure resources have been running for at least 5 minutes
- Check Log Analytics workspace has data

## Cost

**Application Insights**: ~$2/month (ingestion) + data retention  
**Alerts**: Free (5 alert rules included)  
**Log Analytics**: ~$5/month for 30-day retention  

**Total**: ~$10/month for full observability

## Resources

- [Application Insights Docs](https://learn.microsoft.com/en-us/azure/azure-monitor/app/app-insights-overview)
- [Alert Rules](https://learn.microsoft.com/en-us/azure/azure-monitor/alerts/alerts-overview)
- [Log Analytics Queries](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/queries)
- [AKS Diagnostics](https://learn.microsoft.com/en-us/azure/aks/monitor-aks)
