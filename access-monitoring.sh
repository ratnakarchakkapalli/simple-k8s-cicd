#!/bin/bash

# ============================================================================
# Prometheus & Grafana - Quick Access Guide
# ============================================================================

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🚀 Prometheus & Grafana - Quick Access${NC}"
echo ""
echo "Choose what you'd like to do:"
echo ""
echo "1. Access Grafana Dashboard"
echo "2. Access Prometheus UI"
echo "3. Check Monitoring Status"
echo "4. View Prometheus Targets"
echo "5. Check Pod Logs"
echo "6. Port-forward All Services"
echo ""
echo -n "Enter choice [1-6]: "
read choice

case $choice in
  1)
    echo -e "${YELLOW}🚀 Starting port-forward to Grafana...${NC}"
    echo "Grafana will be available at: http://localhost:3000"
    echo "Username: admin"
    echo "Password: admin"
    echo ""
    echo "Press Ctrl+C to stop port-forward"
    kubectl port-forward -n monitoring svc/grafana 3000:80
    ;;

  2)
    echo -e "${YELLOW}🚀 Starting port-forward to Prometheus...${NC}"
    echo "Prometheus will be available at: http://localhost:9090"
    echo ""
    echo "Press Ctrl+C to stop port-forward"
    kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
    ;;

  3)
    echo -e "${BLUE}📊 Monitoring Stack Status${NC}"
    echo ""
    echo "Pods in monitoring namespace:"
    kubectl get pods -n monitoring -o wide
    echo ""
    echo "Services in monitoring namespace:"
    kubectl get svc -n monitoring
    echo ""
    echo "PersistentVolumeClaims:"
    kubectl get pvc -n monitoring
    ;;

  4)
    echo -e "${BLUE}🎯 Prometheus Scrape Targets${NC}"
    echo ""
    echo "Starting Prometheus port-forward (this will stay open)..."
    echo ""
    echo "1. Run this in a terminal:"
    echo "   kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090"
    echo ""
    echo "2. Then visit: http://localhost:9090/targets"
    echo ""
    read -p "Press Enter to continue..."
    kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
    ;;

  5)
    echo -e "${BLUE}📋 Pod Logs${NC}"
    echo ""
    echo "Which pod would you like to view logs for?"
    echo ""
    kubectl get pods -n monitoring
    echo ""
    read -p "Enter pod name: " podname
    kubectl logs -f -n monitoring $podname
    ;;

  6)
    echo -e "${GREEN}🔗 Port-forwarding All Services${NC}"
    echo ""
    echo "This will open multiple port-forwards in the background"
    echo "Grafana:      http://localhost:3000"
    echo "Prometheus:   http://localhost:9090"
    echo ""
    
    # Start port-forwards in background
    kubectl port-forward -n monitoring svc/grafana 3000:80 > /dev/null 2>&1 &
    GRAFANA_PID=$!
    
    kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090 > /dev/null 2>&1 &
    PROMETHEUS_PID=$!
    
    echo -e "${GREEN}✅ Port-forwards started!${NC}"
    echo ""
    echo "Grafana PID:      $GRAFANA_PID"
    echo "Prometheus PID:   $PROMETHEUS_PID"
    echo ""
    echo "To stop, run:"
    echo "  kill $GRAFANA_PID $PROMETHEUS_PID"
    echo ""
    echo "Or press Ctrl+C..."
    
    wait
    ;;

  *)
    echo "Invalid choice!"
    exit 1
    ;;
esac
