#!/usr/bin/env bash

set -e

DEVICE="${1:-chrome}"
WEB_PORT="${2:-0}"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$PROJECT_ROOT/.env.local"

if [ ! -f "$ENV_FILE" ]; then
    echo "Error: Missing .env.local."
    echo "Copy .env.local.example to .env.local and add your Supabase values."
    exit 1
fi

# Read .env.local
while IFS='=' read -r key value; do
    # Skip empty lines and comments
    [[ -z "$key" || "$key" =~ ^# ]] && continue

    # Remove surrounding quotes
    value="${value%\"}"
    value="${value#\"}"
    value="${value%\'}"
    value="${value#\'}"

    export "$key=$value"
done < "$ENV_FILE"

# Check required variables
if [ -z "$SUPABASE_URL" ]; then
    echo "Error: Missing SUPABASE_URL in .env.local."
    exit 1
fi

if [ -z "$SUPABASE_PUBLISHABLE_KEY" ]; then
    echo "Error: Missing SUPABASE_PUBLISHABLE_KEY in .env.local."
    exit 1
fi

echo "Starting VidyaLedger on $DEVICE with Supabase values from .env.local..."

FLUTTER_ARGS=(
    run
    -d "$DEVICE"
    --dart-define="SUPABASE_URL=$https://memzizgycisrmhpaeeez.supabase.co"
    --dart-define="SUPABASE_PUBLISHABLE_KEY=$sb_publishable_IwkZpnv0YXdPhMK4nAdKnA_PWVZ7x87"
)

if [ "$WEB_PORT" -gt 0 ]; then
    FLUTTER_ARGS+=(--web-port "$WEB_PORT")
fi

flutter "${FLUTTER_ARGS[@]}"