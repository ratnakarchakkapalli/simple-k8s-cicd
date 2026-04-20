# Live End-to-End CI/CD Pipeline Test (v7.0)

## Test Objective
Verify that pushing code to GitHub triggers the full CI/CD pipeline:
1. GitHub Actions builds the Docker image
2. Image is pushed to Docker Hub
3. Kubernetes detects the new image
4. Pods automatically pull and run the new version
5. Application updates without manual intervention

## Timeline

### Step 1: Code Push (✅ COMPLETED)
- **Time:** Pushed v7.0 to GitHub main branch
- **Commit:** `e91e0c1` - "Test v7.0: Full end-to-end CI/CD pipeline verification"
- **Changed File:** `src/index.html` (version bumped from 6.0 to 7.0)
- **Status:** Code is on GitHub, workflow should be triggered

### Step 2: GitHub Actions Workflow (⏳ IN PROGRESS)
**Expected Steps:**
1. Run tests on the code
2. Build Docker image with buildx (multi-platform)
3. Push to Docker Hub with tags:
   - `ratnakar99/simple-k8s-cicd:main`
   - `ratnakar99/simple-k8s-cicd:main-<sha>`
   - `ratnakar99/simple-k8s-cicd:latest`
4. Print deployment info

**Monitoring:**
```bash
# Check GitHub Actions logs in the GitHub UI:
# https://github.com/ratnakarchakkapalli/simple-k8s-cicd/actions

# Or check Docker Hub for new image
docker pull ratnakar99/simple-k8s-cicd:main
docker inspect ratnakar99/simple-k8s-cicd:main | grep -i version
```

### Step 3: Kubernetes Pod Updates (⏳ PENDING)
**Expected Behavior:**
1. K8s detects new image in Docker Hub
2. Due to `imagePullPolicy: Always`, K8s fetches the new image
3. Rolling update starts (maxSurge: 1, maxUnavailable: 0)
4. Old pods are terminated, new pods created
5. New pods run v7.0

**Monitoring:**
```bash
# Watch pod updates in real-time
kubectl get pods -w

# Check pod image
kubectl describe pod <pod-name> | grep Image

# Verify application version
kubectl port-forward svc/simple-k8s-cicd-service 8080:80 &
curl http://localhost:8080 | grep -i "v7.0"
```

### Step 4: Final Verification (⏳ PENDING)
- [ ] Docker Hub has new image with v7.0
- [ ] K8s pods are running v7.0
- [ ] Application displays "v7.0 FULLY VERIFIED"
- [ ] Rolling update completed successfully

## Key Configuration

### Deployment Settings (k8s/deployment.yaml)
```yaml
imagePullPolicy: Always          # Always pull latest image
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1                  # One extra pod during update
    maxUnavailable: 0            # No pods offline during update
```

### GitHub Actions Workflow (.github/workflows/ci-cd.yml)
- Triggers on: push to main or develop branches
- Builds multi-platform image (amd64, arm64, etc.)
- Pushes with tags: main, main-<sha>, latest
- Includes Docker cache for faster builds

## Commands to Monitor

### Real-time Pod Monitoring
```bash
watch kubectl get pods
watch kubectl describe deployment simple-k8s-cicd
```

### Check Image Digest (before and after)
```bash
# Check current pods' image digest
kubectl get pods -o jsonpath='{.items[*].status.containerStatuses[*].imageID}'

# Check Docker Hub image digest
docker manifest inspect ratnakar99/simple-k8s-cicd:latest
```

### Timeline Recording
- v1.0-v5.0: Previous manual builds and tests
- v6.0: Code pushed, awaiting automated build
- v7.0: Testing full end-to-end automation (THIS TEST)

## Expected Outcomes

### Success Criteria
✅ All pods running with v7.0  
✅ No ImagePullBackOff or ErrImagePull errors  
✅ Rolling update completed in < 5 minutes  
✅ Zero downtime during update  

### What Should NOT Happen
❌ No manual kubectl commands needed (except monitoring)  
❌ No manual Docker build/push needed  
❌ No pod restart errors  
❌ No image pull failures  

## Notes for Future Reference

This test demonstrates the complete CI/CD automation:
- **Manual Steps:** Only push code to GitHub
- **Automated Steps:** Everything else (build, push, deploy)
- **Verification:** Can be done via kubectl and web browser
- **Time to Deploy:** ~2-3 minutes from git push to pod update
