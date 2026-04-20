# 🧪 Complete Pipeline Test Plan

## Pre-Test Checklist

Before running the complete automation test, verify:

- [ ] Docker Hub credentials added to GitHub secrets
  - `DOCKER_USERNAME`
  - `DOCKER_PASSWORD`
- [ ] Kubeconfig added to GitHub secrets
  - `KUBE_CONFIG`
- [ ] Repository is on GitHub
  - Remote: `git remote -v`
- [ ] Local K8s cluster is running
  - `kubectl cluster-info`
- [ ] Deployment manifest exists
  - `k8s/deployment.yaml`

---

## Test Scenario 1: Basic Automation (No Kubeconfig Yet)

### Objective
Verify that test and build steps work automatically.

### Steps

**1. Make a code change:**
```bash
cd /Users/ratnakarchakkapalli/Documents/K8s/simple-k8s-cicd

# Update version
cat > src/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>K8s App - v5.1</title>
</head>
<body>
    <h1>Hello from Simple K8s CI/CD Pipeline!</h1>
    <p>Version: 5.1</p>
    <p>Fully Automated Testing & Building</p>
</body>
</html>
EOF

git add src/index.html
git commit -m "Pipeline Test v5.1: Verify automated test and build"
git push origin main
```

**2. Check GitHub Actions:**
- Go to: https://github.com/ratnakarchakkapalli/simple-k8s-cicd/actions
- Click the latest run
- Expected to see:
  - ✅ "Run Tests" - PASSED
  - ✅ "Build & Push Docker Image" - PASSED (or SKIPPED if not on main)
  - ⏸️ "Deploy to Kubernetes" - SKIPPED (or FAILED if KUBE_CONFIG not set)

**3. Verify image on Docker Hub:**
```bash
# Check Docker Hub UI or use:
curl -s https://hub.docker.com/v2/repositories/ratnakar99/simple-k8s-cicd/tags | jq '.results[] | .name'
```

Expected: New tags like `main-abc1234def`, `main`, `latest`

---

## Test Scenario 2: Full End-to-End Automation (With Kubeconfig)

### Prerequisite
`KUBE_CONFIG` secret must be added to GitHub.

### Objective
Verify complete pipeline: Code → Test → Build → Push → Deploy to K8s

### Steps

**1. Get current pod state:**
```bash
# Terminal 1: Watch pods
kubectl get pods -l app=simple-k8s-cicd -w

# Terminal 2: Check current image
kubectl describe deployment simple-k8s-cicd | grep Image
```

**2. Make a significant code change:**
```bash
cd /Users/ratnakarchakkapalli/Documents/K8s/simple-k8s-cicd

# Update with noticeable change
cat > src/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>K8s App - v10.0 AUTOMATED</title>
    <style>
        body { font-family: Arial; background: #e8f4f8; padding: 20px; }
        h1 { color: #0066cc; }
        .status { 
            background: #90EE90; 
            padding: 10px; 
            border-radius: 5px;
            font-weight: bold;
        }
    </style>
</head>
<body>
    <h1>🚀 K8s CI/CD Pipeline - Fully Automated! 🚀</h1>
    <p style="font-size: 18px;"><strong>Version:</strong> 10.0 AUTOMATED</p>
    <div class="status">✅ Deployed automatically via GitHub Actions</div>
    <p>Commit triggered a fully automated pipeline:</p>
    <ol>
        <li>✅ Code pushed to GitHub</li>
        <li>✅ Tests ran automatically</li>
        <li>✅ Docker image built</li>
        <li>✅ Image pushed to Docker Hub</li>
        <li>✅ Kubernetes deployment updated</li>
        <li>✅ Pods restarted with new image</li>
    </ol>
    <p style="color: #666; font-size: 12px;">Updated: <span id="time"></span></p>
    <script>
        document.getElementById('time').textContent = new Date().toLocaleString();
    </script>
</body>
</html>
EOF

git add src/index.html
git commit -m "Full Automation Test v10.0: Complete end-to-end pipeline"
git push origin main
```

**3. Monitor in real-time:**

