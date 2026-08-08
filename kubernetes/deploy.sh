#!/bin/bash
# ============================================================
# deploy.sh — One-click Kubernetes deployment script (Bash)
#
# Usage:
#   chmod +x kubernetes/deploy.sh
#   ./kubernetes/deploy.sh
# ============================================================
set -e

echo "======================================================"
echo " 🚀 Multi-Tenant SaaS Platform — Kubernetes Deployment"
echo "======================================================"

# 1. Create namespaces
echo -e "\n📦 [1/4] Applying Namespaces (tenant-a, tenant-b, tenant-c)..."
kubectl apply -f kubernetes/namespaces.yaml

# 2. Deploy tenant resources
echo -e "\n🔵 [2/4] Deploying Tenant A (ABC Retail)..."
kubectl apply -f kubernetes/tenant-a/

echo -e "\n🟢 [2/4] Deploying Tenant B (XYZ Hospital)..."
kubectl apply -f kubernetes/tenant-b/

echo -e "\n🟠 [2/4] Deploying Tenant C (PQR School)..."
kubectl apply -f kubernetes/tenant-c/

# 3. Deploy Ingress
echo -e "\n🌐 [3/4] Applying AWS ALB Ingress..."
kubectl apply -f kubernetes/ingress-alb.yaml

# 4. Check status
echo -e "\n⏳ [4/4] Deployment finished! Checking resource status...\n"
kubectl get pods,svc,ingress --all-namespaces | grep -E "tenant|NAMESPACE"

echo -e "\n======================================================"
echo " ✅ All tenant resources deployed successfully!"
echo "======================================================"
