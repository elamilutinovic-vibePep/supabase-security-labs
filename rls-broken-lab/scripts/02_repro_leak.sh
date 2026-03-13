#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
load_env

EMAIL_A="ela.a@example.com"
PASS="Passw0rd!123"

mkdir -p tmp
login "$EMAIL_A" "$PASS" tmp/a.json
JWT_A="$(extract_access_token tmp/a.json)"

echo "Calling LEAKY edge function (should leak posts)..."
curl -sS -X GET "$FUNCTIONS_URL/posts_list_leaky" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Authorization: Bearer $JWT_A" \
  -H "Content-Type: application/json"
echo