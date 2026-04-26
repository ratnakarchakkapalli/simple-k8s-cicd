# 🚀 Instrumenting Your Application with Prometheus Metrics

## Overview

This guide shows how to add custom Prometheus metrics to your Node.js/Express application for detailed monitoring of HTTP requests, errors, and performance.

---

## Option 1: Simple HTTP Metrics (Express Middleware)

### Step 1: Install Dependencies

```bash
npm install prom-client express
```

### Step 2: Create Metrics Module

Create `src/metrics.js`:

```javascript
const promClient = require('prom-client');

// Define custom metrics
const httpRequestDuration = new promClient.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.1, 0.5, 1, 2, 5]
});

const httpRequestTotal = new promClient.Counter({
  name: 'http_requests_total',
  help: 'Total HTTP requests',
  labelNames: ['method', 'route', 'status_code']
});

const httpRequestsInProgress = new promClient.Gauge({
  name: 'http_requests_in_progress',
  help: 'HTTP requests in progress',
  labelNames: ['method', 'route']
});

const appVersion = new promClient.Gauge({
  name: 'app_version_info',
  help: 'Application version info',
  labelNames: ['version', 'build']
});

// Register default metrics (CPU, memory, etc.)
promClient.collectDefaultMetrics();

module.exports = {
  httpRequestDuration,
  httpRequestTotal,
  httpRequestsInProgress,
  appVersion,
  register: promClient.register
};
```

### Step 3: Add Middleware to Express

Update `src/index.js`:

```javascript
const express = require('express');
const path = require('path');
const metrics = require('./metrics');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware to track metrics
app.use((req, res, next) => {
  const start = Date.now();
  const route = req.route?.path || req.path;

  // Increment in-progress requests
  metrics.httpRequestsInProgress.inc({ method: req.method, route });

  // Listen for response finish
  res.on('finish', () => {
    const duration = (Date.now() - start) / 1000;

    // Record metrics
    metrics.httpRequestDuration.observe({
      method: req.method,
      route,
      status_code: res.statusCode
    }, duration);

    metrics.httpRequestTotal.inc({
      method: req.method,
      route,
      status_code: res.statusCode
    });

    metrics.httpRequestsInProgress.dec({ method: req.method, route });
  });

  next();
});

// Set app version
metrics.appVersion.set({ version: '1.0.0', build: 'docker' }, 1);

// Existing routes
app.use(express.static(path.join(__dirname)));

app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'index.html'));
});

// Prometheus metrics endpoint
app.get('/metrics', async (req, res) => {
  try {
    res.set('Content-Type', metrics.register.contentType);
    res.end(await metrics.register.metrics());
  } catch (err) {
    res.status(500).end(err);
  }
});

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Metrics available at http://localhost:${PORT}/metrics`);
});
```

### Step 4: Test Metrics Endpoint

```bash
# Build and run the container
docker build -t simple-k8s-cicd:latest .
docker run -p 3000:3000 simple-k8s-cicd:latest

# In another terminal, check the metrics endpoint
curl http://localhost:3000/metrics
```

You should see output like:

```
# HELP http_request_duration_seconds Duration of HTTP requests in seconds
# TYPE http_request_duration_seconds histogram
http_request_duration_seconds_bucket{le="0.1",method="GET",route="/",status_code="200"} 2
...
```

---

## Option 2: Add Service Monitor for Automatic Scraping

Create `k8s/servicemonitor.yaml`:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: simple-k8s-cicd
  namespace: default
  labels:
    app: simple-k8s-cicd
spec:
  selector:
    matchLabels:
      app: simple-k8s-cicd
  endpoints:
  - port: web
    path: /metrics
    interval: 30s
```

Apply it:

```bash
kubectl apply -f k8s/servicemonitor.yaml
```

Verify Prometheus is scraping:

```bash
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# Visit http://localhost:9090/targets
# Look for "simple-k8s-cicd" - should show "UP"
```

---

## Option 3: Custom Business Metrics

Extend `src/metrics.js` with business-specific metrics:

```javascript
const promClient = require('prom-client');

// Business metrics
const ordersProcessed = new promClient.Counter({
  name: 'orders_processed_total',
  help: 'Total orders processed',
  labelNames: ['status']
});

const processingTime = new promClient.Histogram({
  name: 'order_processing_time_seconds',
  help: 'Order processing time',
  labelNames: ['order_type'],
  buckets: [1, 5, 10, 30]
});

const activeUsers = new promClient.Gauge({
  name: 'active_users',
  help: 'Current active users'
});

const cacheHitRate = new promClient.Gauge({
  name: 'cache_hit_rate',
  help: 'Cache hit rate percentage',
  labelNames: ['cache_name']
});

// Usage in application
function processOrder(orderType) {
  const start = Date.now();
  
  try {
    // Process order...
    ordersProcessed.inc({ status: 'success' });
  } catch (err) {
    ordersProcessed.inc({ status: 'error' });
  }
  
  const duration = (Date.now() - start) / 1000;
  processingTime.observe({ order_type: orderType }, duration);
}

module.exports = {
  ordersProcessed,
  processingTime,
  activeUsers,
  cacheHitRate
};
```

---

## Monitoring Dashboard Queries

### Application Health Dashboard

