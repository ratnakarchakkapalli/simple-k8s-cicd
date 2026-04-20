# 🚀 Complete Automation Flow - Quick Reference

## What Just Happened (v6.0 Deployment)

### Timeline of Automation

```
├─ ⏰ 14:23 - You pushed v6.0 to GitHub
│  └─ Command: git push
│
├─ ⏰ 14:24 - GitHub received the push
│  └─ Webhook triggered
│
├─ ⏰ 14:25 - GitHub Actions workflow started
│  ├─ Test job spawned (ubuntu-latest)
│  ├─ Test job: Ran tests/validate.sh
│  └─ Test job: ✅ PASSED
│
├─ ⏰ 14:26 - Build job started (waiting for test)
│  ├─ Set up Docker Buildx
│  ├─ Login to Docker Hub (ratnakar99 with secret token)
│  ├─ Built Docker image from Dockerfile
│  │  └─ COPY src/index.html → copies v6.0
│  ├─ Tagged: ratnakar99/simple-k8s-cicd:main
│  ├─ Tagged: ratnakar99/simple-k8s-cicd:latest
│  ├─ Pushed both tags to Docker Hub
│  └─ ✅ BUILD & PUSH PASSED
│
├─ ⏰ 14:27 - Deploy job runs (information only)
│  ├─ Prints deployment instructions
│  └─ ✅ DEPLOY JOB PASSED
│
└─ ⏰ NOW - Manual step needed
   ├─ Run: kubectl apply -f k8s/deployment.yaml
   ├─ Run: kubectl rollout restart deployment/simple-k8s-cicd
   └─ Wait: Pods updated with new image
```

---

## The GitHub Actions Workflow

### File: `.github/workflows/ci-cd.yml`

```yaml
name: CI/CD Pipeline
on:
  push:
    branches: [main, develop]  # ← Triggers on push to main
  pull_request:
    branches: [main]           # ← Also runs on pull requests

jobs:
  test:                        # ← Job 1: Test
    runs-on: ubuntu-latest
    steps:
      - Checkout code
      - Run tests/validate.sh
      - Echo "Tests passed"
    
  build-and-push:              # ← Job 2: Build (needs test to pass)
    runs-on: ubuntu-latest
    needs: test               # ← Wait for test to pass
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    steps:
      - Checkout code
      - Set up Docker Buildx
      - Login to Docker Hub (using secrets.DOCKER_USERNAME & secrets.DOCKER_PASSWORD)
      - Build and push Docker image
    
  deploy:                     # ← Job 3: Deploy (needs build to pass)
    runs-on: ubuntu-latest
    needs: build-and-push     # ← Wait for build to pass
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    steps:
      - Checkout code
      - Print deployment instructions
```

**Key Points:**
- ✅ `on: push` - Triggers whenever you push to main
- ✅ `needs: test` - Build only runs if test passes
- ✅ `needs: build-and-push` - Deploy only runs if build passes
- ✅ `if: github.ref == 'refs/heads/main'` - Only runs on main branch
- ✅ `secrets.DOCKER_USERNAME` & `secrets.DOCKER_PASSWORD` - Secure credentials

---

## How Your Code Gets to Kubernetes

### The Complete Path

