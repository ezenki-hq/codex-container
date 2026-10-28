
#!/bin/bash
set -euo pipefail

TAG=${TAG:-latest}
COMMIT=${COMMIT:-$(git rev-parse --short HEAD)}
DATE=${DATE:-$(date -u +%Y-%m-%dT%H:%M:%SZ)}
PLATFORMS=${PLATFORMS:-linux/amd64,linux/arm64}

IMAGE=ezenki/codex-container

TAGS=(--tag "${IMAGE}:${TAG}")

if [[ "$TAG" != "latest" ]]; then
  TAGS+=(--tag "${IMAGE}:latest")
fi

docker buildx build \
  --platform "$PLATFORMS" \
  --file Dockerfile \
  "${TAGS[@]}" \
  --build-arg "VERSION=${TAG}" \
  --build-arg "COMMIT=${COMMIT}" \
  --build-arg "DATE=${DATE}" \
  --push .
