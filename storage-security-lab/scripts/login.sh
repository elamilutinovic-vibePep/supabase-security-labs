#!/usr/bin/env bash
set -euo pipefail
: "${SUPABASE_URL:?set SUPABASE_URL}"
: "${SUPABASE_ANON_KEY:?set SUPABASE_ANON_KEY}"
: "${EMAIL:?set EMAIL}"
: "${PASSWORD:?set PASSWORD}"
curl -sS "$SUPABASE_URL/auth/v1/token?grant_type=password" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  --data "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}" \
  > /tmp/login.json
JWT=$(sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p' /tmp/login.json)
if [[ -z "$JWT" ]]; then
  echo "❌ Login failed. Response:"
  cat /tmp/login.json
  exit 1
fi
echo "$JWT"