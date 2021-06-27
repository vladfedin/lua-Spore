#! /usr/bin/env bash

set -euox pipefail

BASE_TAG="0.3.3"
TAG="$(git describe --tags --exclude "${BASE_TAG}.*.*" | sed 's/-/./g')"
git tag "${TAG}"
git push origin "${TAG}"
