# EPP Gateway Mode on Bare-Metal OpenShift

This guide explains how to deploy `LLMInferenceService` with
[`llm-d-inference-sim`](https://github.com/llm-d/llm-d-inference-sim) as the
backend inference server in Gateway Mode on a bare-metal OpenShift cluster. The deployment was
validated with
RHOAI 3.6-EA.1.

## 1. Create the LLMInferenceService test namespace

Create the namespace where the simulator `LLMInferenceService` and GuideLLM
benchmark Job will run.

```bash
oc create namespace llm-d-perf-investigation
```

## 2. Deploy the Gateway

Deploy the Gateway:

```bash
oc apply -f manifests/openshift-ai-inference-gateway.yaml
```

Verify that the Gateway and its Service were deployed correctly:

```bash
oc get gateway openshift-ai-inference -n openshift-ingress
oc get svc openshift-ai-inference-data-science-gateway-class \
  -n openshift-ingress -o wide
```

## 3. Deploy the simulator

Deploy the simulator:

```bash
oc apply -f manifests/sim-llmisvc.yaml
```

Verify that the simulator deployment was created successfully:

```bash
oc get llmisvc sim-llm -n llm-d-perf-investigation
oc get pods -n llm-d-perf-investigation -w
```

The simulator manifest must contain:

```text
--ssl-certfile /var/run/kserve/tls/tls.crt
--ssl-keyfile  /var/run/kserve/tls/tls.key
```

## 4. Test the Gateway and EPP

Get the Gateway Service ClusterIP:

```bash
oc get svc openshift-ai-inference-data-science-gateway-class \
  -n openshift-ingress -o wide
```

Replace `<GATEWAY_CLUSTER_IP>` with the displayed ClusterIP and run:

```bash
oc run curl-gateway-test \
  -n llm-d-perf-investigation \
  --rm -i \
  --restart=Never \
  --image=curlimages/curl:8.10.1 \
  -- curl -k -N -v --http1.1 --max-time 20 \
  --resolve openshift-ai-inference-data-science-gateway-class.openshift-ingress.svc.cluster.local:443:<GATEWAY_CLUSTER_IP> \
  https://openshift-ai-inference-data-science-gateway-class.openshift-ingress.svc.cluster.local/llm-d-perf-investigation/sim-llm/v1/completions \
  -H 'Content-Type: application/json' \
  -d '{"model":"simulated-llama-3","prompt":"Return a short answer.","max_tokens":20,"stream":true}'
```

Expected response:

- HTTP `200 OK`
- `Content-Type: text/event-stream`
- streamed `data:` chunks
- final `data: [DONE]`

## 5. Run GuideLLM

The provided Job sends streaming requests through the Gateway:

```bash
oc apply -f manifests/guidellm-test-job.yaml
oc get pods -n llm-d-perf-investigation \
  -l app.kubernetes.io/name=guidellm -w
oc logs -n llm-d-perf-investigation -f job/guidellm-gateway-test
```

The Job uses GuideLLM `v0.8.1`, HTTPS streaming requests to
`/v1/completions`, synthetic 256-token prompts, 128 output tokens, rates
`5, 10, 20, 30, 40, 50`, and 120 seconds per rate. TLS verification is
disabled in the GuideLLM backend because the Gateway certificate is
cluster-generated.

The Job currently expects the `lvms-vg1` StorageClass and a node labeled
`role=loadgen`. Change those fields in `manifests/guidellm-test-job.yaml` if
the cluster uses different storage or node labels. Keep the endpoint pointed
at the Gateway; using the workload Service bypasses the Gateway and EPP.
