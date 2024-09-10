#!/bin/bash
set -e

cd remote

git add .
git reset --hard

git checkout main
git pull origin main --tags

VERSION=$(git describe --tags $(git rev-list --tags --max-count=1))

git checkout "$VERSION"
git pull origin "$VERSION"
git apply ../license.patch

SHA1=$(git rev-parse --short=8 --verify HEAD)
GO_LDFLAGS="-X github.com/elastic/cloud-on-k8s/v2/pkg/about.version=$VERSION \
  -X github.com/elastic/cloud-on-k8s/v2/pkg/about.buildHash=$SHA1 \
  -X github.com/elastic/cloud-on-k8s/v2/pkg/about.buildDate=$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
  -X github.com/elastic/cloud-on-k8s/v2/pkg/about.buildSnapshot=false"
OPERATOR_IMAGE=ghcr.io/elastic-ee/eck-operator:$VERSION

docker buildx build . \
	 	-f build/Dockerfile \
		--build-arg GO_LDFLAGS="$GO_LDFLAGS" \
		--build-arg GO_TAGS='' \
		--build-arg VERSION="$VERSION" \
		--push \
		-t $OPERATOR_IMAGE

git add .
git reset --hard
