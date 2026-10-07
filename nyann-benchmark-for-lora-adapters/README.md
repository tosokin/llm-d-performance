# nyann-bench Multi-LoRA Testing

Benchmark setup to simulate concurrent traffic to multiple LoRA adapters using nyann-bench.

## Goal

Test EPP routing with 1000 different LoRA adapters receiving traffic simultaneously.

## Approach

Run multiple nyann-bench processes in a single container, each targeting a different adapter name. This creates concurrent multi-adapter traffic from one pod.

## Quick Start

```bash
# Deploy namespace and mock server
oc apply -f manifests/namespace.yaml

# Option A: Single-replica mock server (for small tests, up to ~50 workers)
oc apply -f manifests/mock-server.yaml

# Option B: Scaled mock server with 4 replicas (for 200+ workers)
# Prevents the mock server from becoming a bottleneck under high concurrency
oc apply -f manifests/mock-server-scaled.yaml

# Run 10 workers (for testing)
oc apply -f manifests/nyann-vertical-10-workers.yaml
oc -n nyann-bench logs -f job/nyann-vertical
```

## Manifests

| File | Description |
|------|-------------|
| `nyann-vertical-10-workers.yaml` | 10 workers in single pod (for testing) |
| `nyann-vertical-1000-workers.yaml` | 1000 workers (requires increased podPidsLimit) |
| `nyann-hybrid-4x250-workers.yaml` | 4 pods x 250 workers = 1000 total |
| `mock-server.yaml` | Mock OpenAI-compatible server |
| `mock-server-scaled.yaml` | Mock server with 4 replicas |

## Known Limitations

### podPidsLimit (4096 default)

Each nyann-bench process (Go runtime) spawns ~11 OS threads. With the default `podPidsLimit: 4096`, max ~350 workers per pod.

**Discovery**: Running `nyann-vertical-1000-workers.yaml` failed at ~270 workers:
```
PIDs current: 2853 / max: max  (at 100 workers)
PIDs current: 3918 / max: max  (at 200 workers)
can't fork: Resource temporarily unavailable  (at ~270 workers)
```

**Workaround**: Use `nyann-hybrid-4x250-workers.yaml` - distributes 1000 workers across 4 pods (250 each, ~2750 PIDs per pod).

## Custom Image

The official nyann-bench image is scratch-based (no shell). See `image/` for a busybox-based image that supports shell scripts.
