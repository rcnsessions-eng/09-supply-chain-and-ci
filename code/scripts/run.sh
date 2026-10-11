#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
umask 077
mkdir -p artifacts .cache
bash scripts/check.sh
bash scripts/signing_check.sh
docker compose build release
image=zero-trust-supply-chain-security-gateway:0.1.0
image_id="$(docker image inspect "$image" --format '{{.Id}}')"
docker save "$image" -o artifacts/image.tar
.tools/syft docker-archive:artifacts/image.tar -o spdx-json=artifacts/sbom.spdx.json
.tools/trivy image --cache-dir .cache --input artifacts/image.tar --scanners vuln \
  --format json --output artifacts/image-scan.json
mkdir -p artifacts/deployment-config/mesh artifacts/deployment-config/capstone
cp -R ../../06-istio-workload-security/code/deploy/. artifacts/deployment-config/mesh/
cp Dockerfile artifacts/deployment-config/Dockerfile
if [[ -d ../../10-production-deployment-and-readiness/code/deploy ]]; then
  cp -R ../../10-production-deployment-and-readiness/code/deploy/. artifacts/deployment-config/capstone/
fi
.tools/trivy config --cache-dir .cache --format json --output artifacts/config-scan.json \
  artifacts/deployment-config
mkdir -p artifacts/dependencies/foundation artifacts/dependencies/mcp
cp ../../01-foundation-learning-api/code/requirements.lock artifacts/dependencies/foundation/requirements.txt
cp ../../04-mcp-constrained-tools/code/requirements.lock artifacts/dependencies/mcp/requirements.txt
.tools/trivy fs --cache-dir .cache --scanners vuln --format json \
  --output artifacts/dependency-scan.json artifacts/dependencies
python3 scripts/provenance.py "$image_id"
python3 scripts/release.py manifest artifacts --image-id "$image_id"
python3 scripts/release.py scan artifacts
COSIGN_PASSWORD='' .tools/cosign sign-blob --yes --use-signing-config=false --tlog-upload=false \
  --key .tools/local-signing.key --bundle artifacts/release.bundle.json artifacts/release.json
bash scripts/verify.sh "$PWD/artifacts" "$PWD/.tools/local-signing.pub"