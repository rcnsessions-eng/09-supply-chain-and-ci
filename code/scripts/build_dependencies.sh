#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../../.."
python3 05-identity-delegation/code/scripts/setup_env.py
env_file="$PWD/05-identity-delegation/code/.env"
for project in 01-foundation-learning-api 02-opa-authorization 03-resource-tenant-isolation; do
  docker compose --env-file "$env_file" -f "$project/code/docker-compose.yml" build api checks
done
docker compose --env-file "$env_file" -f 04-mcp-constrained-tools/code/docker-compose.yml build mcp checks
docker compose --env-file "$env_file" -f 05-identity-delegation/code/docker-compose.yml build gateway checks
docker compose -f 07-adversarial-security-tests/code/docker-compose.yml build checks
docker compose --env-file "$env_file" -f 08-observability-audit/code/docker-compose.yml build gateway checks
docker compose -f 07-adversarial-security-tests/code/docker-compose.yml run --rm checks
bash 08-observability-audit/code/scripts/check.sh