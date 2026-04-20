# 🎯 CI/CD Pipeline Setup Guide

Complete step-by-step guide to set up your GitHub Actions CI/CD pipeline.

## 📋 Prerequisites Checklist

- [ ] Docker installed and running
- [ ] Docker Hub account created
- [ ] GitHub account with this repo
- [ ] Kubernetes cluster accessible (local or cloud)
- [ ] kubectl configured
- [ ] Git installed

## 🔧 Step 1: GitHub Secrets Setup

Your GitHub Actions workflow needs credentials to push to Docker Hub.

### 1.1 Create Docker Hub Access Token

1. Go to **Docker Hub** → https://hub.docker.com/settings/security
2. Click **"New Access Token"**
3. Name it: `github-actions`
4. Click **"Generate"**
5. **Copy the token** (won't show again!)

### 1.2 Add Secrets to GitHub

1. Go to your GitHub repository
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **"New repository secret"**
4. Create two secrets:

**Secret 1: DOCKER_USERNAME**
- Name: `DOCKER_USERNAME`
- Value: Your Docker Hub username (e.g., `ratnakar99`)

**Secret 2: DOCKER_PASSWORD**  
- Name: `DOCKER_PASSWORD`
- Value: The access token you copied from Docker Hub

✅ Save both secrets

## 🚀 Step 2: Test Locally

### 2.1 Build Docker Image

```bash
cd /Users/ratnakarchakkapalli/Documents/K8s/simple-k8s-cicd

docker build -t ratnakar99/simple-k8s-cicd:test .
```

**Expected output:** `=> exporting to image ... naming to docker.io/ratnakar99/simple-k8s-cicd:test`

### 2.2 Test Container

```bash
docker run -d -p 8080:80 --name test ratnakar99/simple-k8s-cicd:test

# Test it works
curl http://localhost:8080 | head -20

# Cleanup
docker stop test && docker rm test
```

**Expected output:** HTML content of your page

## 📦 Step 3: Push to GitHub

### 3.1 Initialize Git (if not already done)

```bash
cd /Users/ratnakarchakkapalli/Documents/K8s/simple-k8s-cicd

git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### 3.2 Create GitHub Repository

1. Go to https://github.com/new
2. Repository name: `simple-k8s-cicd`
3. Click **"Create repository"**
4. Copy the commands shown

### 3.3 Push Code to GitHub

```bash
# From your project directory
git init
git add .
git commit -m "Initial commit: K8s CI/CD pipeline setup"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/simple-k8s-cicd.git
git push -u origin main
```

## ⚙️ Step 4: Verify GitHub Actions

### 4.1 Check Workflow Trigger

1. Go to your GitHub repo
2. Click **"Actions"** tab
3. You should see **"Build and Push Docker Image"** workflow
4. If green ✅ = success
5. If yellow ⏳ = running
6. If red ❌ = failed

### 4.2 Check Workflow Details

Click the workflow run to see:
- Build step logs
- Image push logs
- Test results

### 4.3 Common Issues

**Issue:** Workflow not running?
```
Solution: Check that .github/workflows/docker-build-push.yml exists in main branch
```

**Issue:** Failed to login to Docker Hub?
```
Solution: Verify DOCKER_USERNAME and DOCKER_PASSWORD secrets are set correctly
```

**Issue:** Failed to push image?
```
Solution: Ensure DOCKER_USERNAME matches your Docker Hub account
```

## 🐳 Step 5: Verify Docker Hub Image

1. Go to **Docker Hub** → https://hub.docker.com/r/YOUR_USERNAME/simple-k8s-cicd
2. You should see:
   - `latest` tag (most recent)
   - `<git-sha>` tag (specific commit)
3. Images should be uploaded recently

### Pull and Test

```bash
docker pull ratnakar99/simple-k8s-cicd:latest
docker run -d -p 8080:80 ratnakar99/simple-k8s-cicd:latest
curl http://localhost:8080
```

## ☸️ Step 6: Deploy to Kubernetes

### 6.1 Update Deployment YAML

Edit `k8s/deployment.yaml` and ensure:
- Image name matches your Docker Hub username
- Example: `image: ratnakar99/simple-k8s-cicd:latest`

### 6.2 Apply Deployment

```bash
kubectl apply -f k8s/deployment.yaml
```

**Output should show:**
```
deployment.apps/simple-k8s-cicd created
service/simple-k8s-cicd-service created
```

### 6.3 Verify Deployment

```bash
# Check deployment
kubectl get deployments
kubectl get pods
kubectl get svc

# Get more details
kubectl describe deployment simple-k8s-cicd
```

### 6.4 Access Application

```bash
# Get the node IP and port
kubectl get svc simple-k8s-cicd-service -o wide

# Access the app
curl http://<NODE-IP>:30080

# Or use port-forward
kubectl port-forward svc/simple-k8s-cicd-service 8080:80
curl http://localhost:8080
```

## 🔄 Step 7: Test Full Pipeline

Now let's test the complete automation!

### 7.1 Make a Code Change

Edit `src/index.html` and change the title:
```html
<h1>🚀 My K8s CI/CD Pipeline - Updated!</h1>
```

### 7.2 Commit and Push

```bash
cd /Users/ratnakarchakkapalli/Documents/K8s/simple-k8s-cicd

git add src/index.html
git commit -m "Update homepage title"
git push origin main
```

### 7.3 Watch GitHub Actions

1. Go to GitHub repo → **Actions**
2. Watch the workflow run in real-time
3. When complete, image is pushed to Docker Hub with your changes

### 7.4 Update Kubernetes

Force Kubernetes to pull the new image:

```bash
# Force update
kubectl rollout restart deployment simple-k8s-cicd

# Watch pods restart
kubectl get pods -w

# Check the updated page
curl http://localhost:8080
```

You should see your updated title! 🎉

## 📊 Monitor the Pipeline

### Check Workflow Status

```bash
# See workflow runs
gh run list --repo YOUR_USERNAME/simple-k8s-cicd

# View specific run
gh run view <run-id> --repo YOUR_USERNAME/simple-k8s-cicd
```

### Monitor Kubernetes

```bash
# Watch pods
kubectl get pods -w

# See events
kubectl get events --sort-by='.lastTimestamp'

# Check deployment rollouts
kubectl rollout status deployment simple-k8s-cicd

# View pod logs
kubectl logs -l app=simple-k8s-cicd
```

### Check Docker Hub

```bash
# List your images
docker images | grep simple-k8s-cicd

# Pull latest from Docker Hub
docker pull ratnakar99/simple-k8s-cicd:latest

# Check Docker Hub via browser
https://hub.docker.com/r/YOUR_USERNAME/simple-k8s-cicd
```

## 🎓 What You've Built

✅ **Automated Testing** - GitHub Actions tests code changes
✅ **Docker Building** - Images built automatically on push
✅ **Registry Management** - Images stored in Docker Hub
✅ **Container Security** - Health checks & resource limits
✅ **Zero-Downtime Deployments** - Rolling updates strategy
✅ **Enterprise Practices** - Probes, limits, version tags

## 🆘 Troubleshooting

### Workflow failing?

```bash
# View workflow logs
# Go to GitHub repo → Actions → Failed workflow → Click step
```

### Pods not updating?

```bash
# Force re-pull image
kubectl set image deployment/simple-k8s-cicd \
  web=ratnakar99/simple-k8s-cicd:latest --record

# Or restart deployment
kubectl rollout restart deployment simple-k8s-cicd
```

### Can't access service?

```bash
# Check service
kubectl describe svc simple-k8s-cicd-service

# Test with port-forward
kubectl port-forward svc/simple-k8s-cicd-service 8080:80

# Try different port if 30080 is taken
# Edit k8s/deployment.yaml and change nodePort value
```

### Docker Hub image not found?

```bash
# Verify image exists
docker pull ratnakar99/simple-k8s-cicd:latest

# Check Docker Hub directly
# https://hub.docker.com/r/YOUR_USERNAME/simple-k8s-cicd
```

## 🚀 Next Steps

1. **Expand Tests** - Add more validation in GitHub Actions
2. **Add Staging** - Deploy to staging environment first
3. **Add Notifications** - Slack/email on deployment
4. **Add Metrics** - Prometheus monitoring
5. **Add Security Scanning** - Trivy or Docker Scout
6. **Multi-arch Builds** - Support ARM64 and AMD64
7. **GitOps** - Use ArgoCD for K8s deployments

## 📚 Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Kubernetes Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [CI/CD Best Practices](https://www.atlassian.com/continuous-delivery)

---

**Congratulations! You now have a production-grade CI/CD pipeline! 🎉**
