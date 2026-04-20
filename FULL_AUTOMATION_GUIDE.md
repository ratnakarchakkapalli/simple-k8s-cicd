# Full End-to-End CI/CD Pipeline Automation Guide

## 🎯 Overview

This guide completes the **fully automated CI/CD pipeline** where:

```
Code Change → Git Push → GitHub Actions → Docker Build & Push → Kubernetes Deploy
```

All steps happen automatically with **zero manual intervention**.

---

## ✅ What's Automated

### 1. **Testing** ✅
- Automatically runs on every push
- Runs `validate.sh` to check Docker build and HTML structure

### 2. **Docker Build & Push** ✅
- Automatically builds Docker image
- Pushes to Docker Hub with tags (branch, SHA, latest)
- Only runs on pushes to `main` branch

### 3. **Kubernetes Deployment** ✅ (NEW)
- Automatically applies deployment manifests
- Triggers rolling restart to pull new image
- Waits for rollout to complete
- Verifies all pods are ready
- Only runs on pushes to `main` branch

---

## 🔧 Prerequisites

### A. Docker Hub Credentials (Already Done)
✅ `DOCKER_USERNAME` - Your Docker Hub username
✅ `DOCKER_PASSWORD` - Your Docker Hub access token

### B. Kubernetes Credentials (New)
You need to add your kubeconfig to GitHub secrets:

1. **Get your encoded kubeconfig:**
   ```bash
   cat ~/.kube/config | base64
   ```

2. **Add to GitHub Secrets:**
   - Go to: `https://github.com/YOUR_USERNAME/simple-k8s-cicd/settings/secrets/actions`
   - Click "New repository secret"
   - **Name:** `KUBE_CONFIG`
   - **Value:** Paste the base64-encoded output from step 1
   - Click "Add secret"

> ⚠️ **Security Note:** This stores your kubeconfig in GitHub. For production:
> - Use GitHub OIDC provider with AWS/GCP/Azure
> - Use sealed secrets or External Secrets Operator in K8s
> - Use ArgoCD or Flux for GitOps-style deployment

---

## 🚀 Testing the Full Pipeline

### Step 1: Make a Code Change
```bash
cd /path/to/simple-k8s-cicd

# Edit the HTML file
vim src/index.html

# Change the version or message
# e.g., "Hello from v2.0!" 

git add src/index.html
git commit -m "Update app to v2.0"
```

### Step 2: Push to GitHub
```bash
git push origin main
```

### Step 3: Monitor GitHub Actions
1. Go to: `https://github.com/YOUR_USERNAME/simple-k8s-cicd/actions`
2. Click the latest workflow run
3. Watch the steps execute:
   - ✅ **Run Tests** - Validates code
   - ✅ **Build & Push Docker Image** - Creates and pushes image
   - ✅ **Deploy to Kubernetes** - Deploys and restarts pods

### Step 4: Verify the Deployment
```bash
# Check if new pods are running
kubectl get pods -l app=simple-k8s-cicd -w

# Check the image they're using
kubectl describe pod <pod-name> | grep Image

# Port forward and test
kubectl port-forward svc/simple-k8s-cicd-service 8080:80

# Visit http://localhost:8080 in browser or:
curl http://localhost:8080
```

---

## 📊 Understanding the Workflow

### Workflow File Structure
```
.github/workflows/ci-cd.yml
├── on: [push to main, PRs]
├── test job (always runs)
│   └── Runs validation tests
├── build-and-push job (if tests pass AND main branch AND push event)
│   └── Builds and pushes Docker image to Docker Hub
└── deploy job (if build-and-push succeeds AND main branch AND push event)
    └── Deploys to Kubernetes and restarts pods
```

### Key Features

1. **Conditional Execution**
   ```yaml
   if: github.ref == 'refs/heads/main' && github.event_name == 'push'
   ```
   - Only builds/deploys on pushes to `main`
   - Skips on PRs (you can test separately)

2. **Job Dependencies**
   ```yaml
   needs: test
   needs: build-and-push
   ```
   - Each job waits for previous ones
   - If tests fail, build doesn't run
   - If build fails, deploy doesn't run

3. **Image Tags**
   ```
   ratnakar99/simple-k8s-cicd:main
   ratnakar99/simple-k8s-cicd:main-abc1234def  (commit SHA)
   ratnakar99/simple-k8s-cicd:latest
   ```

4. **Kubernetes Auto-Pull**
   ```yaml
   imagePullPolicy: Always
   ```
   - Ensures latest image is pulled even if tag exists
   - Paired with `kubectl rollout restart` for immediate update

---

## 🔍 Troubleshooting

### 1. Workflow Status in GitHub

**Check workflow logs:**
```bash
# View in browser: GitHub Actions tab
# Or use GitHub CLI:
gh run list --repo YOUR_USERNAME/simple-k8s-cicd
gh run view <RUN_ID> --log
```

### 2. Kubernetes Deployment Status
```bash
# Check deployment status
kubectl rollout status deployment/simple-k8s-cicd

# View recent events
kubectl describe deployment simple-k8s-cicd

# Check logs of pods
kubectl logs -l app=simple-k8s-cicd -f --tail=50
```

### 3. Common Issues

