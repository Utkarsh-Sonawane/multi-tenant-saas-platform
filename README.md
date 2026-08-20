# Multi-Tenant SaaS Platform — Amazon EKS Demo

> **Portfolio Project** — Demonstrates Kubernetes multi-tenancy, Amazon RDS PostgreSQL, AWS ALB Ingress, CI/CD-readiness, Prometheus monitoring, and dynamic tenant routing using **one codebase and one Docker image**.

---

## Architecture Diagram

```
Internet
   │
   ▼
┌─────────────────────────────────────────────────────┐
│            AWS Application Load Balancer            │
│         (AWS Load Balancer Controller / ALB)        │
│                                                     │
│  /tenant-a ──► tenant-a-service (namespace: tenant-a)  │
│  /tenant-b ──► tenant-b-service (namespace: tenant-b)  │
│  /tenant-c ──► tenant-c-service (namespace: tenant-c)  │
└─────────────────────────────────────────────────────┘
         │                │                │
         ▼                ▼                ▼
   ┌──────────┐    ┌──────────┐    ┌──────────┐
   │ Pod(s)   │    │ Pod(s)   │    │ Pod(s)   │
   │ Tenant A │    │ Tenant B │    │ Tenant C │
   │ (Flask)  │    │ (Flask)  │    │ (Flask)  │
   └────┬─────┘    └────┬─────┘    └────┬─────┘
        │               │               │
        └───────────────┼───────────────┘
                        │ (same image, different env vars)
                        ▼
         ┌──────────────────────────────┐
         │   Amazon RDS PostgreSQL      │
         │                              │
         │  config_db   (tenant registry)  │
         │  tenant_a_db (ABC Retail)    │
         │  tenant_b_db (XYZ Hospital)  │
         │  tenant_c_db (PQR School)    │
         └──────────────────────────────┘
```

---

## Key Design Principles

| Principle | Implementation |
|-----------|---------------|
| **One image, N tenants** | Single Docker image deployed across 3 namespaces with different env vars |
| **Config-driven routing** | `config_db.tenant_config` table drives theme, DB name, and modules |
| **No hardcoded tenant logic** | All tenant data queried dynamically; `MODULE_TABLE_MAP` maps module→table |
| **Namespace isolation** | Each tenant in its own K8s namespace with separate Secrets |
| **Dynamic frontend** | Theme color injected as CSS custom property; sidebar menus auto-generated |
| **Production observability** | Prometheus metrics at `/metrics`, structured JSON logs on stdout |

---

## Project Structure

```
multi-tenant-platform/
├── backend/
│   ├── app.py           # Flask routes, auth, middleware
│   ├── config.py        # Configuration from env vars
│   ├── db_manager.py    # Dynamic SQLAlchemy engine registry
│   ├── logger.py        # Structured JSON logging
│   ├── metrics.py       # Prometheus metrics
│   └── requirements.txt
│
├── frontend/
│   ├── templates/
│   │   ├── base.html        # Layout scaffold with dynamic theme injection
│   │   ├── login.html       # Tenant login portal
│   │   ├── dashboard.html   # SaaS admin dashboard
│   │   ├── module_page.html # Data table for any module
│   │   ├── 404.html
│   │   └── 500.html
│   └── static/
│       ├── css/style.css    # Premium Vanilla CSS (dark mode, glassmorphism)
│       ├── js/main.js       # Dark mode, sidebar, toasts, search
│       └── js/charts.js     # Dynamic Chart.js loader
│
├── database/
│   ├── init_config_db.sql   # config_db schema + 3 tenant seed records
│   ├── init_tenant_a.sql    # products, customers, orders
│   ├── init_tenant_b.sql    # patients, doctors, appointments
│   ├── init_tenant_c.sql    # students, teachers, attendance
│   └── seed_all.py          # Local DB setup utility
│
├── docker/
│   ├── Dockerfile           # Multi-stage Python 3.12 slim image
│   ├── docker-compose.yml   # Local dev stack (Postgres + app)
│   ├── entrypoint.sh        # DB readiness check + Gunicorn launch
│   └── .env.example         # Environment variable template
│
├── kubernetes/
│   ├── namespaces.yaml
│   ├── ingress-alb.yaml     # AWS ALB path-based ingress
│   ├── tenant-a/
│   │   ├── configmap.yaml
│   │   ├── secret.yaml
│   │   ├── deployment.yaml
│   │   └── service.yaml
│   ├── tenant-b/
│   │   └── … (same structure)
│   └── tenant-c/
│       └── … (same structure)
│
└── terraform/               # (existing) EKS, RDS, VPC, ALB infrastructure
```

