# ⚙️ GitHub Secrets Setup Guide

## Required Secrets for Full CI/CD Automation

The GitHub Actions workflow requires three secrets to be set up in your GitHub repository:

### 1. **DOCKER_PASSWORD** (Already Set ✅)
This is your Docker Hub access token for pushing images.

**Status:** ✅ Already configured  
**Used by:** Build & Push Docker Image job  
**For:** Authenticating with Docker Hub during image push

---

### 2. **KUBE_CONFIG** (NEEDS TO BE SET)
This is your Kubernetes configuration encoded in base64.

**Status:** ⚠️ MISSING - This is why the deploy job is failing!

**Steps to Add:**

1. Go to your GitHub repository settings:
   ```
   https://github.com/ratnakarchakkapalli/simple-k8s-cicd/settings/secrets/actions
   ```

2. Click **"New repository secret"**

3. Fill in the details:
   - **Name:** `KUBE_CONFIG`
   - **Value:** Copy the entire string below:
   ```
   YXBpVmVyc2lvbjogdjEKY2x1c3RlcnM6Ci0gY2x1c3RlcjoKICAgIGNlcnRpZmljYXRlLWF1dGhvcml0eS1kYXRhOiBMUzB0TFMxQ1JVZEpUaUJEUlZKVVNVWkpRMEZVUlMwdExTMHRDazFKU1VSQ2VrTkRRV1VyWjBGM1NVSkJaMGxKV1RoVU0xTnJablpZVVVWM1JGRlpTa3R2V2tsb2RtTk9RVkZGVEVKUlFYZEdWRVZVVFVKRlIwRXhWVVVLUVhoTlMyRXpWbWxhV0VwMVdsaFNiR282UVdkR2R6QjVUbXBCTUUxVVZYZE5la2w2VFdwR1lVZEJPSGxOVkVreVRVUk5lVTFxUVhwTmFtZDVUVlp2ZHdwR1ZFVlVUVUpGUjBFeFZVVkJlRTFMWVROV2FWcFlTblZhV0ZKc1kzcERRMEZUU1hkRVVWbEtTMjlhU1doMlkwNUJVVVZDUWxGQlJHZG5SVkJCUkVORENrRlJiME5uWjBWQ1FVdG9iM05HVjBNMVpVZEZjMWhYVDJOVmFVcE1iRk5wVmxOT2FYRnZaelpaTWxacGEyMXhhVmxQTDNKamFXVlhUVUo2WlUxak1sSUtieTlKTW1oWldGSnRVbmxLTDFNcmJrRkNXRFJ2U0dKdWRrcHlaVWw2TDNacU1HUjNNME5HWWxSMFFUTkJWakJFTkhFeFpuWnhOV3hpWnpWaWNrcEVVZ3B4ZERKRmFXNHdiVmxLU0dKU1dISTFkRXBEWWtaNGFFSnVjelpHU2tGTmFXbEtjbUYyU1hCM1VtUjNZa1pLUTJOWlJWbElVazVrTm1adFV6WnVUR1Z6Q21sdlExVkxRbEJyTldOamNsSmhSRlJtYTJJd1JrWlVaVGwwUW5ScVJUWTFaRlJQVmxwbk1qTXpja3BYTTBwdlNFdHJlV0psVFhkUmRHWk5lV2g2YURjS2J6VTVXRGh4YUc5UlpUQmxNbHBGWkdWb2VuTjZUbUpFUVRGeVRsZFlVVVZrWW1WTmNXcHdNazAwSzBaalQyWnljbkV6Wm05V1YwSmxNRFpNYVhCVWVRcHJTREpIZFZrMFV5dElkRFJEUkZoeGIwbHJOREpUTVc1Q1owTklSVVk0UTBGM1JVRkJZVTVhVFVaamQwUm5XVVJXVWpCUVFWRklMMEpCVVVSQlowdHJDazFCT0VkQk1WVmtSWGRGUWk5M1VVWk5RVTFDUVdZNGQwaFJXVVJXVWpCUFFrSlpSVVpGVUN0Tk9YSkhNVkF6YVVreU1WbDRSV2d2Y21WUWNXMXZTVWdLVFVKVlIwRXhWV1JGVVZGUFRVRjVRME50ZERGWmJWWjVZbTFXTUZwWVRYZEVVVmxLUzI5YVNXaDJZMDVCVVVWTVFsRkJSR2RuUlVKQlFVcEJlWGQwZHdwbFJIWllhVlpRV21ab05sUlJiVnBNY0dKRFdVWnVUWHB6T0ZKSmFHZHpTRlUzTml0R1YxbzVkbXBJU1hSV2JVTm5aRTUzVTFGTVJrSndOaTlQYWtoMkNtcFpSWEJuWkhsMWVXNUdhRnBvZFhsU0syeExlRmhWZHpKa1QwWnNPRVkxWW5wNlIyZHpkRnAzYm1sbWIyZGxlREZqVUc1TGFEQkRNMGQ2WWpCaFUxSUtlWE5UVFZaalMyMW5ibUpDVWs1VllsQlhWV2hJYnpOT2FrMWFSR2xqTkdKalIyaDFkMnhSWVV0bkwwRk1Sak5tT1dWck16bGhUbGwyZUc1clpVdFFRZ3BrZEROeWQwRk5ObVpzYTNNclZsUXlablEzUTJkb1JGWlpRalJVVDFVd1YyRkhUM000ZW1SRlVrVTBZVGhFWTFGSk9EZHRMekkyVERWSWNrSm9TVGhQQ2pCblJHb3hMeXQ0VEdsdmNsbEhSVXRUTmxkVWJFTnJMM0p2ZFVkM2FrSXpVM2RHTjJaQ2ExRm1hMWR4YkRNMGRIQmFlVXhPZEVaUGFpdHhPSFJ1U3k4S1ZURm9hV2N6UVdsRkZTRWRVUlZRNFBRb3RMUzB0TFVWVVJVRkRVMFJRUlMwdExTMHRDZz09CiAgICBzZXJ2ZXI6IGh0dHBzOi8vMTI3LjAuMC4xOjY0NDMKICBuYW1lOiBkb2NrZXItZGVza3RvcApjb250ZXh0czoKLSBjb250ZXh0OgogICAgY2x1c3RlcjogZG9ja2VyLWRlc2t0b3AKICAgIHVzZXI6IGRvY2tlci1kZXNrdG9wCiAgbmFtZTogZG9ja2VyLWRlc2t0b3AKY3VycmVudC1jb250ZXh0OiBkb2NrZXItZGVza3RvcApreW5kOiBDb25maWcKdXNlcnM6Ci0gbmFtZTogZG9ja2VyLWRlc2t0b3AKICB1c2VyOgogICAgY2xpZW50LWNlcnRpZmljYXRlLWRhdGE6IExTMHRMUzFDUlVkSlRpQkRSVkpVU1VSUmFrTkRRV2x4WjBGM1NVSkJaMGxKV0V0dVIxTlZSR05ZWVRSM1JGRlpTa3R2V2tsb2RtTk9RVkZGVEVKUlFYZEdWRVZVVFVKRlIwRXhWVVVLUVhoTlMyRXpWbWxhV0VwMVdsaFNiR282UVdWR2R6QjVUbXBCTUUxVVZYZE5la2w2VFdwR1lVWjNNSGxPZWtFd1RWUlZkMDE2U1hwTmFrWmhUVVJaZUFwR2VrRldRbWRPVmtKQmIxUkViazQxWXpOU2JHSlVjSFJaV0U0d1dsaEtlazFTYzNkSFVWbEVWbEZSUkVWNFNtdGlNazV5V2xoSmRGcHRPWGxNVjFKc0NtTXlkREJpTTBGM1oyZEZhVTFCTUVkRFUzRkhVMGxpTTBSUlJVSkJVVlZCUVRSSlFrUjNRWGRuWjBWTFFXOUpRa0ZSUkU5M2VrRjVaMGhtUVZCWE5IWUtNR05CWlRoWWRUZGtSazlWYmtzMU1rUk9OVll2YXpGa1NHWXhRVUZ3VG5Gb1oxSlhRMVJuT0hSTlN6ZE9ZamxUZW1WWlNqaFBPU3RvZVRSUmFWRlNkQXAyYkVFMVF6QTJUVU5tYlRWUU9VdHNSMUU1VURSRGVHVkZUVVE1VTBSMWRFdHBWV2h0TWtoMWFXTnRMM28wYm1vemR6UjJkSFF6VlZKNmRVOUhjR1IzQ25WalJrUlNhMk4xSzNaaFRqVXlNazl5UmtKaU16WlpNbWxMZUVSRFYwOHlhR3BsTDFSSVVrUmpNbTUwZEZGb09GcG1TRTlNVG5CS0x6VldiME5IV25RS1JqUm1TRGhtVFdkU016Sm5WMWcyWlhKYUx6RnZNa3RoTjBsMWRqRTJPRzVYTjNOYVVXbExMM2R2THpSRU1YSk9SMHBwU3l0U05TOXplV05HV2xCQlJ3cFZSSGhIY0ZOa2FUSmtSamw2UzBKWWRFVjFXR3RLYUhGTFkweHRhM2hMVjFGU1RsYzJSRTk2YWtoeFRHczBhRlJqZUVwTVpVNVBRU3N4TlV4cFZrTTJDa3hXYzI5SmRubzVRV2ROUWtGQlIycGtWRUo2VFVFMFIwRXhWV1JFZDBWQ0wzZFJSVUYzU1VadlJFRlVRbWRPVmtoVFZVVkVSRUZMUW1kbmNrSm5SVVlLUWxGalJFRnFRVTFDWjA1V1NGSk5Ra0ZtT0VWQmFrRkJUVUk0UjBFeFZXUkpkMUZaVFVKaFFVWkZVQ3ROT1hKSE1WQXphVWt5TVZsNFJXZ3ZjbVZRY1FwdGIwbElUVUl3UjBFeFZXUkZVVkZYVFVKVFEwVnRVblpaTW5Sc1kya3xiV0l6U1hSYVIxWjZZVE5TZG1ORVFVNUNaMnR4YUd0cFJ6bDNNRUpCVVhOR0NrRkJUME5CVVVWQmJFdFFkRzVXSzFkalYwZHdhakUxVEM5eGRYZDNNbWRKZW5WRksxRlRNMmhMWTBKVmFqSTJjbmxXWVZJNVFqTnBNVzlQWm1GdE5IY0tjREZUV0VNcmJWTlNaRTFHWjFKdFVYSXJSVkpYYjBOSFJESXhhMUpLVDBKU2QycHlObFIyVVRaV2JXODVUREI1TWxKT1lUbDViRUpHV21RNU5ucFdiQXAwVURNMFVVNW1Ua1pVYzBvdlUwdzJVVXB4WkRBMVdVSTFTbTVIY3pCaWVsWTBiVUkzT1c5cE9VOTZhbWxDVDFaV2VWbHlOblZpYlhoaE5HTmlRek5zQ2l0TU5UZFFRbU5oUm1ONVQyNVFTV1oxTm1SelVtWnpVa2RhYlhGMlJ6Rm9TWGtyYmxCaU9ISmtNVzlpVERSNVpEVnhPRzU1ZFRSRlVIQlVha3BvYVZjS1ZHZ3ZaVXhrTm1NMVZIZDJZak0zUTBwSlZXUmhiVlpxU2twRVNURnJlR1p1TWt4S1lrcEhTbFJETDJ4VWRXbEVlVzl1VjB4MVUxWjBXVGRhVGtoRlV3cHFXWGg2V2xGdFF6SmhSVkZzVERnNE5rSkxTemhWU2tkaFlURXJWakJWV0hCWFNVSkVSRU5GVkRSUVZVOVRTbkZYUmsxalVYQlhXVmRLVVcwMGEwUlZlazFVVmpsUGF6QTFUWEJhVnk5R2JGWmFiVEkxUW1zclZtRllNMEJXVVhkUGIwaFRSakJSTW0xdllVTkRlazlVVFRkRFZGbERRa0p3YTBGQlkyUlVNMEJHTlRWblowVXhSazlIWjJ4RldFTjVVVEJ3YWsxWlRVTlFXVEZSU0doT1dGZHdhVGRrV0ZKNU9VdERiMEYzVTBSRVNVOUdRMEJ6ZWsxV1p6QkRWMEoxVVQwOWQw
   ```

