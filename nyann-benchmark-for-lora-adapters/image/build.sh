#!/bin/bash
# Build and push nyann-bench-shell image
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# CONFIGURE THESE:
# =============================================================================
REGISTRY="${REGISTRY:-quay.io/rh-ee-tosokin}"
IMAGE_NAME="nyann-bench-shell"
TAG="${TAG:-latest}"
# =============================================================================

FULL_IMAGE="${REGISTRY}/${IMAGE_NAME}:${TAG}"

echo "=== Building nyann-bench-shell image ==="
echo "Image: ${FULL_IMAGE}"
echo ""

cd "$SCRIPT_DIR"

# Build
echo "Step 1: Building image..."
podman build -t "${IMAGE_NAME}:${TAG}" -f Dockerfile .

# Tag for registry
echo ""
echo "Step 2: Tagging for registry..."
podman tag "${IMAGE_NAME}:${TAG}" "${FULL_IMAGE}"

# Test locally
echo ""
echo "Step 3: Testing image locally..."
echo "  - Checking shell..."
podman run --rm "${IMAGE_NAME}:${TAG}" -c "echo 'Shell works!'"
echo "  - Checking nyann-bench..."
podman run --rm "${IMAGE_NAME}:${TAG}" -c "nyann-bench --help | head -3"
echo "  - Checking utilities..."
podman run --rm "${IMAGE_NAME}:${TAG}" -c "seq 1 3 && echo 'seq works'"

echo ""
echo "=== Build successful ==="
echo ""
echo "Image: ${FULL_IMAGE}"
echo ""
echo "To push to registry, run:"
echo "  podman push ${FULL_IMAGE}"
echo ""
echo "Or set REGISTRY and run this script again:"
echo "  REGISTRY=quay.io/your-org ./build.sh"