---

## Tenant Configuration

| Property | Tenant A | Tenant B | Tenant C |
|----------|----------|----------|----------|
| **tenant_id** | `tenant-a` | `tenant-b` | `tenant-c` |
| **company_name** | ABC Retail | XYZ Hospital | PQR School |
| **theme_color** | `#0d6efd` (Blue) | `#198754` (Green) | `#fd7e14` (Orange) |
| **database** | `tenant_a_db` | `tenant_b_db` | `tenant_c_db` |
| **namespace** | `tenant-a` | `tenant-b` | `tenant-c` |
| **modules** | Products, Orders, Customers | Patients, Doctors, Appointments | Students, Teachers, Attendance |

---

## Quick Start — Local Development

### Prerequisites
- Docker Desktop (with Compose)
- Python 3.12 (optional, for direct run)
- PostgreSQL client (optional)

### 1. Clone and start

```bash
# From project root
docker-compose -f docker/docker-compose.yml up --build
```

This will:
1. Start PostgreSQL 15 on port 5432
2. Run `seed_all.py` to create all 4 databases with sample data
3. Start the Flask SaaS app on port 5000

### 2. Open in browser

| URL | Tenant |
|-----|--------|
| http://localhost:5000/tenant-a | ABC Retail (Blue) |
| http://localhost:5000/tenant-b | XYZ Hospital (Green) |
| http://localhost:5000/tenant-c | PQR School (Orange) |
| http://localhost:5000/metrics  | Prometheus metrics |
| http://localhost:5000/healthz  | Liveness probe |

### 3. Login credentials (demo)

| Username | Password |
|----------|----------|
| `admin`  | `admin123` |
| `viewer` | `viewer123` |

---

## Amazon EKS Deployment

### Prerequisites

```bash
# Install tools
brew install kubectl helm awscli eksctl
helm repo add eks https://aws.github.io/eks-charts && helm repo update
```

### Step 1 — Terraform Infrastructure (existing)

```bash
cd terraform/environments/prod
terraform init
terraform plan
terraform apply
```

This creates: VPC, EKS cluster, RDS PostgreSQL, ECR repository, ALB controller IAM role.

### Step 2 — Configure kubectl

```bash
aws eks update-kubeconfig \
  --region ap-south-1 \
  --name multi-tenant-eks-cluster
```

### Step 3 — Install AWS Load Balancer Controller

```bash
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=multi-tenant-eks-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller
```

### Step 4 — Initialize RDS databases

```bash
# Get RDS endpoint from Terraform output
RDS_ENDPOINT=$(terraform -chdir=terraform/environments/prod output -raw rds_endpoint)

# Run init scripts
PGHOST=$RDS_ENDPOINT PGUSER=postgres PGPASSWORD=your-password \
  python database/seed_all.py
```

### Step 5 — Build & push Docker image to ECR

```bash
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
REGION=ap-south-1
ECR_URI="${ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com/multi-tenant-saas"

# Authenticate
aws ecr get-login-password --region $REGION | \
  docker login --username AWS --password-stdin "${ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com"

# Build & push (from project root)
docker build -f docker/Dockerfile -t "${ECR_URI}:latest" .
docker push "${ECR_URI}:latest"
```

### Step 6 — Update image in deployments

```bash
# Replace placeholder in all deployment files
sed -i "s|YOUR_AWS_ACCOUNT_ID|${ACCOUNT}|g" kubernetes/tenant-*/deployment.yaml
```

### Step 7 — Update secrets with real values

```bash
# Encode your RDS password
echo -n "your-rds-password" | base64
# Paste result into kubernetes/tenant-*/secret.yaml → DB_PASSWORD
```

### Step 8 — Apply all Kubernetes manifests

