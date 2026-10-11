# Secure Supply Chain and CI

Supply-chain workshop only: build orchestration, scanning, SBOM, signing, verification and provenance. Compose project `zero-trust-supply-chain-security`; no business implementation is duplicated. The full local release gate passes with no vulnerability exceptions. Hosted CI and keyless publication remain unexecuted.

## Run

From the sequence root:

```bash
bash 09-supply-chain-and-ci/code/scripts/build_dependencies.sh
bash 09-supply-chain-and-ci/code/scripts/install_tools.sh
bash 09-supply-chain-and-ci/code/scripts/run.sh
```

Supported hosts: macOS ARM64 or Linux AMD64, Docker/Compose, host Python 3.12+, curl, tar and shasum. Application files inherit earlier overlays; native dependencies are reinstalled from exact runtime constraints on the digest-pinned Python 3.12.15/Alpine 3.24.2 release base. Test overlays retain Python 3.12.11. Native imports and actual deployed identity/MCP/API/telemetry calls pass on Alpine. This is repeatable source builds, not bit-for-bit identity across platforms or timestamps.

## Executed Evidence

Checksum-verified Trivy 0.75.0, Syft 1.54.1 and Cosign 3.1.3 installed locally. Three release-integrity/exception tests, formatting, lint and strict parser types pass. Actual Cosign signing verifies original input and rejects modified/unsigned input. Syft cataloged 92 release packages. Image scanning reports zero high/critical findings, six medium and one low. Both owned dependency lockfiles and the release Dockerfile/baseline/capstone configuration report zero high/critical findings. Scan/sign/separate verification passes. Earlier Debian findings were remediated by the minimal Alpine release, not waived. Keycloak's read-only-root/non-root hardening passed real identity/MCP/mesh checks after rollout.

Ignored `artifacts/` includes `image.tar`, `sbom.spdx.json`, three scan reports, `provenance.json`, `release.json`, `release.bundle.json`, and synthetic signature-test bundles. The signed manifest binds artifact SHA-256 hashes and Docker's reported immutable image identifier. Archive SHA-256 is the distributable artifact identity, not a claimed registry digest. Provenance records source hashes, optional actual commit, builder and versions; it is self-reported, not SLSA-certified. No Git repository/commit was created. An actual Docker build-context probe confirmed exclusion of private `.tools`, `.cache` and `.env` material.

## Threshold and Trust

All HIGH/CRITICAL vulnerability and failed configuration findings block release, including unfixed findings. No blanket ignore file is used. Exceptions require exact target/finding ID, reason, owner, independent reviewer and expiry; expired or incomplete entries fail. `security/exceptions.json` is empty. A security owner must review a proposed exception in a pull request; this automation does not approve risk for them. Scan databases evolve and findings must be reevaluated each release. A scan is evidence, not a guarantee of safety.

Local signing uses an ignored, mode-restricted disposable Cosign test key with an empty passphrase; it is not a production signing identity. No signing secret is printed. Public-log upload is disabled explicitly for local tests, and verification documents the resulting lack of transparency/audit proof. Release verification requires an independently trusted public key, never a key accepted from the artifact bundle:

```bash
cd 09-supply-chain-and-ci/code
bash scripts/verify.sh "$PWD/artifacts" "$PWD/.tools/local-signing.pub"
```

Verification passes for the current local release. `signing_check.sh` proves real signature failure paths separately. CI grants read-only permissions to pull-request gates; only a successful main-branch release job receives OIDC permission for keyless signing, with exact workflow identity/issuer verification in a separate step. Hosted CI/keyless publication are configured, not executed. If nested in a repository, install the workflow in that repository's root `.github/workflows/`; it supports sequence-root and current nested checkout paths. Required-check branch protection is a repository-owner action.

Evidence publication retains JSON reports for 14 days and excludes private keys and the image archive. Release consumers need the archive from an approved artifact store. The deployment-readiness workshop verifies the local signature, bound hashes, image identity and severity gate before deployment.