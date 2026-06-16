# Azure K8s CI/CD Demo

A production-ready CI/CD pipeline demonstrating containerized application deployment to Kubernetes on Azure. This project showcases DevOps best practices: infrastructure as code, automated testing, continuous integration, continuous deployment, and monitoring.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    GitHub Repository                        │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │         Git Push (Code Changes)                      │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│              GitHub Actions CI/CD Pipeline                  │
│                                                              │
│  1. Lint (flake8)     ▶  2. Test (pytest)  ▶  3. Build     │
│  4. Push to ACR       ▶  5. Status Check                    │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│         Azure Container Registry (ACR)                      │
│                                                              │
│  Stores Docker images with tags:                            │
│  - :latest (most recent)                                    │
│  - :{commit-sha} (specific version)                         │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│      Azure Kubernetes Service (AKS) Cluster                 │
│                                                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Kubernetes Pod (Flask App)                         │   │
│  │  - Liveness Probe: /health (K8s restart on failure) │   │
│  │  - Readiness Probe: /readiness (load balancer)      │   │
│  │  - Service: Exposes app on public IP                │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Other Pods/Services (as needed)                    │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│           Azure Monitor (Observability)                     │
│                                                              │
│  - Application Insights (logs, metrics, traces)             │
│  - Alerts (if response time > 500ms, CPU > 80%)             │
│  - Dashboard (real-time monitoring)                         │
└─────────────────────────────────────────────────────────────┘
```

## Features

✅ **Automated Testing** — Pytest runs on every push  
✅ **Code Quality** — Flake8 linting enforced in pipeline  
✅ **Docker Containerization** — Multi-stage builds for optimized images  
✅ **Infrastructure as Code** — Terraform provisions entire AKS stack  
✅ **Continuous Integration** — GitHub Actions automates lint, test, build  
✅ **Continuous Deployment** — Automatic push to registry & AKS deployment  
✅ **Production Ready** — Non-root user, health probes, gunicorn WSGI server  
✅ **Observability** — Azure Monitor dashboards & alerts  

## API Endpoints

- `GET /` — Welcome message
- `GET /health` — Kubernetes liveness probe
- `GET /readiness` — Kubernetes readiness probe
- `GET /api/v1/status` — Application status

## Quick Start (Local Development)

1. **Clone repo**
   ```bash
   git clone https://github.com/saybabatunde/azure-k8s-cicd-demo.git
   cd azure-k8s-cicd-demo
   ```

2. **Create virtual environment**
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

4. **Run tests**
   ```bash
   pytest test_app.py -v
   ```

5. **Run app**
   ```bash
   python app.py
   # Visit http://localhost:5000
   ```

## CI/CD Pipeline (GitHub Actions)

The pipeline runs automatically on every push to `main`:

1. **Lint** — Flake8 code quality checks
2. **Test** — Pytest unit tests with coverage
3. **Build** — Docker multi-stage build
4. **Push** — Image pushed to Azure Container Registry

**Required GitHub Secrets:**
- `ACR_LOGIN_SERVER` — Your ACR login server
- `ACR_USERNAME` — ACR username
- `ACR_PASSWORD` — ACR password

## Project Phases

- ✅ **Phase 1** — Flask app + Docker
- ⏳ **Phase 2** — GitHub Actions pipeline (in progress)
- ⏳ **Phase 3** — Terraform infrastructure
- ⏳ **Phase 4** — Kubernetes deployment
- ⏳ **Phase 5** — Azure Monitor observability

## Design Decisions

**Why Flask?** Lightweight, Pythonic, focuses on pipeline not app complexity.

**Why Gunicorn?** Production-grade WSGI server, handles concurrency.

**Why Multi-stage Docker?** ~60% smaller images, faster deployments.

**Why Non-root User?** Security hardening, production best practice.

**Why GitHub Actions?** Native GitHub integration, free for public repos.

## Resources

- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [Azure Kubernetes Service](https://learn.microsoft.com/en-us/azure/aks/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)

---

**Built by:** Olawalebabatunde  
**Portfolio:** [babatundeportfolio.com](https://babatundeportfolio.com)  
**License:** MIT