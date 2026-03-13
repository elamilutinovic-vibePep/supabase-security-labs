#!/usr/bin/env bash
set -euo pipefail
: "${SUPABASE_URL:?}"
: "${SUPABASE_ANON_KEY:?}"
EMAIL="$1"
PASSWORD="$2"
curl -sS -X POST "$SUPABASE_URL/auth/v1/token?grant_type=password" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  --data "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}"