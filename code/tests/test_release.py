import importlib.util
from datetime import date

import pytest

spec = importlib.util.spec_from_file_location("release", "/supply-scripts/release.py")
release = importlib.util.module_from_spec(spec)
spec.loader.exec_module(release)


def test_modified_or_missing_artifact_fails(tmp_path):
    artifact = tmp_path / "image.tar"
    artifact.write_bytes(b"synthetic image")
    manifest = {"schema_version": "1.0", "files": {"image.tar": release.digest(artifact)}}
    release.verify_files(tmp_path, manifest)
    artifact.write_bytes(b"modified")
    with pytest.raises(ValueError):
        release.verify_files(tmp_path, manifest)
    artifact.unlink()
    with pytest.raises(FileNotFoundError):
        release.verify_files(tmp_path, manifest)


def test_severity_gate_and_expiring_target_bound_exception():
    report = {
        "Results": [
            {
                "Target": "image",
                "Vulnerabilities": [{"VulnerabilityID": "CVE-test", "Severity": "HIGH"}],
            }
        ]
    }
    assert release.violations(report, {"exceptions": []}, date(2026, 10, 11))
    entry = {
        "id": "CVE-test",
        "target": "image",
        "owner": "security-team",
        "reviewer": "release-owner",
        "reason": "synthetic test only",
        "expires": "2026-10-12",
    }
    assert not release.violations(report, {"exceptions": [entry]}, date(2026, 10, 11))
    with pytest.raises(ValueError):
        release.violations(report, {"exceptions": [entry]}, date(2026, 10, 13))
    entry["target"] = "other-image"
    assert release.violations(report, {"exceptions": [entry]}, date(2026, 10, 11))
    report["Results"][0]["Vulnerabilities"][0]["Status"] = "affected"
    assert release.violations(report, {"exceptions": []}, date(2026, 10, 11))


def test_manifest_cannot_reference_outside_artifacts(tmp_path):
    with pytest.raises(ValueError):
        release.verify_files(
            tmp_path, {"schema_version": "1.0", "files": {"../secret": "sha256:fake"}}
        )
