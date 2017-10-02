#!/bin/bash

set -e
set -o pipefail

### ---- ###

echo "Switch back to master"
git checkout master
git reset --hard origin/master

### ---- ###

echo "Fetching latest version..."
LATEST=$(curl -sSLf 'https://latest.luzifer.io/catalog-api/vault/latest.txt?p=version')

echo "Getting SHA256SUM for Linux AMD64 version..."
SHASUM=$(curl -s https://releases.hashicorp.com/vault/${LATEST}/vault_${LATEST}_SHA256SUMS | awk '/linux_amd64/{print $1}')

echo "Testing availability of archive 'vault_${LATEST}_linux_amd64.zip'..."
curl -sSLIfo /dev/null https://releases.hashicorp.com/vault/${LATEST}/vault_${LATEST}_linux_amd64.zip

echo "Found version ${LATEST}, patching..."
sed -i "s/ENV VAULT_VERSION .*$/ENV VAULT_VERSION ${LATEST}/" Dockerfile
sed -i "s/ENV VAULT_HASH .*$/ENV VAULT_HASH ${SHASUM}/" Dockerfile

echo "Checking for changes..."
git diff --exit-code && exit 0

echo "Testing build..."
docker build .

echo "Updating repository..."
git add Dockerfile
git -c user.name='Travis Automated Update' -c user.email='travis@luzifer.io' \
  commit -m "Vault ${LATEST}"
git tag ${LATEST}

git push -q https://${GH_USER}:${GH_TOKEN}@github.com/luzifer-docker/vault.git master --tags