#### Issue: "Unauthorized: authentication required"
**Cause:** Docker Hub credentials not in GitHub secrets
**Fix:** Verify `DOCKER_USERNAME` and `DOCKER_PASSWORD` are set correctly

#### Issue: "Connection refused" in deploy step
**Cause:** Kubeconfig not in GitHub secrets or invalid
**Fix:** 
```bash
# Verify kubeconfig is valid
kubectl cluster-info
# Re-encode and add to GitHub secrets
cat ~/.kube/config | base64
```

#### Issue: Pod still showing old image after deploy
**Cause:** Rollout didn't wait or failed silently
**Fix:**
```bash
# Manually check and restart
kubectl get pods -o jsonpath='{.items[*].spec.containers[0].image}'
kubectl rollout restart deployment/simple-k8s-cicd
kubectl get pods -w
```

---

## 📈 Monitoring & Verification

### Check Docker Hub for New Images
```bash
# View images on Docker Hub via web or:
docker pull ratnakar99/simple-k8s-cicd:main
docker inspect ratnakar99/simple-k8s-cicd:main | grep -i created
```

### Check Kubernetes Deployment
```bash
# Deployment status
kubectl get deployment simple-k8s-cicd

# Pod status
kubectl get pods -l app=simple-k8s-cicd -o wide

# Recent events
kubectl get events --sort-by='.lastTimestamp' | tail -20

# Rolling update history
kubectl rollout history deployment/simple-k8s-cicd

# Rollback if needed
kubectl rollout undo deployment/simple-k8s-cicd --to-revision=<N>
```

### Test Application
```bash
# Port forward
kubectl port-forward svc/simple-k8s-cicd-service 8080:80

# In another terminal:
curl http://localhost:8080
# or open http://localhost:8080 in browser
```

---

## 🎬 Example: Complete Workflow

### Timeline of a Successful Deployment

```
1. Developer edits src/index.html
   └─ Time: 10:00 AM

2. Developer runs: git push origin main
   └─ Time: 10:01 AM
   └─ GitHub receives push

3. GitHub Actions triggers workflow
   └─ Time: 10:01 AM
   └─ run: Test job starts
       ├─ Checkout code
       ├─ Run validation tests
       └─ ✅ Tests pass (5s)
   
4. Build & Push job starts
   └─ Time: 10:02 AM
   └─ Steps:
       ├─ Checkout code
       ├─ Set up Docker Buildx
       ├─ Login to Docker Hub
       ├─ Build Docker image (~30s)
       └─ ✅ Push to Docker Hub (15s)
       └─ New images available:
           - ratnakar99/simple-k8s-cicd:main
           - ratnakar99/simple-k8s-cicd:main-abc1234
           - ratnakar99/simple-k8s-cicd:latest

5. Deploy job starts (only if build succeeds)
   └─ Time: 10:03 AM
   └─ Steps:
       ├─ Checkout code
       ├─ Set up kubectl with kubeconfig
       ├─ Apply deployment.yaml
       ├─ Trigger rolling restart
       │  └─ Kubernetes:
       │     ├─ Creates new pods with new image
       │     ├─ Waits for readiness (liveness/readiness probes)
       │     ├─ Terminates old pods (zero-downtime via rolling update)
       │     └─ Sets desired replicas = actual replicas
       └─ ✅ Deployment complete (10s)

6. Verification
   └─ Time: 10:04 AM
   └─ All pods running with new image
   └─ Application serving new content
   └─ Old pods terminated

Total time: ~3 minutes
Zero manual intervention! ✅
```

---

## 🔐 Security Best Practices

### Current Setup (Development)
✅ Good for learning and testing
⚠️ Kubeconfig stored in GitHub (acceptable for development)

### For Production

1. **Use GitHub OIDC Provider**
   - No secrets stored in GitHub
   - Tokens are short-lived
   - Audit trail in cloud provider

2. **Use ArgoCD/Flux**
   - GitOps approach
   - Automatic sync between repo and cluster
   - Built-in security features

3. **Implement RBAC**
   - Create service account with minimal permissions
   - Use kubeconfig with limited scope
   - Example:
     ```bash
     kubectl create serviceaccount github-actions -n default
     kubectl create clusterrolebinding github-actions \
       --clusterrole=edit \
       --serviceaccount=default:github-actions
     ```

4. **Use External Secrets**
   - Store secrets in Vault or AWS Secrets Manager
   - Kubernetes pulls on demand
   - Never expose secrets in kubeconfig

---

## 📝 Next Steps

### Enhancements
1. ✅ Full automation (just implemented)
2. Add Slack notifications on deployment
3. Add rollback triggers on failed health checks
4. Implement canary deployments
5. Add performance monitoring
6. Setup auto-scaling based on metrics

### Advanced Topics
- Helm charts for easier K8s management
- Multi-environment deployments (dev/staging/prod)
- Image signing and verification
- Policy enforcement (OPA/Kyverno)
- GitOps with ArgoCD

---

## ✨ Summary

You now have a **fully automated CI/CD pipeline**:

```
Every code push → Auto tests → Auto builds → Auto deploys to K8s
```

**No manual steps required!** 🚀

The workflow handles:
- Code validation
- Docker image building and pushing
- Kubernetes deployment and pod rolling restart
- Zero-downtime updates via rolling updates
- Health checks to ensure pod readiness

Enjoy your automated pipeline! 🎉
