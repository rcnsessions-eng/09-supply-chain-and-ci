#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .tools
case "$(uname -s)-$(uname -m)" in
  Darwin-arm64)
    trivy_platform=macOS-ARM64
    syft_platform=darwin_arm64
    cosign_platform=darwin-arm64
    trivy_sha=4a77108cccf8e55c8d6823e1e759939a622277e66cd0daa3c1fc621ed69e4568
    syft_sha=b4319c3abaa87a0170ab76ee83ea2260ca34b53aecfa3ab0dd5428d2319d744f
    cosign_sha=5cf948c2f4dfe59687bdd0b8523709067383e03982cc543475c8a7dc70e92a76 ;;
  Linux-x86_64)
    trivy_platform=Linux-64bit
    syft_platform=linux_amd64
    cosign_platform=linux-amd64
    trivy_sha=c6e65abddb348e25f10549df887045629cf28cc72453cd1c63acb717316b3f3f
    syft_sha=c069905b391cc4c20a5ba65ad5c10be2a7ba074f8ea6ad203e24d14e303dad47
    cosign_sha=4629c757b7618056f8ddd7e2625ae9fdd94c0372a65049520bc7d9df9efc7f71 ;;
  *) printf 'Supported tool hosts: macOS ARM64 or Linux AMD64\n' >&2; exit 1 ;;
esac
download() {
  local url="$1" expected="$2" target="$3"
  curl --fail --silent --show-error --location --retry 2 "$url" -o "$target"
  test "$(shasum -a 256 "$target" | cut -d ' ' -f 1)" = "$expected"
}
download "https://github.com/aquasecurity/trivy/releases/download/v0.75.0/trivy_0.75.0_${trivy_platform}.tar.gz" "$trivy_sha" .tools/trivy.tar.gz
tar -xzf .tools/trivy.tar.gz -C .tools trivy
download "https://github.com/anchore/syft/releases/download/v1.54.1/syft_1.54.1_${syft_platform}.tar.gz" "$syft_sha" .tools/syft.tar.gz
tar -xzf .tools/syft.tar.gz -C .tools syft
download "https://github.com/sigstore/cosign/releases/download/v3.1.3/cosign-${cosign_platform}" "$cosign_sha" .tools/cosign
chmod 755 .tools/trivy .tools/syft .tools/cosign
rm .tools/trivy.tar.gz .tools/syft.tar.gz
.tools/trivy --version
.tools/syft version
.tools/cosign version