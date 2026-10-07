# nyann-bench-shell Image

Custom container image that combines **busybox** (shell + utilities) with the **nyann-bench** binary.

## Why This Image?

The official `ghcr.io/neuralmagic/nyann-bench:latest` is a scratch image containing only the Go binary - no shell, no utilities. To run shell scripts that spawn multiple nyann-bench workers, we need a shell.

## Build

```bash
# Build locally
./build.sh

# Or with custom registry
REGISTRY=quay.io/your-org ./build.sh
```

## Push

```bash
podman push quay.io/rh-ee-tosokin/nyann-bench-shell:latest
```

## Usage

```yaml
containers:
  - name: workers
    image: quay.io/rh-ee-tosokin/nyann-bench-shell:latest
    command: ["/bin/sh"]
    args: ["/scripts/run-workers.sh"]
```

## Contents

- `/bin/sh` - BusyBox shell
- `/usr/local/bin/nyann-bench` - nyann-bench binary
- Standard BusyBox utilities (`seq`, `mkdir`, `cat`, etc.)
