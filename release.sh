#!/bin/bash
set -euo pipefail

# Usage: GITHUB_TOKEN=yourtoken RELEASE_VERSION=v1.0.0 ./release.sh

if [[ -z "${GITHUB_TOKEN:-}" || -z "${RELEASE_VERSION:-}" ]]; then
  echo "Usage: GITHUB_TOKEN=yourtoken RELEASE_VERSION=v1.0.0 ./release.sh"
  exit 1
fi

# Auto-detect GitHub username from git remote
GITHUB_USERNAME=$(git remote get-url origin | sed -n 's/.*github\.com[:/]\([^/]*\)\/.*/\1/p')

if [[ -z "$GITHUB_USERNAME" ]]; then
  echo "Error: Could not detect GitHub username from git remote origin"
  echo "Make sure your git remote origin is set to a GitHub repository"
  exit 1
fi

echo "Detected GitHub username: $GITHUB_USERNAME"

IMAGE_NAME=ghcr.io/$GITHUB_USERNAME/simpletuvearchiver:$RELEASE_VERSION
LATEST_IMAGE=ghcr.io/$GITHUB_USERNAME/simpletuvearchiver:latest

# Tag and push git (force override if exists)

git tag -f "$RELEASE_VERSION"
git push -f origin "$RELEASE_VERSION"

echo "$GITHUB_TOKEN" | docker login ghcr.io -u "$GITHUB_USERNAME" --password-stdin

# Create and use buildx builder for multi-architecture builds
docker buildx create --use --name multiarch-builder || docker buildx use multiarch-builder

# Build and push multi-architecture images (AMD64 and ARM64)
# Add retry logic and longer timeout for network issues
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --tag "$IMAGE_NAME" \
  --tag "$LATEST_IMAGE" \
  --push \
  --progress=plain \
  --build-arg BUILDKIT_INLINE_CACHE=1 \
  .

echo "Release $RELEASE_VERSION complete!"
