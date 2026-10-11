#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
umask 077
mkdir -p artifacts/signature-test .tools
if [[ ! -f .tools/local-signing.key ]]; then
  COSIGN_PASSWORD='' .tools/cosign generate-key-pair --output-key-prefix .tools/local-signing
fi
cp security/exceptions.json artifacts/signature-test/original.json
COSIGN_PASSWORD='' .tools/cosign sign-blob --yes --use-signing-config=false --tlog-upload=false \
  --key .tools/local-signing.key --bundle artifacts/signature-test/signature.bundle.json \
  artifacts/signature-test/original.json
.tools/cosign verify-blob --key .tools/local-signing.pub --insecure-ignore-tlog \
  --bundle artifacts/signature-test/signature.bundle.json artifacts/signature-test/original.json
cp pyproject.toml artifacts/signature-test/modified.json
if .tools/cosign verify-blob --key .tools/local-signing.pub --insecure-ignore-tlog \
  --bundle artifacts/signature-test/signature.bundle.json artifacts/signature-test/modified.json; then
  printf 'Modified artifact incorrectly verified\n' >&2; exit 1
fi
if .tools/cosign verify-blob --key .tools/local-signing.pub --insecure-ignore-tlog \
  --bundle artifacts/signature-test/missing.bundle.json artifacts/signature-test/original.json; then
  printf 'Unsigned artifact incorrectly verified\n' >&2; exit 1
fi
printf 'Actual Cosign positive, modified and unsigned checks passed\n'