```promql
# Request rate (requests per second)
rate(http_requests_total[5m])

# Error rate
rate(http_requests_total{status_code=~"5.."}[5m])

# Error rate percentage
(rate(http_requests_total{status_code=~"5.."}[5m]) / rate(http_requests_total[5m])) * 100

# P95 latency
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# Average request size
avg(http_request_size_bytes)

# In-progress requests
http_requests_in_progress
```

### Deployment Monitoring

```promql
# Pod crashes
increase(kube_pod_container_status_restarts_total{pod=~"simple-k8s-cicd.*"}[5m])

# Memory usage trending
sum(container_memory_usage_bytes{pod=~"simple-k8s-cicd.*"}) by (pod)

# CPU usage trending
sum(rate(container_cpu_usage_seconds_total{pod=~"simple-k8s-cicd.*"}[5m])) by (pod)

# Deployment scaling events
kube_deployment_status_replicas{deployment="simple-k8s-cicd"}
```

---

## Complete Instrumented Example

Create `src/index-instrumented.js`:

```javascript
const express = require('express');
const path = require('path');
const promClient = require('prom-client');

const app = express();
const PORT = process.env.PORT || 3000;

// ==================== METRICS SETUP ====================

// HTTP metrics
const httpDuration = new promClient.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status'],
  buckets: [0.1, 0.5, 1, 2, 5]
});

const httpRequests = new promClient.Counter({
  name: 'http_requests_total',
  help: 'Total HTTP requests',
  labelNames: ['method', 'route', 'status']
});

const requestsInFlight = new promClient.Gauge({
  name: 'http_requests_in_flight',
  help: 'HTTP requests in flight',
  labelNames: ['method', 'route']
});

// Business metrics
const pageViews = new promClient.Counter({
  name: 'page_views_total',
  help: 'Total page views',
  labelNames: ['page']
});

const apiCalls = new promClient.Counter({
  name: 'api_calls_total',
  help: 'Total API calls',
  labelNames: ['endpoint', 'status']
});

// Application info
const appInfo = new promClient.Gauge({
  name: 'app_info',
  help: 'Application information',
  labelNames: ['version', 'environment']
});

// Register default metrics (CPU, memory, etc.)
promClient.collectDefaultMetrics();

// ==================== MIDDLEWARE ====================

// Metrics collection middleware
app.use((req, res, next) => {
  const start = Date.now();
  const route = req.route?.path || req.path;

  requestsInFlight.inc({ method: req.method, route });

  res.on('finish', () => {
    const duration = (Date.now() - start) / 1000;
    const status = res.statusCode;

    httpDuration.observe({
      method: req.method,
      route,
      status
    }, duration);

    httpRequests.inc({
      method: req.method,
      route,
      status
    });

    requestsInFlight.dec({ method: req.method, route });
  });

  next();
});

// Set app info
appInfo.set({ version: 'v2.0', environment: 'kubernetes' }, 1);

// ==================== ROUTES ====================

app.use(express.static(path.join(__dirname)));

app.get('/', (req, res) => {
  pageViews.inc({ page: 'home' });
  res.sendFile(path.join(__dirname, 'index.html'));
});

app.get('/api/data', (req, res) => {
  apiCalls.inc({ endpoint: '/api/data', status: 'success' });
  res.json({ message: 'Data retrieved', timestamp: new Date() });
});

app.get('/health', (req, res) => {
  res.json({ status: 'healthy' });
});

app.get('/ready', (req, res) => {
  res.json({ ready: true });
});

// Prometheus metrics endpoint
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', promClient.register.contentType);
  res.end(await promClient.register.metrics());
});

// Error handling
app.get('/error', (req, res) => {
  apiCalls.inc({ endpoint: '/error', status: 'error' });
  res.status(500).json({ error: 'Test error' });
});

app.listen(PORT, () => {
  console.log(`✅ Server running on port ${PORT}`);
  console.log(`📊 Metrics available at http://localhost:${PORT}/metrics`);
  console.log(`❤️  Health check at http://localhost:${PORT}/health`);
});
```

---

## Grafana Dashboard JSON (for import)

1. Create a new dashboard
2. Click **Settings** → **JSON Model**
3. Paste this configuration:

```json
{
  "dashboard": {
    "title": "Application Metrics",
    "panels": [
      {
        "title": "Request Rate",
        "targets": [
          {
            "expr": "rate(http_requests_total[5m])"
          }
        ]
      },
      {
        "title": "Error Rate",
        "targets": [
          {
            "expr": "(rate(http_requests_total{status=~\"5..\"}[5m]) / rate(http_requests_total[5m])) * 100"
          }
        ]
      },
      {
        "title": "P95 Latency",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))"
          }
        ]
      },
      {
        "title": "In Flight Requests",
        "targets": [
          {
            "expr": "http_requests_in_flight"
          }
        ]
      }
    ]
  }
}
```

---

## 📝 Next Steps

1. **Add metrics to your application** using prom-client
2. **Deploy updated version** to Docker Hub
3. **Verify metrics** in Prometheus UI
4. **Create dashboards** in Grafana
5. **Set up alerts** based on metrics
6. **Monitor performance** over time

---

## 📚 Resources

- [Prometheus Client Library for Node.js](https://github.com/siimon/prom-client)
- [Prometheus Best Practices](https://prometheus.io/docs/practices/instrumentation/)
- [PromQL Documentation](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [Grafana Dashboard Best Practices](https://grafana.com/docs/grafana/latest/dashboards/)

---

**Last Updated**: 2026-04-24
