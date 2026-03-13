#!/usr/bin/env bash
set -euo pipefail
: "${SUPABASE_URL:?}"
: "${SUPABASE_ANON_KEY:?}"
: "${PROJECT_REF:?}"
A_EMAIL="${A_EMAIL:-a@example.com}"
A_PASS="${A_PASS:-PassA123!}"
B_EMAIL="${B_EMAIL:-b@example.com}"
B_PASS="${B_PASS:-PassB123!}"
echo "Login A..."
A_JSON="$(./scripts/lab-login.sh "$A_EMAIL" "$A_PASS")"
A_JWT="$(echo "$A_JSON" | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')"
echo "A JWT len: ${#A_JWT}"
echo "Login B..."
B_JSON="$(./scripts/lab-login.sh "$B_EMAIL" "$B_PASS")"
B_JWT="$(echo "$B_JSON" | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')"
echo "B JWT len: ${#B_JWT}"
URL="https://${PROJECT_REF}.functions.supabase.co/leaky_list_family_photos"
echo
echo "Call as A (should LEAK both families):"
curl -sS "$URL" \
  -H "Authorization: Bearer $A_JWT" \
  -H "Content-Type: application/json" | head -c 800; echo
echo
echo "Call as B (should LEAK both families):"
curl -sS "$URL" \
  -H "Authorization: Bearer $B_JWT" \
  -H "Content-Type: application/json" | head -c 800; echo