# ============================================================
# deploy.ps1 — One-click Kubernetes deployment script (PowerShell)
#
# Usage:
#   .\kubernetes\deploy.ps1
# ============================================================

Write-Host "======================================================" -ForegroundColor Cyan
Write-Host " 🚀 Multi-Tenant SaaS Platform — Kubernetes Deployment" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan

# 1. Create namespaces
Write-Host "`n📦 [1/4] Applying Namespaces (tenant-a, tenant-b, tenant-c)..." -ForegroundColor Yellow
kubectl apply -f kubernetes/namespaces.yaml

# 2. Deploy tenant resources
Write-Host "`n🔵 [2/4] Deploying Tenant A (ABC Retail)..." -ForegroundColor Blue
kubectl apply -f kubernetes/tenant-a/

Write-Host "`n🟢 [2/4] Deploying Tenant B (XYZ Hospital)..." -ForegroundColor Green
kubectl apply -f kubernetes/tenant-b/

Write-Host "`n🟠 [2/4] Deploying Tenant C (PQR School)..." -ForegroundColor DarkYellow
kubectl apply -f kubernetes/tenant-c/

# 3. Deploy Ingress
Write-Host "`n🌐 [3/4] Applying AWS ALB Ingress..." -ForegroundColor Magenta
kubectl apply -f kubernetes/ingress-alb.yaml

# 4. Check status
Write-Host "`n⏳ [4/4] Deployment finished! Checking resource status...`n" -ForegroundColor Cyan
kubectl get pods,svc,ingress --all-namespaces | Select-String -Pattern "tenant|NAMESPACE"

Write-Host "`n======================================================" -ForegroundColor Green
Write-Host " ✅ All tenant resources deployed successfully!" -ForegroundColor Green
Write-Host "======================================================" -ForegroundColor Green
