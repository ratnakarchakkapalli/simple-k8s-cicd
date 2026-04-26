#!/bin/bash

# ============================================================================
# Prometheus & Grafana Setup for Kubernetes Monitoring
# ============================================================================

set -e

echo "🚀 Starting Prometheus & Grafana Setup..."
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================================
# 1. Check Prerequisites
# ============================================================================

echo -e "${BLUE}[1/6] Checking prerequisites...${NC}"

if ! command -v helm &> /dev/null; then
    echo -e "${RED}❌ Helm is not installed!${NC}"
    echo "Install Helm: https://helm.sh/docs/intro/install/"
    exit 1
fi

if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ kubectl is not installed!${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Helm and kubectl are installed${NC}"
echo ""

# ============================================================================
# 2. Create monitoring namespace
# ============================================================================

echo -e "${BLUE}[2/6] Creating monitoring namespace...${NC}"

kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
echo -e "${GREEN}✅ Namespace 'monitoring' ready${NC}"
echo ""

# ============================================================================
# 3. Add Prometheus Community Helm Repository
# ============================================================================

echo -e "${BLUE}[3/6] Adding Prometheus Community Helm repository...${NC}"

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

echo -e "${GREEN}✅ Helm repositories updated${NC}"
echo ""

# ============================================================================
# 4. Install kube-state-metrics
# ============================================================================

echo -e "${BLUE}[4/6] Installing kube-state-metrics...${NC}"

helm upgrade --install kube-state-metrics prometheus-community/kube-state-metrics \
    --namespace monitoring \
    --set replicas=1 \
    --set image.tag=v2.10.0 \
    --wait

echo -e "${GREEN}✅ kube-state-metrics installed${NC}"
echo ""

# ============================================================================
# 5. Install Prometheus
# ============================================================================

echo -e "${BLUE}[5/6] Installing Prometheus...${NC}"

# Create Prometheus values file
cat > /tmp/prometheus-values.yaml << 'EOF'
prometheus:
  prometheusSpec:
    # Retention period
    retention: 7d
    storageSpec:
      volumeClaimTemplate:
        spec:
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 10Gi
    
    # Service Monitor selector
    serviceMonitorSelectorNilUsesHelmValues: false
    
    # Pod Monitor selector
    podMonitorSelectorNilUsesHelmValues: false
    
    # Resource limits
    resources:
      requests:
        cpu: 100m
        memory: 256Mi
      limits:
        cpu: 500m
        memory: 512Mi

# Node Exporter
nodeExporter:
  enabled: true

# Prometheus Operator
prometheusOperator:
  enabled: true

# Grafana integration
grafana:
  enabled: false  # We'll install Grafana separately
EOF

helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
    --namespace monitoring \
    --values /tmp/prometheus-values.yaml \
    --wait

echo -e "${GREEN}✅ Prometheus installed${NC}"
echo ""

# ============================================================================
# 6. Install Grafana
# ============================================================================

echo -e "${BLUE}[6/6] Installing Grafana...${NC}"

# Create Grafana values file
cat > /tmp/grafana-values.yaml << 'EOF'
# Admin credentials
adminPassword: admin

# Persistence
persistence:
  enabled: true
  size: 5Gi

# Resource limits
resources:
  requests:
    cpu: 50m
    memory: 128Mi
  limits:
    cpu: 200m
    memory: 256Mi

# Data sources - automatically add Prometheus
datasources:
  datasources.yaml:
    apiVersion: 1
    datasources:
    - name: Prometheus
      type: prometheus
      url: http://prometheus-kube-prometheus-prometheus:9090
      access: proxy
      isDefault: true

# Dashboards - pre-loaded
dashboardProviders:
  dashboardproviders.yaml:
    apiVersion: 1
    providers:
    - name: 'default'
      orgId: 1
      folder: ''
      type: file
      disableDeletion: false
      updateIntervalSeconds: 10
      allowUiUpdates: true
      options:
        path: /var/lib/grafana/dashboards/default

dashboards:
  default:
    kubernetes-cluster:
      gnetId: 7249
      revision: 1
      datasource: Prometheus
    kubernetes-pods:
      gnetId: 6417
      revision: 1
      datasource: Prometheus
    prometheus-stats:
      gnetId: 2
      revision: 2
      datasource: Prometheus
EOF

helm upgrade --install grafana grafana/grafana \
    --namespace monitoring \
    --values /tmp/grafana-values.yaml \
    --wait

echo -e "${GREEN}✅ Grafana installed${NC}"
echo ""

# ============================================================================
# 7. Verify Installation
# ============================================================================

echo -e "${YELLOW}⏳ Waiting for all pods to be ready...${NC}"
kubectl rollout status deployment/prometheus-kube-prometheus-operator -n monitoring --timeout=300s 2>/dev/null || true
kubectl rollout status deployment/grafana -n monitoring --timeout=300s 2>/dev/null || true

echo ""
echo -e "${GREEN}✅ Installation Complete!${NC}"
echo ""

# ============================================================================
# 8. Display Access Information
# ============================================================================

echo -e "${BLUE}📊 Monitoring Stack Information:${NC}"
echo ""

echo "Pod Status:"
kubectl get pods -n monitoring
echo ""

echo "Services:"
kubectl get svc -n monitoring
echo ""

# ============================================================================
# 9. Port Forwarding Commands
# ============================================================================

echo -e "${YELLOW}🔗 To access Grafana and Prometheus:${NC}"
echo ""
echo "📈 Grafana:"
echo "  kubectl port-forward -n monitoring svc/grafana 3000:80"
echo "  Access: http://localhost:3000"
echo "  Username: admin"
echo "  Password: admin"
echo ""
echo "📊 Prometheus:"
echo "  kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090"
echo "  Access: http://localhost:9090"
echo ""

echo -e "${YELLOW}💡 Next Steps:${NC}"
echo "1. Run 'kubectl port-forward -n monitoring svc/grafana 3000:80' to access Grafana"
echo "2. Log in with username 'admin' and password 'admin'"
echo "3. Check the pre-loaded dashboards"
echo "4. Explore Prometheus metrics at http://localhost:9090"
echo ""

echo -e "${GREEN}✨ Monitoring setup complete!${NC}"
