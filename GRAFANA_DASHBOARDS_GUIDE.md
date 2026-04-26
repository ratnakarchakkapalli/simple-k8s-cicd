# 📊 Grafana Dashboard Creation & PromQL Guide

## Table of Contents
1. [PromQL Basics](#promql-basics)
2. [Common Metrics](#common-metrics)
3. [Creating Custom Dashboards](#creating-custom-dashboards)
4. [Dashboard Examples](#dashboard-examples)
5. [Advanced Queries](#advanced-queries)
6. [Monitoring Your Application](#monitoring-your-application)

---

## PromQL Basics

### What is PromQL?

PromQL is Prometheus's query language. It allows you to select and aggregate time series data in real-time.

### Query Types

#### 1. **Instant Vector** - Returns current value
```promql
container_memory_usage_bytes
```

#### 2. **Range Vector** - Returns values over time range
```promql
container_memory_usage_bytes[5m]
```

#### 3. **Scalar** - Single numeric value
```promql
1 + 1
```

### Time Ranges

- `s` - seconds
- `m` - minutes
- `h` - hours
- `d` - days
- `w` - weeks
- `y` - years

```promql
# Last 5 minutes
[5m]

# Last 1 hour
[1h]

# Last 7 days
[7d]
```

### Operators

```promql
# Arithmetic: +, -, *, /, %
container_memory_usage_bytes / 1024 / 1024  # Convert to MB

# Comparison: ==, !=, >, <, >=, <=
http_requests_total > 100

# Logical: and, or, unless
instance:node_cpu:rate5m > 0.8 or instance:memory_usage:rate5m > 0.8
```

### Labels

Most metrics have labels (like namespace, pod, container):

```promql
# Select specific namespace
container_memory_usage_bytes{namespace="monitoring"}

# Multiple label conditions
container_memory_usage_bytes{namespace="default", pod=~"simple-k8s.*"}

# Regex matching: =~, !~
kube_pod_labels{label_app=~"simple.*"}
```

### Functions

#### Rate & Increase
```promql
# Rate of change per second (for counters)
rate(http_requests_total[5m])

# Total increase over time period
increase(http_requests_total[1h])
```

#### Aggregation
```promql
# Sum across all instances
sum(container_memory_usage_bytes)

# Average across instances
avg(container_memory_usage_bytes)

# Min/Max
min(container_memory_usage_bytes)
max(container_memory_usage_bytes)

# Count
count(container_memory_usage_bytes)
```

#### Aggregation with Grouping
```promql
# Sum grouped by namespace
sum(container_memory_usage_bytes) by (namespace)

# Sum grouped by pod and namespace
sum(container_memory_usage_bytes) by (pod, namespace)

# Without (reverse grouping)
sum without (instance)(container_memory_usage_bytes)
```

#### Math Functions
```promql
# Absolute value
abs(metric)

# Ceiling/Floor
ceil(metric)
floor(metric)

# Rate of increase
deriv(metric[5m])
```

#### Sorting
```promql
# Top 5
topk(5, container_memory_usage_bytes)

# Bottom 5
bottomk(5, container_memory_usage_bytes)

# Sort ascending
sort(metric)

# Sort descending
sort_desc(metric)
```

---

## Common Metrics

### Container Metrics

```promql
# Container CPU usage
container_cpu_usage_seconds_total

# Container memory usage (bytes)
container_memory_usage_bytes

# Container filesystem usage
container_fs_usage_bytes

# Container network transmitted bytes
container_network_transmit_bytes_total

# Container network received bytes
container_network_receive_bytes_total
```

### Kubernetes Metrics (via kube-state-metrics)

```promql
# Pod status (1 = running)
kube_pod_status_phase{phase="Running"}

# Pod restart count
kube_pod_container_status_restarts_total

# Deployment replicas
kube_deployment_status_replicas

# Deployment replicas ready
kube_deployment_status_replicas_ready

# StatefulSet replicas
kube_statefulset_status_replicas

# Job status
kube_job_status_succeeded
```

### Node Metrics

```promql
# Node CPU (from system metrics)
node_cpu_seconds_total

# Node memory available
node_memory_MemAvailable_bytes

# Node filesystem usage
node_filesystem_avail_bytes

# Node disk I/O
node_disk_read_bytes_total
node_disk_written_bytes_total
```

### Prometheus Metrics

```promql
# Scrape duration
scrape_duration_seconds

# Number of samples scraped
scrape_samples_scraped

# TSDB storage size
prometheus_tsdb_symbol_table_size_bytes

# Number of time series
prometheus_tsdb_metric_chunks_created_total
```

---

## Creating Custom Dashboards

### Step-by-Step Guide

#### Step 1: Create New Dashboard

1. In Grafana, click **"+"** in the left sidebar
2. Select **"Dashboard"**
3. Click **"Add new panel"**

#### Step 2: Configure Data Source

1. In the query editor (bottom panel), ensure **"Prometheus"** is selected
2. You'll see the PromQL query box

#### Step 3: Write PromQL Query

Replace the default query with your custom query:

```promql
# Example: Pod memory usage
sum(container_memory_usage_bytes{namespace="default"}) by (pod_name)
```

#### Step 4: Configure Visualization

On the right panel, choose visualization type:
- **Graph**: Time series data
- **Stat**: Single number
- **Gauge**: Visual gauge
- **Bar gauge**: Horizontal bars
- **Heatmap**: 2D data visualization
- **Table**: Tabular data
- **Pie chart**: Pie chart
- **Logs**: Log data

#### Step 5: Customize Panel

Configure in the right panel:
- **Title**: Panel name
- **Description**: Panel description
- **Unit**: Data unit (bytes, percent, short, etc.)
- **Decimals**: Number precision
- **Min/Max**: Value range
- **Thresholds**: Alert thresholds (e.g., orange at 70%, red at 90%)
- **Legend**: Show/hide, position, values to display

#### Step 6: Save Dashboard

Click **"Save dashboard"** at the top, give it a name, and save.

---

## Dashboard Examples

### Example 1: Simple Application Monitoring Dashboard

#### Panel 1: Pod Count
- **Name**: "Running Pods"
- **Query**: 
  ```promql
  count(kube_pod_status_phase{namespace="default", phase="Running"})
  ```
- **Visualization**: Stat
- **Unit**: Short (no unit)

#### Panel 2: Total Memory Usage
- **Name**: "Memory Usage"
- **Query**: 
  ```promql
  sum(container_memory_usage_bytes{namespace="default"}) / 1024 / 1024 / 1024
  ```
- **Visualization**: Stat
- **Unit**: GB
- **Decimals**: 2

#### Panel 3: Memory Usage Over Time
- **Name**: "Memory Trend"
- **Query**: 
  ```promql
  sum(container_memory_usage_bytes{namespace="default"}) by (pod_name) / 1024 / 1024
  ```
- **Visualization**: Graph
- **Unit**: MB
- **Legend**: Show pod names

#### Panel 4: Pod Restarts
- **Name**: "Pod Restarts"
- **Query**: 
  ```promql
  sum(increase(kube_pod_container_status_restarts_total{namespace="default"}[1h])) by (pod_name)
  ```
- **Visualization**: Table
- **Unit**: Short

#### Panel 5: CPU Usage
- **Name**: "CPU Usage"
- **Query**: 
  ```promql
  sum(rate(container_cpu_usage_seconds_total{namespace="default"}[5m])) by (pod_name)
  ```
- **Visualization**: Graph
- **Unit**: Percent (0-100)

---

### Example 2: Deployment Monitoring Dashboard

#### Panel 1: Deployment Replica Status
```promql
sum(kube_deployment_status_replicas_ready{namespace="default"}) by (deployment)
/
sum(kube_deployment_status_replicas{namespace="default"}) by (deployment)
```

#### Panel 2: Pod Creation Rate
```promql
rate(kube_pod_created{namespace="default"}[5m])
```

#### Panel 3: Pod Crash Looping
```promql
sum(rate(kube_pod_container_status_last_terminated_reason{reason="ContainerCannotRun"}[5m])) by (pod)
```

#### Panel 4: Recent Pod Events
```promql
kube_pod_labels{namespace="default"}
```

---

## Advanced Queries

### CPU Usage Percentage (normalized)

```promql
# CPU as percentage (0-100%)
(sum(rate(container_cpu_usage_seconds_total{namespace="default"}[5m])) by (pod_name) * 100)
```

### Memory Usage Percentage

```promql
# Memory as percentage of node available memory
(sum(container_memory_usage_bytes{namespace="default"}) by (pod_name) 
/ 
sum(node_memory_MemAvailable_bytes) * 100)
```

### Network I/O (bytes per second)

```promql
# Network received (Mbps)
rate(container_network_receive_bytes_total{namespace="default"}[5m]) / 1024 / 1024

# Network transmitted (Mbps)
rate(container_network_transmit_bytes_total{namespace="default"}[5m]) / 1024 / 1024
```

### Pod Uptime

```promql
# Get pod start time (useful for calculating uptime)
time() - container_start_time_seconds{namespace="default"}
```

### Request Rate (if instrumented)

```promql
# HTTP requests per second
sum(rate(http_requests_total{namespace="default"}[5m])) by (service)

# HTTP error rate percentage
(sum(rate(http_requests_total{job="app", status=~"5.."}[5m])) 
/ 
sum(rate(http_requests_total{job="app"}[5m]))) * 100
```

### Combining Multiple Metrics

```promql
# Metric if another metric exists
container_memory_usage_bytes 
* on(pod_name) 
kube_pod_status_phase{phase="Running"}
```

### Comparing Values

```promql
# Pods using more than 500MB
container_memory_usage_bytes{namespace="default"} > 500000000
```

---

## Monitoring Your Application

### Step 1: Verify Metrics Collection

1. Open Prometheus: http://localhost:9090
2. Go to **"Status"** → **"Targets"**
3. Look for your pods' targets
4. Check if metrics are being scraped (should show "UP")

### Step 2: Create Application Dashboard

#### Create a new dashboard with:

1. **App Status Panel**
   ```promql
   count(kube_pod_status_phase{namespace="default", pod=~"simple-k8s-cicd.*", phase="Running"})
   ```

2. **App Resource Usage Panel**
   ```promql
   sum(container_memory_usage_bytes{namespace="default", pod=~"simple-k8s-cicd.*"}) by (pod_name)
   ```

3. **App Pod Restarts Panel**
   ```promql
   sum(increase(kube_pod_container_status_restarts_total{namespace="default", pod=~"simple-k8s-cicd.*"}[1h])) by (pod_name)
   ```

4. **App CPU Usage Panel**
   ```promql
   sum(rate(container_cpu_usage_seconds_total{namespace="default", pod=~"simple-k8s-cicd.*"}[5m])) by (pod_name)
   ```

### Step 3: Add Alerting (Optional)

1. In a panel, click **"Alert"** tab
2. Set **"Evaluate every"** (e.g., 1m)
3. Set **"For"** (e.g., 5m - wait 5 min before alerting)
4. Set **"Conditions"** (e.g., when value > threshold)
5. Set **"No Data and Execution Errors"** handling

---

## 🎯 Quick PromQL Cheat Sheet

```promql
# Current value
metric_name

# Range vector (last 5 minutes)
metric_name[5m]

# Rate of change
rate(counter[5m])

# Increase over period
increase(counter[1h])

# Sum by label
sum(metric) by (label)

# Top 5 values
topk(5, metric)

# Average by label
avg(metric) by (label)

# Filter by label
metric{label="value"}

# Regex match
metric{label=~"pattern.*"}

# Comparison
metric > 100

# Arithmetic
metric / 1024 / 1024  # Convert bytes to MB

# Boolean operations
metric1 > 50 and metric2 < 100

# Function
rate(http_requests_total[5m]) * 1000  # Convert to milliseconds
```

---

## 📚 Resources & Next Steps

1. **PromQL Explorer**: In Prometheus UI, try different queries
2. **Grafana Dashboards Library**: Import community dashboards
3. **Alert Setup**: Configure alerts in Grafana or Prometheus
4. **Custom Metrics**: Instrument your app with Prometheus client library
5. **Remote Storage**: Configure Prometheus remote write for long-term storage

---

**Last Updated**: 2026-04-24
