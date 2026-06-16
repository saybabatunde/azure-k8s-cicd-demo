# Application Insights for monitoring
resource "azurerm_application_insights" "main" {
  name                = "${var.cluster_name}-ai"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.main.id

  tags = local.common_tags
}

# Alert Rule: High Response Time
resource "azurerm_monitor_metric_alert" "high_response_time" {
  name                = "${var.cluster_name}-high-response-time"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_application_insights.main.id]
  description         = "Alert when API response time exceeds 500ms"
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_name      = "requests/duration"
    operator         = "GreaterThan"
    threshold        = 500
    metric_namespace = "Microsoft.Insights/components"
    aggregation      = "Average"
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }

  tags = local.common_tags
}

# Alert Rule: High Error Rate
resource "azurerm_monitor_metric_alert" "high_error_rate" {
  name                = "${var.cluster_name}-high-error-rate"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_application_insights.main.id]
  description         = "Alert when error rate exceeds 5%"
  severity            = 1
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_name      = "requests/failed"
    operator         = "GreaterThan"
    threshold        = 5
    metric_namespace = "Microsoft.Insights/components"
    aggregation      = "Total"
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }

  tags = local.common_tags
}

# Alert Rule: Low Availability
resource "azurerm_monitor_metric_alert" "low_availability" {
  name                = "${var.cluster_name}-low-availability"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_application_insights.main.id]
  description         = "Alert when availability drops below 95%"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_name      = "availabilityResults/availabilityPercentage"
    operator         = "LessThan"
    threshold        = 95
    metric_namespace = "Microsoft.Insights/components"
    aggregation      = "Average"
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }

  tags = local.common_tags
}

# Action Group for Alerts
resource "azurerm_monitor_action_group" "main" {
  name                = "${var.cluster_name}-action-group"
  resource_group_name = azurerm_resource_group.main.name
  short_name          = "k8s-app"

  email_receiver {
    name           = "admin"
    email_address  = var.alert_email
    use_common_alert_schema = true
  }

  tags = local.common_tags
}

# Monitor Diagnostic Setting for AKS
resource "azurerm_monitor_diagnostic_setting" "aks" {
  name                       = "${var.cluster_name}-diagnostics"
  target_resource_id         = azurerm_kubernetes_cluster.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "kube-apiserver"
  }

  enabled_log {
    category = "kube-controller-manager"
  }

  enabled_log {
    category = "kube-scheduler"
  }

  enabled_log {
    category = "cluster-autoscaler"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# Dashboard
resource "azurerm_portal_dashboard" "main" {
  name                = "${var.cluster_name}-dashboard"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  dashboard_properties = jsonencode({
    lenses = {
      "0" = {
        order = 0
        parts = {
          "0" = {
            position = {
              x      = 0
              y      = 0
              colSpan = 6
              rowSpan = 4
            }
            metadata = {
              inputs = [
                {
                  name  = "resourceId"
                  value = azurerm_kubernetes_cluster.main.id
                }
              ]
              type = "Extension/HubsExtension/PartType/ResourcePart"
              settings = {}
            }
          }
          "1" = {
            position = {
              x      = 6
              y      = 0
              colSpan = 6
              rowSpan = 4
            }
            metadata = {
              inputs = [
                {
                  name  = "resourceId"
                  value = azurerm_application_insights.main.id
                }
              ]
              type = "Extension/AppInsightsExtension/PartType/OverviewPart"
              settings = {}
            }
          }
          "2" = {
            position = {
              x      = 0
              y      = 4
              colSpan = 6
              rowSpan = 4
            }
            metadata = {
              inputs = [
                {
                  name  = "resourceId"
                  value = azurerm_application_insights.main.id
                }
              ]
              type = "Extension/AppInsightsExtension/PartType/PerformanceTilePart"
              settings = {}
            }
          }
          "3" = {
            position = {
              x      = 6
              y      = 4
              colSpan = 6
              rowSpan = 4
            }
            metadata = {
              inputs = [
                {
                  name  = "resourceId"
                  value = azurerm_container_registry.main.id
                }
              ]
              type = "Extension/HubsExtension/PartType/ResourcePart"
              settings = {}
            }
          }
        }
      }
    }
  })

  tags = local.common_tags
}
