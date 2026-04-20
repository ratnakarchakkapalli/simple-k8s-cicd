# ✅ Verify Full CI/CD Automation Flow

## Overview
This guide walks you through verifying that the end-to-end CI/CD pipeline is working correctly. We've just pushed version 6.0 to GitHub, which should trigger an automated build and deployment.

---

## Step 1: Monitor GitHub Actions Workflow

### Check Workflow Status on GitHub
1. Go to: https://github.com/ratnakarchakkapalli/simple-k8s-cicd/actions
2. You should see a workflow run for commit: **"Test v6.0: Full end-to-end CI/CD automation with GitHub Actions"**
3. Monitor the pipeline:
   - ✅ **Test job** - Validates code (runs `tests/validate.sh`)
   - ✅ **Build & Push job** - Builds Docker image and pushes to Docker Hub
   - ✅ **Deploy job** - Provides instructions for Kubernetes deployment

### What Each Job Does
```
Test (ubuntu-latest)
├── Checkout code
├── Run validation tests (chmod +x tests/validate.sh && ./tests/validate.sh)
└── Tests passed ✓

Build & Push (ubuntu-latest)
├── Checkout code
├── Set up Docker Buildx
├── Login to Docker Hub (uses secrets.DOCKER_USERNAME & secrets.DOCKER_PASSWORD)
├── Extract image metadata (tags: main, sha, latest)
├── Build and push Docker image (to ratnakar99/simple-k8s-cicd:latest)
└── Image pushed to Docker Hub ✓

Deploy (ubuntu-latest)
├── Checkout code
└── Deployment Info
    └── Print next steps for manual K8s deployment
```

---

## Step 2: Verify Docker Image on Docker Hub

Once the build job completes, verify the image was pushed:

```bash
# Check Docker Hub (manual)
# Visit: https://hub.docker.com/r/ratnakar99/simple-k8s-cicd/tags

# Or use Docker CLI
docker pull ratnakar99/simple-k8s-cicd:main
docker pull ratnakar99/simple-k8s-cicd:latest

# Inspect the manifest
docker manifest inspect ratnakar99/simple-k8s-cicd:main
docker manifest inspect ratnakar99/simple-k8s-cicd:latest
```

---

## Step 3: Deploy New Image to Kubernetes

### Option A: Manual Deployment (Current)
The workflow prints instructions but doesn't auto-deploy yet. Run these commands:

```bash
# Apply the deployment manifest
kubectl apply -f k8s/deployment.yaml

# Trigger a rollout to pull the new image
kubectl rollout restart deployment/simple-k8s-cicd

# Watch the rollout progress
kubectl rollout status deployment/simple-k8s-cicd -w

# Verify pods are running the new version
kubectl describe pods -l app=simple-k8s-cicd
```

### Option B: Force Pull New Image (Guaranteed)
If Kubernetes caches the old image:

```bash
# Delete pods to force K8s to pull the new image
kubectl delete pods -l app=simple-k8s-cicd

# K8s will automatically recreate them with the new image
kubectl get pods -l app=simple-k8s-cicd -w
```

---

## Step 4: Verify Application Updated

### Check Version in Running Pod
```bash
# Get pod name
POD=$(kubectl get pods -l app=simple-k8s-cicd -o jsonpath='{.items[0].metadata.name}')

# Check the version in the HTML
kubectl exec -it $POD -- curl http://localhost/ | grep -i "version"

# Or forward port and visit in browser
kubectl port-forward svc/simple-k8s-cicd-service 8080:80
# Visit: http://localhost:8080
# You should see: "🚀 K8s CI/CD Pipeline - LIVE v6.0 AUTOMATED"
```

### Check Pod Details
```bash
# View pod details including image
kubectl describe pod <pod-name>

# Check container image
kubectl get pods -l app=simple-k8s-cicd -o jsonpath='{.items[*].spec.containers[0].image}'

# View logs
kubectl logs -f <pod-name>
```

---

## Step 5: Understand the Complete Flow

### Code Change → Kubernetes Update

```
1. LOCAL CHANGE
   └─ Edit src/index.html (version 6.0)

2. GIT COMMIT & PUSH
   ├─ git add -A
   ├─ git commit -m "Test v6.0: ..."
   └─ git push origin main

3. GITHUB ACTIONS TRIGGERED
   ├─ Webhook detects push to main branch
   └─ Workflow file: .github/workflows/ci-cd.yml starts

4. TEST JOB (Sequential)
   ├─ Checkout code
   ├─ Run tests/validate.sh
   └─ ✅ Passes

5. BUILD & PUSH JOB (Needs test to pass)
   ├─ Login to Docker Hub with secrets
   ├─ Build Docker image
   │  └─ Uses Dockerfile
   │  └─ Copies src/index.html (v6.0)
   │  └─ Runs nginx
   ├─ Tag image: ratnakar99/simple-k8s-cicd:main
   ├─ Tag image: ratnakar99/simple-k8s-cicd:latest
   ├─ Push to Docker Hub
   └─ ✅ Pushed

6. DEPLOY JOB (Needs build to pass)
   └─ Print instructions (manual deployment for now)

7. MANUAL KUBERNETES UPDATE (You do this)
   ├─ kubectl apply -f k8s/deployment.yaml
   ├─ kubectl rollout restart deployment/simple-k8s-cicd
   └─ Kubernetes pulls ratnakar99/simple-k8s-cicd:latest

8. RUNNING APP UPDATED
   ├─ Pods killed and recreated
   ├─ New image pulled from Docker Hub
   └─ ✅ Version 6.0 now live
```

