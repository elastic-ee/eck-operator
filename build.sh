#!/bin/bash
set -e

cd remote

git add .
git reset --hard

git checkout main
git pull origin main --tags

REGISTRY=ghcr.io
REPO=elastic-ee/eck-operator
VERSION=$(git describe --tags $(git rev-list --tags --max-count=1))
OPERATOR_IMAGE=$REGISTRY/$REPO:$VERSION

# Check if the version is already built
TOKEN=$(curl -s https://ghcr.io/token\?scope\="repository:$REPO:pull" | jq -r .token)
if curl -f -s -H "Authorization: Bearer $TOKEN" https://ghcr.io/v2/$REPO/manifests/$VERSION >/dev/null; then
  echo "Image $OPERATOR_IMAGE already exists"
  exit 0
fi

git checkout "$VERSION"
git pull origin "$VERSION"
git apply ../license.patch

SHA1=$(git rev-parse --short=8 --verify HEAD)
GO_LDFLAGS="-X github.com/elastic/cloud-on-k8s/v2/pkg/about.version=$VERSION \
  -X github.com/elastic/cloud-on-k8s/v2/pkg/about.buildHash=$SHA1 \
  -X github.com/elastic/cloud-on-k8s/v2/pkg/about.buildDate=$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
  -X github.com/elastic/cloud-on-k8s/v2/pkg/about.buildSnapshot=false"

docker buildx build . \
  -f build/Dockerfile \
  --build-arg GO_LDFLAGS="$GO_LDFLAGS" \
  --build-arg GO_TAGS='' \
  --build-arg VERSION="$VERSION" \
  --push \
  -t $OPERATOR_IMAGE

git add .
git reset --hard
