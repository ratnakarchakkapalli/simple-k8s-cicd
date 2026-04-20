# ⚠️ IMPORTANT: Kubeconfig Setup for GitHub Actions

## Before Testing Full Automation

**The workflow is now fully automated**, but it requires your kubeconfig to be added to GitHub secrets. Follow these steps:

### Step 1: Get Your Encoded Kubeconfig

```bash
cat ~/.kube/config | base64
```

This will output a long base64 string. **Copy the entire output.**

### Step 2: Add to GitHub Secrets

1. Go to: `https://github.com/ratnakarchakkapalli/simple-k8s-cicd`
2. Click **Settings** (top menu)
3. Click **Secrets and variables** → **Actions** (left sidebar)
4. Click **New repository secret** (green button)
5. Fill in:
   - **Name:** `KUBE_CONFIG`
   - **Value:** Paste the entire base64 string from Step 1
6. Click **Add secret**

### Step 3: Verify

In GitHub > Settings > Secrets, you should see:
- ✅ `DOCKER_USERNAME`
- ✅ `DOCKER_PASSWORD`
- ✅ `KUBE_CONFIG` (new)

---

## ⚠️ Important Notes

### Security Warning

**This setup stores your kubeconfig in GitHub.** For development/learning: ✅ OK
For production: ❌ NOT recommended

Production alternatives:
- Use GitHub OIDC provider with AWS/GCP/Azure
- Use ArgoCD/Flux with GitOps
- Use sealed secrets in Kubernetes

### Current Kubeconfig Includes

Your kubeconfig contains:
- ✅ Cluster certificate (public)
- ✅ API server URL (public)
- ⚠️ Client certificate (sensitive - authenticates as you)
- ⚠️ Client key (sensitive - proves identity)

**Anyone with this kubeconfig can:**
- Access your local Kubernetes cluster
- Deploy to it
- Access all resources
- Potentially escalate privileges

### Mitigation Steps (Optional for Dev)

If concerned, create a limited service account instead:

```bash
# Create service account for GitHub Actions
kubectl create serviceaccount github-actions -n default

# Give it permission to manage deployments
kubectl create clusterrolebinding github-actions \
  --clusterrole=edit \
  --serviceaccount=default:github-actions

# Get token and server details
kubectl config view --raw
# Then manually construct kubeconfig with service account token

# Or use kubelogin for OIDC
```

But for learning purposes, using your personal kubeconfig is fine.

---

## Testing the Full Pipeline

Once `KUBE_CONFIG` is added to GitHub secrets:

### 1. Make a Test Change
```bash
cd /Users/ratnakarchakkapalli/Documents/K8s/simple-k8s-cicd

# Edit the HTML
echo '<h1>Updated to v7.0 - Full Automation Test!</h1>' > src/index.html

git add src/index.html
git commit -m "Test full automation pipeline v7.0"
git push origin main
```

### 2. Watch GitHub Actions
- Go to: https://github.com/ratnakarchakkapalli/simple-k8s-cicd/actions
- Click the latest workflow run
- Watch it execute: Test → Build & Push → Deploy to K8s

### 3. Verify Deployment
```bash
# Watch pods update in real-time
kubectl get pods -l app=simple-k8s-cicd -w

# Check image being used
kubectl describe pod <pod-name> | grep Image

# Test the app
kubectl port-forward svc/simple-k8s-cicd-service 8080:80
curl http://localhost:8080
```

---

## Expected Workflow Behavior

### If Everything Works ✅

```
git push → GitHub Actions (test, build, push) → Docker Hub gets new image
         ↓
         → GitHub Actions (deploy) → kubectl apply & rollout restart
         ↓
         → New pods spin up with new image
         ↓
         → Old pods terminate gracefully (zero downtime)
         ↓
         → Application updated
```

**Total time:** ~2-3 minutes

### If Deploy Job Fails ❌

Common reasons:
1. `KUBE_CONFIG` secret not added
   - Error: `Unknown flag: --kubeconfig`
   - Fix: Add the secret to GitHub

2. Kubeconfig invalid/expired
   - Error: `Unable to connect to the server`
   - Fix: Update secret with new kubeconfig

3. Context not found
   - Error: `error: Context "xxx" does not exist`
   - Fix: Verify kubeconfig has correct context name

Check logs in GitHub Actions > Run Details > Deploy job

---

## Summary

✅ **Workflow is ready for full automation**
⏳ **Waiting for:** `KUBE_CONFIG` to be added to GitHub secrets
🚀 **Once set:** Code changes will automatically deploy to Kubernetes

**No other steps needed!**

See `FULL_AUTOMATION_GUIDE.md` for complete documentation.