4. Click **Add secret**

---

### 3. **DOCKER_USERNAME** (Optional - Already in Workflow)
Your Docker Hub username for authentication.

**Status:** ✅ Not needed - We use hardcoded value `ratnakar99` in the workflow

**Note:** We changed the workflow to use the hardcoded username `ratnakar99` instead of a secret to avoid the "Username required" error.

---

## Summary of Changes Made

### ✅ Fixed in Workflow (ci-cd.yml)
```yaml
# OLD (broken - "Username required" error):
with:
  username: ${{ secrets.DOCKER_USERNAME }}
  password: ${{ secrets.DOCKER_PASSWORD }}

# NEW (fixed):
with:
  username: ratnakar99  # Hardcoded username
  password: ${{ secrets.DOCKER_PASSWORD }}
```

### ✅ Added Kubernetes Deployment Steps
```yaml
deploy:
  name: Deploy to Kubernetes
  needs: build-and-push
  steps:
    - name: Set up kubectl
      run: |
        mkdir -p $HOME/.kube
        echo "${{ secrets.KUBE_CONFIG }}" | base64 -d > $HOME/.kube/config
        chmod 600 $HOME/.kube/config
    
    - name: Apply Kubernetes deployment
      run: kubectl apply -f k8s/deployment.yaml
    
    - name: Trigger rolling restart
      run: kubectl rollout restart deployment/simple-k8s-cicd
    
    - name: Wait for rollout to complete
      run: kubectl rollout status deployment/simple-k8s-cicd --timeout=5m
```

