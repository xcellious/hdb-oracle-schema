#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# run_validate.sh — Validate seeded HDB Oracle database integrity & joins
# Reads connection settings from repository .env (never prints credentials).
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ENV_FILE="$REPO_ROOT/.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERROR: .env file not found at $ENV_FILE." >&2
  exit 1
fi

set -a
# shellcheck disable=SC1090
source <(sed 's/\r$//' "$ENV_FILE")
set +a

EZCONNECT="${FLYWAY_URL#jdbc:oracle:thin:@}"

build_payload() {
  printf 'WHENEVER SQLERROR EXIT SQL.SQLCODE\n'
  printf 'CONNECT %s/"%s"@%s AS SYSDBA\n' "$FLYWAY_USER" "$FLYWAY_PASSWORD" "$EZCONNECT"
  cat "$SCRIPT_DIR/validate_seed_data.sql"
  printf '\n'
}

if command -v sqlplus >/dev/null 2>&1; then
  build_payload | sqlplus -s /nolog
else
  CONTAINER="${ORACLE_DOCKER_CONTAINER:-$(docker ps --filter 'publish=1521' --format '{{.Names}}' | head -n 1)}"
  if [[ -z "$CONTAINER" ]]; then
    echo "ERROR: Neither local sqlplus nor a running Oracle Docker container on port 1521 was found." >&2
    exit 1
  fi
  build_payload | docker exec -i "$CONTAINER" sqlplus -s /nolog
fi