```
Your Machine (localhost)
│
├─ src/index.html (v6.0)
├─ Dockerfile
└─ .github/workflows/ci-cd.yml
   │
   └─ git add -A
      git commit -m "v6.0"
      git push origin main
         │
         ▼
GitHub Repository (github.com/ratnakarchakkapalli/simple-k8s-cicd)
   │
   ├─ Webhook triggered
   └─ GitHub Actions runner starts
      │
      ├─ Test Job
      │  ├─ Checkout code
      │  ├─ Run tests/validate.sh
      │  └─ Result: PASS ✅
      │
      ├─ Build & Push Job (waits for test)
      │  ├─ Checkout code
      │  ├─ Build Docker image
      │  │  └─ Dockerfile: FROM nginx + COPY src/index.html
      │  ├─ Tag: ratnakar99/simple-k8s-cicd:main
      │  ├─ Tag: ratnakar99/simple-k8s-cicd:latest
      │  ├─ Push to Docker Hub (authenticate with secrets)
      │  └─ Result: PUSH ✅
      │
      └─ Deploy Job (waits for build)
         └─ Print instructions
            │
            ▼
Docker Hub Registry (hub.docker.com)
   │
   └─ ratnakar99/simple-k8s-cicd
      ├─ Tag: main       ← Latest from main branch
      ├─ Tag: latest     ← Always latest
      ├─ Tag: old-hash   ← Previous versions
      └─ Image Layers
         ├─ nginx base
         └─ src/index.html (v6.0)
            │
            ▼
Your Kubernetes Cluster (minikube, Docker Desktop, etc.)
   │
   ├─ kubectl apply -f k8s/deployment.yaml
   │  └─ Creates Deployment: simple-k8s-cicd
   │
   ├─ kubectl rollout restart deployment/simple-k8s-cicd
   │  └─ Kills old pods, creates new pods
   │
   ├─ Kubernetes scheduler
   │  └─ "New pod needs image: ratnakar99/simple-k8s-cicd:latest"
   │
   ├─ Kubelet pulls image from Docker Hub
   │  └─ Downloads ratnakar99/simple-k8s-cicd:latest
   │     └─ Includes src/index.html (v6.0)
   │
   └─ Pod starts
      ├─ Nginx serving index.html (v6.0)
      ├─ Readiness probe: ✅ READY
      ├─ Liveness probe: ✅ ALIVE
      └─ Visit http://localhost:8080
         └─ Shows: "🚀 K8s CI/CD Pipeline - LIVE v6.0 AUTOMATED"
```

---

## Manual Deployment Step (Why It's Needed)

### Current State
The GitHub Actions workflow **does NOT have cluster credentials**, so it can only:
- ✅ Build and push Docker images
- ❌ Deploy directly to Kubernetes

### Why?
- Security: Don't want GitHub Actions to have K8s cluster access
- Flexibility: You decide when to deploy
- Visibility: You control the deployment process

### Solution for Full Automation
1. **Add K8s credentials to GitHub**
   - Create a service account in your cluster
   - Generate credentials (token + CA cert)
   - Add to GitHub secrets

2. **Update workflow to deploy**
   ```yaml
   - name: Deploy to Kubernetes
     run: |
       kubectl apply -f k8s/deployment.yaml
       kubectl rollout restart deployment/simple-k8s-cicd
   ```

3. **Result: Fully automated from code push → live app**

---

## Verification Commands

### Check GitHub Actions
```bash
# Open GitHub Actions page
open "https://github.com/ratnakarchakkapalli/simple-k8s-cicd/actions"

# Or use GitHub CLI
gh run list --repo ratnakarchakkapalli/simple-k8s-cicd
gh run view <RUN_ID>
```

### Check Docker Hub
```bash
# List tags
curl -s https://registry.hub.docker.com/v2/repositories/ratnakar99/simple-k8s-cicd/tags/ | jq '.results[].name'

# Or visit
open "https://hub.docker.com/r/ratnakar99/simple-k8s-cicd/tags"

# Pull locally and test
docker pull ratnakar99/simple-k8s-cicd:latest
docker run -p 8080:80 ratnakar99/simple-k8s-cicd:latest
# Visit http://localhost:8080
```

### Check Kubernetes
```bash
# Apply deployment
kubectl apply -f k8s/deployment.yaml

# Restart deployment
kubectl rollout restart deployment/simple-k8s-cicd

# Watch rollout
kubectl rollout status deployment/simple-k8s-cicd -w

# Check pods
kubectl get pods -l app=simple-k8s-cicd -o wide

# Check image
kubectl get pods -o jsonpath='{.items[0].spec.containers[0].image}'

# Access app
kubectl port-forward svc/simple-k8s-cicd-service 8080:80
# Visit http://localhost:8080
```

---

## Understanding the Architecture

### Components

