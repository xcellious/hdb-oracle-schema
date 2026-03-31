#!/bin/bash
set -a # automatically export all variables
if [ -f .env ]; then
  echo "Loading variables from .env..."
  source .env
else
  echo "WARNING: .env file not found. Please copy .env.example to .env and configure it."
fi
set +a

# Run flyway passing through all arguments
flyway_tool/flyway-9.22.3/flyway -configFiles="flyway_migration/conf/flyway.conf" "$@"
