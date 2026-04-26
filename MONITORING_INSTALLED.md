# 📊 Prometheus & Grafana - Installation Complete!

## ✅ Installation Status

All monitoring components are now running in your Kubernetes cluster:

```
✅ Prometheus - Metrics collection and storage
✅ Grafana - Visualization and dashboards
✅ kube-state-metrics - Kubernetes object metrics
✅ AlertManager - Alert management
✅ Prometheus Operator - CRD management
```

### Pod Status
```
$ kubectl get pods -n monitoring

NAME                                                     READY   STATUS    RESTARTS   AGE
alertmanager-prometheus-kube-prometheus-alertmanager-0   2/2     Running   0          2m31s
grafana-6c975b9dd7-d2nn8                                 1/1     Running   0          67s
kube-state-metrics-8bf6c4869-2z7wf                       1/1     Running   0          26m
prometheus-kube-prometheus-operator-7d5ccb4599-j5pxf     1/1     Running   0          2m32s
prometheus-kube-state-metrics-f47d8dd47-z9wkq            1/1     Running   0          2m32s
prometheus-prometheus-kube-prometheus-prometheus-0       2/2     Running   0          2m31s
```

---

## 🚀 Quick Start - Accessing Grafana

### Step 1: Start Port Forwarding

Open a new terminal and run:

```bash
kubectl port-forward -n monitoring svc/grafana 3000:80
```

You should see:
```
Forwarding from 127.0.0.1:3000 -> 3000
Forwarding from [::1]:3000 -> 3000
```

### Step 2: Access Grafana

Open your browser and navigate to:
- **URL**: http://localhost:3000
- **Username**: `admin`
- **Password**: `admin`

⚠️ **Change the default password after first login!**

### Step 3: Explore Pre-loaded Dashboards

Once logged in, you'll find these dashboards in the Grafana home:

1. **Kubernetes Cluster** (gnetId: 7249)
   - Cluster-wide resource usage
   - Node metrics
   - Pod distribution

2. **Kubernetes Pods** (gnetId: 6417)
   - Pod metrics
   - Container performance
   - Network I/O

3. **Prometheus Stats** (gnetId: 2)
   - Prometheus itself metrics
   - Query performance
   - Storage usage

---

## 📊 What You Can Monitor

### Cluster Metrics
- **Node CPU & Memory**: Usage and availability
- **Pod Count**: Running, pending, failed
- **Network I/O**: Bytes sent/received per node
- **Disk Usage**: Per node and volume
- **Deployment Status**: Replicas ready/desired

### Application Metrics
- **Pod Performance**: CPU and memory usage
- **Container Restarts**: Crash detection
- **Pod Events**: Status changes
- **Network**: Connections and throughput

### System Metrics
- **Kubernetes Components**: API server, etcd, scheduler health
- **Storage**: PVC usage and availability
- **Alerts**: Active alerts and their status

---

## 🔍 Accessing Prometheus Directly

To query Prometheus directly (useful for debugging):

```bash
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
```

Then open http://localhost:9090

### Useful Prometheus Queries

```promql
# Pod CPU usage
sum(rate(container_cpu_usage_seconds_total[5m])) by (pod_name)

# Pod memory usage
sum(container_memory_usage_bytes) by (pod_name)

# Pod restart count
increase(kube_pod_container_status_restarts_total[1h])

# Node CPU usage
sum(rate(node_cpu_seconds_total[5m])) by (node)

# Node memory usage
sum(node_memory_MemAvailable_bytes) by (node)
```

---

## 📈 Creating Custom Dashboards

### In Grafana:

1. **Click "+" → "Dashboard"** to create a new dashboard
2. **Click "Add new panel"**
3. **Select Prometheus** as the data source
4. **Write a PromQL query** (see examples above)
5. **Configure visualization** (graph, gauge, stat, etc.)
6. **Save the dashboard**

### Example: Simple CPU Usage Dashboard

```promql
sum(rate(container_cpu_usage_seconds_total{pod=~"simple-k8s-cicd.*"}[5m])) by (pod)
```

---

## 🛠️ Useful kubectl Commands

```bash
# Check monitoring namespace
kubectl get all -n monitoring

# View Grafana logs
kubectl logs -f -n monitoring deployment/grafana

# View Prometheus logs
kubectl logs -f -n monitoring statefulset/prometheus-kube-prometheus-prometheus

# Get Grafana admin password (if changed)
kubectl get secret -n monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode

# Describe Prometheus service
kubectl describe svc prometheus-kube-prometheus-prometheus -n monitoring

# Port-forward multiple services
# Terminal 1:
kubectl port-forward -n monitoring svc/grafana 3000:80

# Terminal 2:
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
```

