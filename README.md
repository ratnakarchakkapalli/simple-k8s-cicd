# Simple K8s CI/CD Pipeline 🚀

A complete, enterprise-level CI/CD pipeline demonstration using Kubernetes, Docker, GitHub Actions, and Docker Hub.

## 📚 What You'll Learn

- ✅ **Testing** - Automated HTML validation
- ✅ **Building** - Docker image creation
- ✅ **Registry** - Docker Hub image management
- ✅ **Kubernetes** - Deployment & service management
- ✅ **CI/CD** - GitHub Actions automation
- ✅ **Enterprise Practices** - Health checks, rolling updates, resource limits

## 🏗️ Project Structure

```
simple-k8s-cicd/
├── src/
│   └── index.html          # Simple webpage
├── tests/
│   └── validate.sh         # HTML validation script
├── k8s/
│   └── deployment.yaml     # K8s deployment & service
├── .github/workflows/
│   └── ci-cd.yml          # GitHub Actions pipeline
├── Dockerfile             # Container definition
└── README.md
```

## 🔄 Complete CI/CD Workflow

```
1. Developer pushes code to GitHub
                ↓
2. GitHub Actions triggers automatically
                ↓
3. Run tests (HTML validation)
                ↓
4. Build Docker image
                ↓
5. Push to Docker Hub
                ↓
6. Manual: Deploy to K8s cluster
                ↓
7. Kubernetes pulls new image
                ↓
8. Pods restart with new version
                ↓
9. Website updated! ✨
```

## 🚀 Quick Start

### Prerequisites

- Docker Desktop (with K8s enabled)
- kubectl configured
- GitHub account
- Docker Hub account

### Step 1: Create GitHub Repository

```bash
# Create repo on GitHub named 'simple-k8s-cicd'
# Then clone it
git clone https://github.com/YOUR_USERNAME/simple-k8s-cicd.git
cd simple-k8s-cicd
```

### Step 2: Copy Files

Copy all files from this project into your GitHub repo.

### Step 3: Add GitHub Secrets

In your GitHub repository:
1. Go to **Settings** → **Secrets and variables** → **Actions**
2. Add these secrets:
   - `DOCKER_USERNAME`: Your Docker Hub username
   - `DOCKER_PASSWORD`: Your Docker Hub access token

### Step 4: Update Kubernetes Deployment

Edit `k8s/deployment.yaml` and update the image name:

```yaml
image: YOUR_USERNAME/simple-k8s-cicd:latest
```

### Step 5: Deploy to Kubernetes

```bash
# Apply deployment
kubectl apply -f k8s/deployment.yaml

# Check pods
kubectl get pods

# Port forward to access
kubectl port-forward svc/simple-k8s-cicd-service 8080:80

# Visit in browser
open http://localhost:8080
```

### Step 6: Trigger CI/CD Pipeline

```bash
# Edit src/index.html (change something)
# Push to main branch
git add .
git commit -m "Update website"
git push origin main

# Watch GitHub Actions run automatically!
# Then restart deployment:
kubectl rollout restart deployment/simple-k8s-cicd

# Check new pods
kubectl get pods
```

## 📊 Monitoring

### View deployment status
```bash
kubectl get deployment simple-k8s-cicd -w
```

### View pod logs
```bash
kubectl logs -f deployment/simple-k8s-cicd
```

### View pod events
```bash
kubectl describe pod <pod-name>
```

### Access the application
```bash
# Option 1: Port forward
kubectl port-forward svc/simple-k8s-cicd-service 8080:80

# Option 2: NodePort (if available)
kubectl get service simple-k8s-cicd-service
# Access on: http://localhost:30080
```

## 🔍 Understanding the Pipeline

### Tests Phase
- Validates HTML structure
- Checks for required tags
- Verifies file size

### Build Phase
- Uses multi-stage Docker build
- Alpine base (lightweight)
- Optimized for K8s

### Push Phase
- Pushes to Docker Hub
- Tags with commit SHA & latest
- Enables image tracking

### Deploy Phase
- K8s pulls new image with `imagePullPolicy: Always`
- Rolling update strategy (zero downtime)
- Health checks ensure pod readiness

## 🛠️ Kubernetes Features Used

- **Deployment** - Manages pod replicas
- **Service** - Exposes pods to network
- **Rolling Update** - Zero-downtime deployment
- **Health Checks**:
  - Liveness probe (is pod alive?)
  - Readiness probe (is pod ready for traffic?)
- **Resource Limits** - CPU & memory constraints
- **Image Pull Policy** - Always pull latest

## 📝 Customization

### Change replica count
Edit `k8s/deployment.yaml`:
```yaml
spec:
  replicas: 3  # Change from 2
```

### Change port mapping
Edit `k8s/deployment.yaml`:
```yaml
nodePort: 30081  # Change from 30080
```

### Modify website
Edit `src/index.html` and push to GitHub!

## 🎓 Learning Resources

- [Kubernetes Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [GitHub Actions](https://docs.github.com/en/actions)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [CI/CD Concepts](https://en.wikipedia.org/wiki/CI/CD)

## 🐛 Troubleshooting

### Pods not starting
```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

### Image not found
```bash
# Check Docker Hub
docker pull YOUR_USERNAME/simple-k8s-cicd:latest

# Verify deployment image name
kubectl get deployment simple-k8s-cicd -o yaml | grep image
```

### Port forward not working
```bash
# Use NodePort instead
kubectl get service simple-k8s-cicd-service
# Visit http://localhost:30080
```

## 📞 Support

If you encounter issues:
1. Check GitHub Actions logs
2. Check kubectl logs
3. Verify Docker Hub credentials
4. Ensure K8s cluster is running

---

**Happy Learning!** 🎓
This is a complete, production-ready CI/CD pipeline. Modify and expand it to learn more!
