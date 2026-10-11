import hashlib
import json
import subprocess
import sys
from datetime import UTC, datetime
from pathlib import Path

root = Path(__file__).resolve().parents[1]
sequence = root.parents[1]
sources = {}
for folder in sequence.iterdir():
    if not folder.is_dir() or not folder.name[:2].isdigit():
        continue
    for source in sorted(folder.rglob("*")):
        relative = source.relative_to(sequence)
        if any(
            part
            in {
                "artifacts",
                ".tools",
                ".cache",
                "__pycache__",
                ".ruff_cache",
                ".mypy_cache",
                ".pytest_cache",
            }
            for part in relative.parts
        ):
            continue
        if not source.is_file() or source.is_symlink() or source.name == ".env":
            continue
        sources[str(relative)] = hashlib.sha256(source.read_bytes()).hexdigest()
result = subprocess.run(
    ["git", "rev-parse", "HEAD"], cwd=sequence, capture_output=True, text=True
)
provenance = {
    "schema_version": "1.0",
    "created_at": datetime.now(UTC).isoformat(),
    "image_id": sys.argv[1],
    "source_commit": result.stdout.strip() if result.returncode == 0 else None,
    "source_files": sources,
    "tools": {"trivy": "0.75.0", "syft": "1.54.1", "cosign": "3.1.3"},
    "builder": "local-docker-compose",
    "claims": "Self-reported local provenance; not SLSA certification or hosted CI evidence",
}
(root / "artifacts/provenance.json").write_text(json.dumps(provenance, indent=2) + "\n")
