import argparse
import hashlib
import json
from datetime import date
from pathlib import Path
from typing import Any


def digest(path: Path) -> str:
    value = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            value.update(chunk)
    return "sha256:" + value.hexdigest()


def violations(report: dict[str, Any], exceptions: dict[str, Any], today: date) -> list[str]:
    approved: set[tuple[str, str]] = set()
    for entry in exceptions["exceptions"]:
        if not all(
            entry.get(key) for key in ("id", "target", "owner", "reason", "reviewer", "expires")
        ):
            raise ValueError("Incomplete exception")
        if date.fromisoformat(entry["expires"]) < today:
            raise ValueError("Expired exception")
        approved.add((entry["target"], entry["id"]))
    failures: list[str] = []
    for result in report.get("Results", []):
        for kind, identifier in (
            ("Vulnerabilities", "VulnerabilityID"),
            ("Misconfigurations", "ID"),
        ):
            for finding in result.get(kind) or []:
                if kind == "Misconfigurations" and finding.get("Status", "FAIL") != "FAIL":
                    continue
                if (
                    finding["Severity"] in {"HIGH", "CRITICAL"}
                    and (result["Target"], finding[identifier]) not in approved
                ):
                    failures.append(result["Target"] + ":" + finding[identifier])
    return failures


def verify_files(root: Path, manifest: dict[str, Any]) -> None:
    if manifest["schema_version"] != "1.0" or not manifest["files"]:
        raise ValueError("Invalid release manifest")
    for name, expected in manifest["files"].items():
        if Path(name).name != name or digest(root / name) != expected:
            raise ValueError("Release artifact hash mismatch")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("operation", choices=["manifest", "verify", "scan"])
    parser.add_argument("root", type=Path)
    parser.add_argument("--image-id")
    args = parser.parse_args()
    if args.operation == "manifest":
        if not args.image_id or not args.image_id.startswith("sha256:"):
            raise ValueError("Immutable image ID required")
        files = [
            "image.tar",
            "sbom.spdx.json",
            "image-scan.json",
            "config-scan.json",
            "dependency-scan.json",
            "provenance.json",
        ]
        manifest = {
            "schema_version": "1.0",
            "image_id": args.image_id,
            "files": {name: digest(args.root / name) for name in files},
        }
        (args.root / "release.json").write_text(json.dumps(manifest, indent=2) + "\n")
    elif args.operation == "verify":
        manifest = json.loads((args.root / "release.json").read_text())
        verify_files(args.root, manifest)
        if args.image_id and manifest["image_id"] != args.image_id:
            raise ValueError("Image identity mismatch")
    else:
        exceptions = json.loads(
            (Path(__file__).resolve().parents[1] / "security/exceptions.json").read_text()
        )
        failures: list[str] = []
        for name in ["image-scan.json", "config-scan.json", "dependency-scan.json"]:
            failures.extend(
                violations(json.loads((args.root / name).read_text()), exceptions, date.today())
            )
        if failures:
            raise SystemExit("Severity gate failed: " + ", ".join(failures))


if __name__ == "__main__":
    main()