---

## 📋 Architecture

```
┌─────────────────────────────────────────────────────┐
│         Kubernetes Cluster (docker-desktop)         │
├─────────────────────────────────────────────────────┤
│                                                     │
│  ┌──────────────────────────────────────────┐      │
│  │ Your Monitoring Namespace                │      │
│  │ ────────────────────────────────────────  │      │
│  │                                          │      │
│  │  ┌──────────────┐  ┌────────────────┐   │      │
│  │  │   Grafana    │  │ kube-state-    │   │      │
│  │  │   (Port 80)  │  │   metrics      │   │      │
│  │  └──────┬───────┘  └────────┬───────┘   │      │
│  │         │                   │           │      │
│  │  ┌──────▼───────────────────▼─────┐    │      │
│  │  │     Prometheus (Port 9090)     │    │      │
│  │  │  - Scrapes metrics every 15s   │    │      │
│  │  │  - Stores 7 days of data       │    │      │
│  │  │  - 5GB persistent volume       │    │      │
│  │  └──────────────────────────────┘     │      │
│  │                                          │      │
│  │  ┌──────────────────────────────────┐   │      │
│  │  │  AlertManager (Port 9093)        │   │      │
│  │  │  - Handles alert routing         │   │      │
│  │  └──────────────────────────────────┘   │      │
│  │                                          │      │
│  └──────────────────────────────────────────┘      │
│                                                     │
│  ┌──────────────────────────────────────────┐      │
│  │ Your Application                         │      │
│  │ ────────────────────────────────────────  │      │
│  │                                          │      │
│  │  ┌─────────────────────────────────┐    │      │
│  │  │ simple-k8s-cicd Pods            │    │      │
│  │  │ (Metrics scraped by Prometheus) │    │      │
│  │  └─────────────────────────────────┘    │      │
│  │                                          │      │
│  └──────────────────────────────────────────┘      │
│                                                     │
└─────────────────────────────────────────────────────┘
```

---

## 🔗 Next Steps

1. **Access Grafana**: http://localhost:3000
2. **Change admin password**: Profile → Settings → Change Password
3. **Explore dashboards**: Check pre-loaded Kubernetes dashboards
4. **Create custom dashboards**: Monitor your specific application
5. **Set up alerts**: In Grafana or Prometheus
6. **Export metrics**: Use Prometheus remote write (optional)

---

## 🐛 Troubleshooting

### Grafana Not Accessible
```bash
# Check if pod is running
kubectl get pod -n monitoring -l app.kubernetes.io/name=grafana

# View logs
kubectl logs -n monitoring -l app.kubernetes.io/name=grafana

# Verify port-forward is running
kubectl port-forward -n monitoring svc/grafana 3000:80
```

### Prometheus Not Scraping Metrics
```bash
# Check Prometheus targets
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# Then visit http://localhost:9090/targets

# View Prometheus logs
kubectl logs -n monitoring statefulset/prometheus-kube-prometheus-prometheus
```

### No Data in Dashboards
- Wait 1-2 minutes for metrics to be scraped
- Check that pods are running and healthy
- Verify Prometheus is scraping targets
- Check Grafana data source configuration

---

## 📚 Resources

- **Grafana Docs**: https://grafana.com/docs/grafana/latest/
- **Prometheus Docs**: https://prometheus.io/docs/
- **PromQL Guide**: https://prometheus.io/docs/prometheus/latest/querying/basics/
- **kube-prometheus-stack**: https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack
- **Grafana Dashboard Library**: https://grafana.com/grafana/dashboards/

---

## 📝 Notes

- **Storage**: Prometheus uses 5GB persistent volume, data retained for 7 days
- **Retention Policy**: Can be adjusted in Helm values
- **Scalability**: Current setup suitable for small to medium clusters
- **Resource Limits**: All pods have CPU/memory limits for stability
- **Node Exporter**: Disabled due to Docker Desktop limitations (not needed for most monitoring)

---

**Setup Date**: 2026-04-24  
**Prometheus Version**: Latest (from Helm chart)  
**Grafana Version**: Latest (from Helm chart)  
**Kubernetes Version**: 1.35

Enjoy monitoring your Kubernetes cluster! 🎉
