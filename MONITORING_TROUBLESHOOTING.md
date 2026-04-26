# 🔧 Monitoring Troubleshooting & Advanced Guide

## Quick Status Check

```bash
# All monitoring components
kubectl get all -n monitoring

# Specific services
kubectl get svc -n monitoring

# Check persistent volumes
kubectl get pvc -n monitoring

# Pod events
kubectl describe pod -n monitoring <pod-name>
```

---

## Common Issues & Solutions

### Issue 1: Grafana Not Accessible

**Symptom**: Connection refused on http://localhost:3000

**Solution**:
```bash
# Verify pod is running
kubectl get pod -n monitoring -l app.kubernetes.io/name=grafana

# Check pod status
kubectl describe pod -n monitoring <grafana-pod-name>

# View logs
kubectl logs -n monitoring -l app.kubernetes.io/name=grafana

# Restart port-forward
kubectl port-forward -n monitoring svc/grafana 3000:80
```

### Issue 2: Prometheus Not Scraping Data

**Symptom**: Empty graphs in Grafana

**Solution**:
```bash
# Check Prometheus UI
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090

# Visit http://localhost:9090/targets
# Look for:
# - "kubernetes-nodes" should be UP
# - "kube-state-metrics" should be UP
# - Your application metrics should be UP

# Check Prometheus logs
kubectl logs -n monitoring statefulset/prometheus-kube-prometheus-prometheus

# View current Prometheus config
kubectl get prometheus -n monitoring -o yaml
```

### Issue 3: Grafana Dashboards Not Loading

**Symptom**: Dashboards visible but no data

**Solution**:
```bash
# Check datasource connection
# In Grafana: Settings → Data Sources → Prometheus
# Click "Save & Test"

# Check if Prometheus service is accessible from Grafana pod
kubectl exec -n monitoring deployment/grafana -- \
  wget -O- http://prometheus-kube-prometheus-prometheus:9090/-/healthy

# Restart Grafana
kubectl rollout restart deployment/grafana -n monitoring
```

### Issue 4: Out of Disk Space

**Symptom**: Prometheus or Grafana pods evicted

**Solution**:
```bash
# Check PVC usage
kubectl get pvc -n monitoring
kubectl describe pvc -n monitoring prometheus-kube-prometheus-prometheus-db-prometheus-kube-prometheus-prometheus-0

# Increase storage (if using dynamic provisioning)
kubectl patch pvc prometheus-kube-prometheus-prometheus-db-prometheus-kube-prometheus-prometheus-0 \
  -n monitoring \
  -p '{"spec":{"resources":{"requests":{"storage":"20Gi"}}}}'

# Reduce retention period
helm upgrade prometheus prometheus-community/kube-prometheus-stack \
  -n monitoring \
  --set prometheus.prometheusSpec.retention=3d
```

### Issue 5: Memory/CPU Issues

**Symptom**: Pods getting OOMKilled or throttled

**Solution**:
```bash
# Check current resource limits
kubectl get pod -n monitoring -o json | \
  jq '.items[].spec.containers[] | {name:.name, limits:.resources.limits}'

# Update resource limits
helm upgrade prometheus prometheus-community/kube-prometheus-stack \
  -n monitoring \
  --set prometheus.prometheusSpec.resources.limits.memory=1Gi \
  --set prometheus.prometheusSpec.resources.limits.cpu=1000m
```

### Issue 6: Metrics Not Visible in Prometheus

**Symptom**: Metrics don't appear in prometheus UI query results

**Solution**:
```bash
# Verify targets are being scraped
curl http://prometheus:9090/api/v1/targets

# Check if pods have correct labels
kubectl get pods -n monitoring --show-labels

# Verify ServiceMonitor is created
kubectl get servicemonitor -n monitoring

# Force Prometheus to reload config
kubectl rollout restart statefulset/prometheus-kube-prometheus-prometheus -n monitoring
```

---

## Advanced Monitoring Tasks

### 1. Increase Prometheus Retention

```bash
helm upgrade prometheus prometheus-community/kube-prometheus-stack \
  -n monitoring \
  --set prometheus.prometheusSpec.retention=30d \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=50Gi
```

### 2. Add Custom Scrape Configuration

Create a file `custom-scrape-config.yaml`:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: Prometheus
metadata:
  name: my-custom-prometheus
  namespace: monitoring
spec:
  additionalScrapeConfigs:
  - job_name: 'my-app'
    static_configs:
    - targets: ['localhost:8080']
```

Apply:
```bash
kubectl apply -f custom-scrape-config.yaml
```

### 3. Add Custom Alerts

Create an alert rule:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: app-alerts
  namespace: monitoring
spec:
  groups:
  - name: app.rules
    interval: 30s
    rules:
    - alert: HighErrorRate
      expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.05
      for: 5m
      annotations:
        summary: "High error rate detected"

    - alert: PodRestartingTooOften
      expr: rate(kube_pod_container_status_restarts_total[15m]) > 0.1
      for: 5m
      annotations:
        summary: "Pod restarting too often"

    - alert: HighMemoryUsage
      expr: container_memory_usage_bytes > 500000000
      for: 5m
      annotations:
        summary: "Pod using more than 500MB"
```