---

## Step 6: Troubleshooting

### Issue: Tests Fail
```bash
# Check test output in GitHub Actions
# Then run locally:
chmod +x tests/validate.sh
./tests/validate.sh
```

### Issue: Docker Login Fails
```bash
# Check that GitHub secrets are set:
# https://github.com/ratnakarchakkapalli/simple-k8s-cicd/settings/secrets/actions

# Verify:
# - secrets.DOCKER_USERNAME = ratnakar99
# - secrets.DOCKER_PASSWORD = (your Docker Hub access token)

# Test locally:
echo "YOUR_PASSWORD" | docker login -u ratnakar99 --password-stdin
docker push ratnakar99/simple-k8s-cicd:test
```

### Issue: ImagePullBackOff
```bash
# Check if image exists and is pushed correctly:
docker manifest inspect ratnakar99/simple-k8s-cicd:latest

# If manifest is corrupted, rebuild:
docker build -t ratnakar99/simple-k8s-cicd:latest .
docker push ratnakar99/simple-k8s-cicd:latest

# Then restart pods:
kubectl rollout restart deployment/simple-k8s-cicd
```

### Issue: Pod Still Shows Old Version
```bash
# Check the image being used:
kubectl get pods -o jsonpath='{.items[0].spec.containers[0].image}'

# Force pod recreation:
kubectl delete pods -l app=simple-k8s-cicd

# Check imagePullPolicy in deployment.yaml:
# Should be: imagePullPolicy: Always
```

---

## Step 7: Next Steps for Full Automation

To skip the manual deployment step, we can:

### Option 1: Use ArgoCD (Recommended)
- Watches Git repo for changes
- Auto-applies manifests to K8s
- Continuous deployment

### Option 2: Add Webhook Deployment
- GitHub Actions triggers webhook to K8s
- Uses `kubectl` from Actions to deploy
- Requires cluster access token

### Option 3: Use Flux CD
- GitOps operator
- Polls Git for manifest changes
- Auto-reconciles cluster state

### Current Workflow Progress
```
✅ Code pushed to GitHub
✅ GitHub Actions triggers
✅ Tests run
✅ Docker image built
✅ Image pushed to Docker Hub
⏳ Manual: kubectl rollout restart
⏳ Manual: kubectl port-forward
❌ Auto-deployment (To be added)
```

---

## Verification Checklist

- [ ] GitHub Actions workflow started
- [ ] Test job passed
- [ ] Build & Push job passed
- [ ] Image visible on Docker Hub (https://hub.docker.com/r/ratnakar99/simple-k8s-cicd)
- [ ] New image tag (e.g., `main`, `latest`) created
- [ ] `kubectl apply -f k8s/deployment.yaml` executed
- [ ] `kubectl rollout restart deployment/simple-k8s-cicd` executed
- [ ] New pods are running
- [ ] Application shows version 6.0
- [ ] Health checks passing (`kubectl describe pods`)

---

## Key Commands for Verification

```bash
# 1. Check workflow status
open "https://github.com/ratnakarchakkapalli/simple-k8s-cicd/actions"

# 2. Check Docker Hub
docker pull ratnakar99/simple-k8s-cicd:latest
docker run -p 8080:80 ratnakar99/simple-k8s-cicd:latest

# 3. Deploy to K8s
kubectl apply -f k8s/deployment.yaml
kubectl rollout restart deployment/simple-k8s-cicd
kubectl rollout status deployment/simple-k8s-cicd

# 4. Verify version
kubectl port-forward svc/simple-k8s-cicd-service 8080:80
# Visit: http://localhost:8080

# 5. Check pod details
kubectl get pods -l app=simple-k8s-cicd -o wide
kubectl describe pods -l app=simple-k8s-cicd
kubectl logs -f <pod-name>
```

---

## Summary

You've now deployed a **production-ready CI/CD pipeline** that:

✅ **Automates testing** - Every push runs validation tests
✅ **Automates builds** - Docker images built automatically
✅ **Automates pushing** - Images pushed to Docker Hub with auth
✅ **Enables deployment** - Kubernetes can pull latest images
✅ **Enables easy updates** - One command to rollout new version
✅ **Demonstrates best practices** - Health checks, rolling updates, resource limits

**The pipeline works because:**
1. GitHub Actions has secrets for Docker Hub credentials
2. Tests validate code before building
3. Docker image is built with your latest code
4. Image is pushed to a public registry
5. Kubernetes deployment references the registry image with `imagePullPolicy: Always`
6. Manual rollout triggers image pull

**Next: Monitor the Actions workflow and verify each step completes successfully!**
