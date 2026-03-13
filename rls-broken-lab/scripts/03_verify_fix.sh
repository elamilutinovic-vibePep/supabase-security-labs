#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
load_env

PASS="Passw0rd!123"

mkdir -p tmp
login "ela.a@example.com" "$PASS" tmp/a.json
login "ela.b@example.com" "$PASS" tmp/b.json

JWT_A="$(extract_access_token tmp/a.json)"
JWT_B="$(extract_access_token tmp/b.json)"

echo "Calling FIXED edge as A (should see only family posts allowed by RLS)..."
curl -sS -X GET "$SUPABASE_URL/functions/v1/posts_list_fixed" \
  -H "Authorization: Bearer $JWT_A" \
  -H "Content-Type: application/json"
echo -e "\n"

echo "Calling FIXED edge as B (should also be isolated correctly)..."
curl -sS -X GET "$SUPABASE_URL/functions/v1/posts_list_fixed" \
  -H "Authorization: Bearer $JWT_B" \
  -H "Content-Type: application/json"
echo