---

## Why This Fixes the Pipeline Failure

### The Problem
The "Build & Push Docker Image" job was failing with **"Username required"** error because:
1. The workflow tried to use `${{ secrets.DOCKER_USERNAME }}`
2. This secret was **never set** in the GitHub repository
3. Docker login failed with an empty username

### The Solution
1. ✅ Changed to hardcoded username `ratnakar99` (no secret needed)
2. ✅ Only requires `DOCKER_PASSWORD` secret (authentication token)
3. ✅ Added `KUBE_CONFIG` secret for Kubernetes deployment automation

---

## Next Steps

1. **Add KUBE_CONFIG Secret:**
   - Go to: https://github.com/ratnakarchakkapalli/simple-k8s-cicd/settings/secrets/actions
   - Create new secret with name `KUBE_CONFIG`
   - Paste the value from above
   - Save

2. **Verify Docker Push Works:**
   - The next push to GitHub will trigger the workflow
   - Watch the "Build & Push Docker Image" job complete successfully

3. **Verify Kubernetes Deployment:**
   - The "Deploy to Kubernetes" job will run automatically
   - Pods should update with the new image

4. **Test the Full Pipeline:**
   - Make a code change
   - Push to GitHub
   - Watch all three jobs complete:
     - ✅ Run Tests
     - ✅ Build & Push Docker Image
     - ✅ Deploy to Kubernetes

---

## Troubleshooting

### "Username required" Error
**Status:** ✅ FIXED - Changed to hardcoded username

### "KUBE_CONFIG secret is empty" Error
**Solution:** Add the secret from the instructions above

### "kubectl: command not found" Error
**This shouldn't happen** - GitHub Actions provides kubectl by default

### "Permission denied" Error
**Likely cause:** kubeconfig permissions not set correctly  
**Status:** ✅ FIXED - Workflow sets `chmod 600` on kubeconfig

---

## Security Note

Your kubeconfig contains sensitive information (certificates and tokens). Keep it safe:
- ✅ Stored in GitHub Secrets (encrypted)
- ✅ Only available to Actions in your repo
- ✅ Never logged or printed in job output
- ⚠️ Don't share it publicly

If compromised, rotate your kubeconfig via your K8s cluster.