Apply:
```bash
kubectl apply -f app-alerts.yaml
```

### 4. Enable Remote Storage

For long-term metrics storage, use Prometheus remote write:

```bash
helm upgrade prometheus prometheus-community/kube-prometheus-stack \
  -n monitoring \
  --set prometheus.prometheusSpec.remoteWrite[0].url=https://your-remote-storage/api/v1/write
```

### 5. Add External Labels

```bash
helm upgrade prometheus prometheus-community/kube-prometheus-stack \
  -n monitoring \
  --set prometheus.prometheusSpec.externalLabels.cluster=production \
  --set prometheus.prometheusSpec.externalLabels.environment=kubernetes
```

---

## Performance Tuning

### Reduce Query Load

```bash
# Reduce scrape interval globally (default: 30s)
helm upgrade prometheus prometheus-community/kube-prometheus-stack \
  -n monitoring \
  --set prometheus.prometheusSpec.interval=60s

# Increase query timeout
helm upgrade prometheus prometheus-community/kube-prometheus-stack \
  -n monitoring \
  --set prometheus.prometheusSpec.queryLogFile=/prometheus/query.log
```

### Optimize Grafana

```bash
# Update Grafana memory limits
helm upgrade grafana grafana/grafana \
  -n monitoring \
  --set resources.limits.memory=512Mi
```

### Reduce Cardinality

In Prometheus scrape config:
```yaml
metric_relabel_configs:
- source_labels: [__name__]
  regex: 'go_.*'
  action: drop
```

---

## Backup & Restore

### Backup Grafana Dashboards

```bash
# Export all dashboards
kubectl exec -n monitoring deployment/grafana -- \
  grafana-cli admin export-dashboard > dashboards-backup.json

# Backup via API
curl -s http://localhost:3000/api/search | jq '.[] | {id:.id, title:.title}' > dashboard-list.json
```

### Backup Prometheus Data

```bash
# Snapshot current data
kubectl exec -n monitoring statefulset/prometheus-kube-prometheus-prometheus -- \
  promtool query instant 'up'

# Create PVC snapshot (if using storage)
kubectl exec -n monitoring statefulset/prometheus-kube-prometheus-prometheus -- \
  tar czf - /prometheus | \
  tar xzf - -C /backup/
```

### Backup All Monitoring Configuration

```bash
# Export all resources
kubectl get all -n monitoring -o yaml > monitoring-backup.yaml

# Export specific resources
kubectl get prometheus,grafana,servicemonitor,PrometheusRule -n monitoring -o yaml > monitoring-crds-backup.yaml
```

---

## Uninstall & Cleanup

### Remove All Monitoring

```bash
# Uninstall Grafana
helm uninstall grafana -n monitoring

# Uninstall Prometheus
helm uninstall prometheus -n monitoring

# Uninstall kube-state-metrics
helm uninstall kube-state-metrics -n monitoring

# Delete namespace
kubectl delete namespace monitoring

# Clean up Helm repositories (optional)
helm repo remove prometheus-community
helm repo remove grafana
```

### Keep Only Prometheus (Remove Grafana)

```bash
helm uninstall grafana -n monitoring
```

---

## Advanced Queries for Debugging

### Check Scrape Health

```bash
# In Prometheus UI, query:
up

# By job:
up{job="prometheus"}

# By instance:
up{instance="localhost:9090"}
```

### Check Metric Availability

```bash
# Find all metrics
{__name__=~".+"}

# Count metrics
count(count by (__name__)({__name__=~".+"}))

# Metrics from specific namespace
{namespace="default"}
```

### Monitor Prometheus Itself

```bash
# Scrape duration
scrape_duration_seconds

# Samples scraped per job
scrape_samples_scraped{job="prometheus"}

# TSDB memory usage
prometheus_tsdb_memory_chunks

# Query duration
rate(prometheus_http_request_duration_seconds_sum{handler="query"}[5m]) / 
rate(prometheus_http_request_duration_seconds_count{handler="query"}[5m])
```

---

## Integration with CI/CD

### Add Metrics Export to Pipeline

```yaml
# In .github/workflows/ci-cd.yml

- name: Export Prometheus Metrics
  run: |
    curl -s http://prometheus:9090/api/v1/query?query=up | \
      jq '.data.result[] | {job:.metric.job, status:.value}' > metrics.json
    
- name: Upload Metrics
  uses: actions/upload-artifact@v3
  with:
    name: prometheus-metrics
    path: metrics.json
```

### Monitor Pipeline Performance

Create dashboard queries:
```promql
# CI/CD Pipeline duration
rate(pipeline_duration_seconds[5m])

# Deployment frequency
rate(deployments_total[1d])

# Deployment success rate
rate(deployments_successful_total[1d]) / rate(deployments_total[1d])
```

---

## Further Resources

- [Prometheus Operator Documentation](https://prometheus-operator.dev/)
- [Grafana Provisioning](https://grafana.com/docs/grafana/latest/administration/provisioning/)
- [AlertManager Configuration](https://prometheus.io/docs/alerting/latest/configuration/)
- [PromQL Functions](https://prometheus.io/docs/prometheus/latest/querying/functions/)

---

**Last Updated**: 2026-04-24