**Terminal 1 - Watch GitHub Actions:**
```bash
# Keep browser open to: https://github.com/ratnakarchakkapalli/simple-k8s-cicd/actions
# Watch status: Running → Completed
# Expected time: 2-3 minutes
```

**Terminal 2 - Watch K8s Pods:**
```bash
kubectl get pods -l app=simple-k8s-cicd -w

# Expected output:
# NAME                                  READY   STATUS              RESTARTS   AGE
# simple-k8s-cicd-xxxx-old    2/2     Running             0          10m
# simple-k8s-cicd-xxxx-old    2/2     Terminating         0          10m
# simple-k8s-cicd-yyyy-new    0/2     ContainerCreating   0          5s
# simple-k8s-cicd-yyyy-new    1/2     Running             0          10s
# simple-k8s-cicd-yyyy-new    2/2     Running             0          15s
```

**Terminal 3 - Monitor Deployment Rollout:**
```bash
kubectl rollout status deployment/simple-k8s-cicd --watch

# Expected: "deployment "simple-k8s-cicd" successfully rolled out"
```

**4. Verify new image is used:**
```bash
# Check all pods are using new image
kubectl get pods -l app=simple-k8s-cicd -o custom-columns=\
NAME:.metadata.name,\
IMAGE:.spec.containers[0].image

# Should show: ratnakar99/simple-k8s-cicd:main (or with latest SHA tag)
```

**5. Test the application:**
```bash
# Terminal 1: Port forward
kubectl port-forward svc/simple-k8s-cicd-service 8080:80

# Terminal 2: Test the app
curl http://localhost:8080
# or open http://localhost:8080 in browser

# Expected: Version 10.0 AUTOMATED visible with new styling
```

**6. Verify Docker Hub has new image:**
```bash
# Check tags (newest should be at top)
curl -s 'https://hub.docker.com/v2/repositories/ratnakar99/simple-k8s-cicd/tags' | \
  jq '.results[] | {name, last_updated}' | head -20
```

---

## Test Scenario 3: Rollback Test (Optional)

### Objective
Verify you can rollback to previous version if deployment has issues.

### Steps

**1. Check rollout history:**
```bash
kubectl rollout history deployment/simple-k8s-cicd

# Output:
# deployment.apps/simple-k8s-cicd
# REVISION  CHANGE-CAUSE
# 1         <none>
# 2         <none>
# 3         <none>
```

**2. Rollback to previous version:**
```bash
# Rollback 1 revision
kubectl rollout undo deployment/simple-k8s-cicd

# Or rollback to specific revision
kubectl rollout undo deployment/simple-k8s-cicd --to-revision=2

# Watch pods restart
kubectl get pods -l app=simple-k8s-cicd -w
```

**3. Verify previous app version:**
```bash
kubectl port-forward svc/simple-k8s-cicd-service 8080:80
curl http://localhost:8080
# Should see previous version
```

**4. Rollforward (if needed):**
```bash
kubectl rollout redo deployment/simple-k8s-cicd
```

---

## Test Scenario 4: Error Handling

### Test 4A: Workflow Failure (Build Fails)

**Objective:** Verify deploy doesn't run if build fails.

**Steps:**
```bash
# Break the Docker build intentionally
echo "INVALID DOCKER SYNTAX" >> Dockerfile

git add Dockerfile
git commit -m "Test: Intentional build failure"
git push origin main

# Check GitHub Actions
# Expected: Build job FAILED, Deploy job SKIPPED

# Fix it
git revert HEAD
git push origin main

# Expected: Next run should succeed
```

### Test 4B: Invalid Kubeconfig

**Objective:** Verify deploy fails gracefully with invalid kubeconfig.

**Steps:**
```bash
# In GitHub: Settings > Secrets > Edit KUBE_CONFIG
# Change some characters to make it invalid
# Update secret

# Make a code change and push
git add src/index.html
git commit -m "Test: Invalid kubeconfig"
git push origin main

# Check GitHub Actions
# Expected: Deploy job FAILED with error message
# Error message should indicate kubeconfig issue

# Restore valid kubeconfig
# Make a new push
git add src/index.html
git commit -m "Fix: Restore valid kubeconfig"
git push origin main

# Expected: All jobs PASSED
```