```
┌─────────────────────────────────────────────────────────┐
│                    Your Workflow                         │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  ┌──────────────┐        ┌────────────────────────┐    │
│  │ src/         │        │  .github/workflows/    │    │
│  │ ├─ index.html│─push──▶│  └─ ci-cd.yml          │    │
│  │ └─ (v6.0)    │        └────────────────────────┘    │
│  │              │               │                       │
│  │              │               │ (detects push)       │
│  └──────────────┘               ▼                       │
│                          ┌────────────────────────┐    │
│                          │  GitHub Actions       │    │
│                          │  ├─ Test Job         │    │
│                          │  ├─ Build & Push Job │    │
│                          │  └─ Deploy Job       │    │
│                          └────────────────────────┘    │
│                                 │                       │
│                                 ▼                       │
│                          ┌────────────────────────┐    │
│                          │  Docker Hub Registry   │    │
│                          │  ratnakar99/           │    │
│                          │  simple-k8s-cicd:      │    │
│                          │  ├─ latest            │    │
│                          │  ├─ main              │    │
│                          │  └─ (other tags)      │    │
│                          └────────────────────────┘    │
│                                 │                       │
│                                 ▼                       │
│                   ┌──────────────────────────────┐    │
│                   │  Your K8s Cluster            │    │
│                   │  ┌──────────────────────┐   │    │
│                   │  │ Deployment:          │   │    │
│                   │  │ simple-k8s-cicd      │   │    │
│                   │  │ image: ...latest ◄──┼───┼────│ pulls
│                   │  │ replicas: 2          │   │    │
│                   │  └──────────────────────┘   │    │
│                   │  ┌──────────────────────┐   │    │
│                   │  │ Pods (2 replicas)    │   │    │
│                   │  │ ├─ Pod-1: v6.0 ✅    │   │    │
│                   │  │ └─ Pod-2: v6.0 ✅    │   │    │
│                   │  └──────────────────────┘   │    │
│                   │  ┌──────────────────────┐   │    │
│                   │  │ Service (NodePort)   │   │    │
│                   │  │ Listening on 8080 ◄──┼──┼────│ visit
│                   │  └──────────────────────┘   │    │
│                   └──────────────────────────────┘    │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### The Two Environments

```
LOCAL TESTING                    PRODUCTION KUBERNETES
─────────────────────────────────────────────────────
src/index.html                   ratnakar99/simple-k8s-cicd
│                                │
├─ docker build                  ├─ Stored in Docker Hub
│  └─ Creates local image        │  └─ Accessible to anyone
│
├─ docker run                     ├─ kubectl apply
│  └─ Container on localhost     │  └─ Deployment in cluster
│
└─ curl/browser                   └─ kubectl port-forward
   http://localhost:8080            http://localhost:8080
```

---

## Summary

**Version 6.0 Deployment Status:**

1. ✅ **Code pushed to GitHub** - `git push origin main`
2. ✅ **GitHub Actions triggered** - Webhook detected push
3. ✅ **Tests ran** - `tests/validate.sh` passed
4. ✅ **Docker image built** - Using Dockerfile + v6.0 HTML
5. ✅ **Image pushed to Docker Hub** - `ratnakar99/simple-k8s-cicd:latest`
6. ⏳ **Manual deployment needed** - Run `kubectl rollout restart ...`
7. ⏳ **Pods updating** - Pulling new image from Docker Hub
8. ⏳ **App live** - Version 6.0 serving on port 8080

**Next Actions:**
```bash
kubectl apply -f k8s/deployment.yaml
kubectl rollout restart deployment/simple-k8s-cicd
kubectl port-forward svc/simple-k8s-cicd-service 8080:80
# Visit: http://localhost:8080
```

**Expected Result:**
- Pods restart
- New image pulled: `ratnakar99/simple-k8s-cicd:latest`
- Page shows: "🚀 K8s CI/CD Pipeline - LIVE v6.0 AUTOMATED"

---

## Additional Resources

- `.github/workflows/ci-cd.yml` - GitHub Actions workflow
- `Dockerfile` - Docker image definition
- `k8s/deployment.yaml` - Kubernetes deployment
- `tests/validate.sh` - Automated tests
- `VERIFY_AUTOMATION.md` - Detailed verification guide
- `PIPELINE_COMPLETE.md` - Previous pipeline setup documentation
