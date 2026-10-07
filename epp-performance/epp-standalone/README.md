# EPP Performance Investigation

Reproducible environment for investigating high CPU usage in the llm-d Endpoint Picker (EPP).

## Prerequisites

- OpenShift cluster with `oc` CLI connected
- Helm 3 (`curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash`)
- MLflow credentials secret (for results logging)

## Deploy the Test Environment

### 1. Install GAIE CRDs

```bash
oc apply -f https://github.com/kubernetes-sigs/gateway-api-inference-extension/releases/latest/download/v1-manifests.yaml
```

### 2. Create namespace

```bash
export NAMESPACE="llm-d-perf-investigation"
export GUIDE_NAME="optimized-baseline"
oc create namespace ${NAMESPACE}
```

### 3. Deploy the standalone router (EPP + Envoy)

```bash
helm install ${GUIDE_NAME} \
  oci://ghcr.io/llm-d/charts/llm-d-router-standalone \
  -f <path-to-llm-d-repo>/guides/recipes/router/base.values.yaml \
  -f <path-to-llm-d-repo>/guides/optimized-baseline/router/optimized-baseline.values.yaml \
  -n ${NAMESPACE} \
  --version v0
```

### 4. Deploy the inference simulator

```bash
oc apply -n ${NAMESPACE} -f inference-sim.yaml
```

### 5. Verify

```bash
oc get pods -n ${NAMESPACE}
# Expected: 4 sim pods (1/1) + 1 EPP pod (2/2)
```

Test a request through EPP:

```bash
oc run curl-test --rm -i --restart=Never --image=curlimages/curl --namespace="${NAMESPACE}" \
  --overrides='{"spec":{"securityContext":{"runAsNonRoot":true,"seccompProfile":{"type":"RuntimeDefault"}},"containers":[{"name":"curl-test","image":"curlimages/curl","command":["curl","-sS","-X","POST","http://optimized-baseline-epp/v1/completions","-H","Content-Type: application/json","-d","{\"model\":\"Qwen/Qwen3-32B\",\"prompt\":\"Hello\"}"],"securityContext":{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]}}}]}}'
```

## Run the Benchmark

### Using GuideLLM Job Manifest

The `guidellm-test-job.yaml` manifest runs a stress test with constant rate profile.

**What it does:**
- Tests rates: 5, 10, 20, 30, 40, 50, 60 QPS
- Each rate runs for 120 seconds (max_duration)
- Prompt tokens: 256, Output tokens: 4096

### 1. Deploy the GuideLLM Job

```bash
oc apply -n ${NAMESPACE} -f manifests/guidellm-test-job.yaml
```

### 2. Monitor the Benchmark

Watch the job logs in real-time:

```bash
POD_NAME=$(kubectl get pods -n ${NAMESPACE} -l app.kubernetes.io/name=guidellm --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}')
kubectl logs -f ${POD_NAME} -n ${NAMESPACE}
```

Or check job status:

```bash
oc get job guidellm-stress -n ${NAMESPACE}
oc get pods -n ${NAMESPACE} -l app.kubernetes.io/name=guidellm
```

### 3. Collect Results

Once the job completes, copy the results from the PVC:

```bash
# Get the pod name (even if completed)
POD_NAME=$(oc get pods -n ${NAMESPACE} -l app.kubernetes.io/name=guidellm -o jsonpath='{.items[0].metadata.name}')

# Copy results locally
oc cp ${NAMESPACE}/${POD_NAME}:/results ./results/

# View the JSON results
cat results/benchmarks.json | jq .
```

### 4. Check EPP CPU Usage

Monitor EPP CPU during the test:

```bash
oc top pod -n ${NAMESPACE} -l app.kubernetes.io/name=optimized-baseline-epp
```

Or check in OpenShift Console → Workloads → Pods → optimized-baseline-epp → Metrics

### 5. Cleanup

```bash
oc delete job guidellm-stress -n ${NAMESPACE}
oc delete pvc guidellm-results -n ${NAMESPACE}
```