---

## Troubleshooting Guide

### Symptom: "Tests Failed"

```bash
# Check what test failed
# In GitHub Actions logs, look for error message

# Run locally
chmod +x tests/validate.sh
./tests/validate.sh

# Fix the issue and re-push
```

### Symptom: "Build Failed - Docker Login Error"

```bash
# Verify Docker Hub credentials in GitHub secrets
# Check if access token is still valid (might be revoked)

# Re-create access token:
# 1. Go to Docker Hub > Account Settings > Security
# 2. Create new access token
# 3. Update GitHub secret DOCKER_PASSWORD
# 4. Re-push code to trigger workflow
```

### Symptom: "Deploy Failed - Connection Refused"

```bash
# Verify kubeconfig is correct
cat ~/.kube/config | base64

# Update GitHub secret KUBE_CONFIG with fresh kubeconfig
# Make sure cluster is running: kubectl cluster-info
# Re-push code
```

### Symptom: "Pod Still Has Old Image"

```bash
# Check if rollout succeeded
kubectl rollout status deployment/simple-k8s-cicd

# If stuck, check events
kubectl describe deployment simple-k8s-cicd

# If liveness probe failing, check logs
kubectl logs -l app=simple-k8s-cicd -f

# Check image pull policy
kubectl get pod <name> -o jsonpath='{.spec.containers[0].imagePullPolicy}'
# Should be: Always
```

### Symptom: "GitHub Actions Workflow Stuck"

```bash
# Cancel the stuck workflow in GitHub UI
# or use GitHub CLI:
gh run cancel <RUN_ID>

# Check workflow syntax
cat .github/workflows/ci-cd.yml

# Push a fix
git add .github/workflows/ci-cd.yml
git commit -m "Fix: Workflow syntax"
git push origin main
```

---

## Performance Metrics

Expected timing for complete pipeline:

| Step | Time | Notes |
|------|------|-------|
| Test | ~10s | Runs validation |
| Build Docker Image | ~30-60s | Depends on cache |
| Push to Docker Hub | ~10-20s | Depends on image size |
| Deploy to K8s | ~30-60s | Includes rollout wait |
| **Total** | **~2-3 min** | From push to pods ready |

If any step takes >5 minutes, might indicate:
- Network issues
- Resource constraints
- Build cache problems
- Cluster connectivity issues

---

## Success Checklist

After Test Scenario 2 completes successfully, verify:

- [ ] GitHub Actions workflow completed with all jobs passing
- [ ] Docker image appears on Docker Hub with correct tags
- [ ] Kubernetes deployment updated (new revision)
- [ ] All pods running with new image
- [ ] Application displays new version
- [ ] Readiness/liveness probes passing
- [ ] Zero pod downtime during update (rolling update worked)
- [ ] Port-forward test shows new app version
- [ ] Old pods have been terminated

If all checks pass: ✅ **Pipeline is fully automated!**

---

## Next Steps

1. Run Test Scenario 1 first (basic automation)
2. Add `KUBE_CONFIG` to GitHub secrets
3. Run Test Scenario 2 (full automation)
4. Optionally run Test Scenario 3 & 4
5. Review `FULL_AUTOMATION_GUIDE.md` for production considerations

---

## Quick Reference Commands

```bash
# Check workflow status
gh run list --repo ratnakarchakkapalli/simple-k8s-cicd

# View specific run logs
gh run view <RUN_ID> --log

# Check pod status
kubectl get pods -l app=simple-k8s-cicd -o wide

# View deployment
kubectl describe deployment simple-k8s-cicd

# Check recent K8s events
kubectl get events --sort-by='.lastTimestamp' | tail -20

# Test application
kubectl port-forward svc/simple-k8s-cicd-service 8080:80
curl http://localhost:8080

# Check image in use
kubectl get pods -l app=simple-k8s-cicd -o jsonpath='{.items[0].spec.containers[0].image}'

# View rollout history
kubectl rollout history deployment/simple-k8s-cicd

# Rollback if needed
kubectl rollout undo deployment/simple-k8s-cicd
```

Enjoy your fully automated CI/CD pipeline! 🚀