```bash
# Apply in order
kubectl apply -f kubernetes/namespaces.yaml

kubectl apply -f kubernetes/tenant-a/
kubectl apply -f kubernetes/tenant-b/
kubectl apply -f kubernetes/tenant-c/

# Apply ingress (after services are ready)
kubectl apply -f kubernetes/ingress-alb.yaml
```

### Step 9 — Get ALB DNS name

```bash
kubectl get ingress multi-tenant-saas-ingress -n tenant-a \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

Open the ALB hostname directly over HTTP. No custom domain is required.

### Step 10 — Verify

```bash
kubectl get pods -n tenant-a
kubectl get pods -n tenant-b
kubectl get pods -n tenant-c
kubectl get svc --all-namespaces | grep tenant
kubectl get ingress -n tenant-a
```

---

## Observability

### Prometheus Metrics

The `/metrics` endpoint exposes:

| Metric | Type | Description |
|--------|------|-------------|
| `http_requests_total` | Counter | Total HTTP requests (by tenant, method, endpoint, status) |
| `http_request_duration_seconds` | Histogram | Request latency in seconds |
| `http_requests_in_progress` | Gauge | Concurrent in-flight requests |
| `db_connections_active` | Gauge | Active DB pool connections per tenant |
| `db_query_duration_seconds` | Histogram | DB query latency |
| `tenant_active` | Gauge | Tenant status (1=active, 0=inactive) |
| `tenant_config_loads_total` | Counter | Config cache hit/miss/error |

### Structured JSON Logs

Every request emits a single JSON log line:

```json
{
  "timestamp": "2026-08-06T12:34:56",
  "level": "INFO",
  "logger": "app",
  "message": "HTTP request",
  "tenant_id": "tenant-a",
  "endpoint": "dashboard",
  "method": "GET",
  "request_id": "a1b2c3d4",
  "status": 200,
  "duration_ms": 42.5,
  "environment": "production"
}
```

### CloudWatch Integration (EKS)

Add Fluent Bit daemonset to ship pod logs to CloudWatch Logs:

```bash
kubectl apply -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/fluent-bit/fluent-bit.yaml
```

---

## Security Notes

| Area | Production Recommendation |
|------|--------------------------|
| Secrets | Use **AWS Secrets Manager** + **External Secrets Operator** |
| Pod security | `runAsNonRoot: true`, drop all capabilities |
| Network | Security Group allows only ALB → pods on port 5000 |
| Database | RDS in private subnet, security group allows only EKS node CIDR |
| Transport | HTTP on the ALB |
| WAF | AWS WAF v2 on ALB (see ingress annotation) |
| RBAC | Separate ServiceAccount per namespace with minimal permissions |

---

## CI/CD Pipeline (GitHub Actions — add `.github/workflows/deploy.yml`)

```yaml
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::ACCOUNT:role/github-deploy-role
          aws-region: ap-south-1
      - name: Build & Push to ECR
        run: |
          aws ecr get-login-password | docker login --username AWS --password-stdin $ECR_URI
          docker build -f docker/Dockerfile -t $ECR_URI:$GITHUB_SHA .
          docker push $ECR_URI:$GITHUB_SHA
      - name: Update EKS deployments
        run: |
          aws eks update-kubeconfig --name multi-tenant-eks-cluster --region ap-south-1
          kubectl set image deployment/tenant-a-app saas-app=$ECR_URI:$GITHUB_SHA -n tenant-a
          kubectl set image deployment/tenant-b-app saas-app=$ECR_URI:$GITHUB_SHA -n tenant-b
          kubectl set image deployment/tenant-c-app saas-app=$ECR_URI:$GITHUB_SHA -n tenant-c
          kubectl rollout status deployment/tenant-a-app -n tenant-a
          kubectl rollout status deployment/tenant-b-app -n tenant-b
          kubectl rollout status deployment/tenant-c-app -n tenant-c
```

---

## Demo Credentials

| Username | Password | Role |
|----------|----------|------|
| admin | admin123 | Administrator |
| viewer | viewer123 | Read-only |

---

*Built for Cloud/DevOps portfolio demonstration.*
*Technologies: Python Flask · SQLAlchemy · PostgreSQL · Bootstrap 5 · Chart.js · Docker · Amazon EKS · AWS ALB · Prometheus · Gunicorn*
