#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
bash -n scripts/*.sh
docker compose config --quiet
docker compose build checks
docker compose run --rm checks
docker compose run --rm -v "$PWD:/supply:ro" checks sh -c 'ruff check --config /supply/pyproject.toml /supply/scripts /supply/tests && ruff format --check --config /supply/pyproject.toml /supply/scripts /supply/tests && mypy --config-file /supply/pyproject.toml /supply/scripts/release.py'