#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# run_seed.sh — Populate local HDB Oracle database with sample seed data
# Reads connection settings from repository .env (never prints credentials).
#
# Usage:
#   ./database/seed/run_seed.sh                (load seed data)
#   ./database/seed/run_seed.sh --validate     (load seed data + run validation)
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ENV_FILE="$REPO_ROOT/.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERROR: .env file not found at $ENV_FILE. Copy .env.example to .env first." >&2
  exit 1
fi

set -a
# shellcheck disable=SC1090
source <(sed 's/\r$//' "$ENV_FILE")
set +a

if [[ -z "${FLYWAY_URL:-}" || -z "${FLYWAY_USER:-}" || -z "${FLYWAY_PASSWORD:-}" ]]; then
  echo "ERROR: FLYWAY_URL, FLYWAY_USER, and FLYWAY_PASSWORD must be set in .env" >&2
  exit 1
fi

EZCONNECT="${FLYWAY_URL#jdbc:oracle:thin:@}"

FILES=(
  "00_preflight_and_prereqs.sql"
  "01_core_lookup_reference.sql"
  "02_sites_and_authorization.sql"
  "03_external_hydromet_mappings.sql"
  "04_models_ensembles_and_cp.sql"
  "05_timeseries_real_and_model.sql"
  "06_alarms_and_monitoring.sql"
  "07_decodes_telemetry.sql"
)

if [[ "${1:-}" == "--validate" || "${1:-}" == "-v" ]]; then
  FILES+=("validate_seed_data.sql")
fi

build_payload() {
  printf 'WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK\n'
  printf 'WHENEVER OSERROR EXIT FAILURE ROLLBACK\n'
  printf 'CONNECT %s/"%s"@%s AS SYSDBA\n' "$FLYWAY_USER" "$FLYWAY_PASSWORD" "$EZCONNECT"
  printf 'SET DEFINE OFF FEEDBACK OFF VERIFY OFF ECHO OFF SERVEROUTPUT ON SIZE UNLIMITED LINESIZE 220 PAGESIZE 500\n'
  for f in "${FILES[@]}"; do
    cat "$SCRIPT_DIR/$f"
    printf '\n'
  done
  printf 'EXIT 0\n'
}

if command -v sqlplus >/dev/null 2>&1; then
  echo "Executing seed scripts via local sqlplus..."
  build_payload | sqlplus -s /nolog
else
  CONTAINER="${ORACLE_DOCKER_CONTAINER:-$(docker ps --filter 'publish=1521' --format '{{.Names}}' | head -n 1)}"
  if [[ -z "$CONTAINER" ]]; then
    echo "ERROR: Neither local sqlplus nor a running Oracle Docker container on port 1521 was found." >&2
    exit 1
  fi
  echo "Executing seed scripts via Docker container: $CONTAINER"
  build_payload | docker exec -i "$CONTAINER" sqlplus -s /nolog
fi
