#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
root="${1:-$PWD/artifacts}"
trusted_key="${2:?Supply the independently trusted public key path}"
.tools/cosign verify-blob --key "$trusted_key" --bundle "$root/release.bundle.json" \
  --insecure-ignore-tlog "$root/release.json"
python3 scripts/release.py verify "$root" --image-id "$(docker image inspect zero-trust-supply-chain-security-gateway:0.1.0 --format '{{.Id}}')"
python3 scripts/release.py scan "$root"
printf 'Verified signature, immutable image identity, bound evidence and severity gate\n'