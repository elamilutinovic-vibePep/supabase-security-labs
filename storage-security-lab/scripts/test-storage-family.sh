#!/usr/bin/env bash
set -euo pipefail
: "${SUPABASE_URL:?set SUPABASE_URL}"
: "${SUPABASE_ANON_KEY:?set SUPABASE_ANON_KEY}"
FAMILY_A="11111111-1111-1111-1111-111111111111"
FAMILY_B="22222222-2222-2222-2222-222222222222"
BUCKET="family-photos"
run_list () {
  local jwt="$1"
  local prefix="$2"
  curl -sS -i "$SUPABASE_URL/storage/v1/object/list/$BUCKET" \
    -H "apikey: $SUPABASE_ANON_KEY" \
    -H "Authorization: Bearer $jwt" \
    -H "Content-Type: application/json" \
    --data "{\"prefix\":\"$prefix/\",\"limit\":10}"
}

run_upload () {
  local jwt="$1"
  local object_path="$2"   # npr: "<family_uuid>/hello.txt"
  local file="$3"
  curl -sS -i -X POST "$SUPABASE_URL/storage/v1/object/$BUCKET/$object_path" \
    -H "apikey: $SUPABASE_ANON_KEY" \
    -H "Authorization: Bearer $jwt" \
    -H "Content-Type: text/plain" \
    --data-binary @"$file"
}
run_download () {
  local jwt="$1"
  local object_path="$2"
  curl -sS -i "$SUPABASE_URL/storage/v1/object/$BUCKET/$object_path" \
    -H "apikey: $SUPABASE_ANON_KEY" \
    -H "Authorization: Bearer $jwt"
}

echo "== Login as USER A =="
EMAIL="USER_A_EMAIL" PASSWORD="USER_A_PASSWORD" JWT_A=$(SUPABASE_URL="$SUPABASE_URL" SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" EMAIL="$EMAIL" PASSWORD="$PASSWORD" ./scripts/login.sh)
echo
echo "== A lists A folder (expect 200) =="
run_list "$JWT_A" "$FAMILY_A" | sed -n '1,12p'

echo
echo "== Prepare tiny files =="
echo "hello from A" > /tmp/a.txt
echo "hello from B" > /tmp/b.txt
echo
echo "== A uploads into A folder (expect 200) =="
run_upload "$JWT_A" "$FAMILY_A/a-hello.txt" "/tmp/a.txt" | sed -n '1,12p'
echo
echo "== A uploads into B folder (expect 403) =="
run_upload "$JWT_A" "$FAMILY_B/a-should-fail.txt" "/tmp/a.txt" | sed -n '1,12p'
echo
echo "== A downloads its own file (expect 200) =="
run_download "$JWT_A" "$FAMILY_A/a-hello.txt" | sed -n '1,12p'

echo
echo "== A lists B folder (expect 403) =="
run_list "$JWT_A" "$FAMILY_B" | sed -n '1,12p'
echo
echo "== Login as USER B =="
EMAIL="USER_B_EMAIL" PASSWORD="USER_B_PASSWORD" JWT_B=$(SUPABASE_URL="$SUPABASE_URL" SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" EMAIL="$EMAIL" PASSWORD="$PASSWORD" ./scripts/login.sh)
echo
echo "== B lists B folder (expect 200) =="
run_list "$JWT_B" "$FAMILY_B" | sed -n '1,12p'

echo
echo "== B uploads into B folder (expect 200) =="
run_upload "$JWT_B" "$FAMILY_B/b-hello.txt" "/tmp/b.txt" | sed -n '1,12p'
echo
echo "== B uploads into A folder (expect 403) =="
run_upload "$JWT_B" "$FAMILY_A/b-should-fail.txt" "/tmp/b.txt" | sed -n '1,12p'
echo
echo "== B downloads A file (expect 403) =="
run_download "$JWT_B" "$FAMILY_A/a-hello.txt" | sed -n '1,12p'

echo
echo "== B lists A folder (expect 403) =="
run_list "$JWT_B" "$FAMILY_A" | sed -n '1,12p'
echo
echo "Done."

run_delete () {
  local jwt="$1"
  local object_path="$2"
  curl -sS -i -X DELETE "$SUPABASE_URL/storage/v1/object/$BUCKET/$object_path" \
    -H "apikey: $SUPABASE_ANON_KEY" \
    -H "Authorization: Bearer $jwt"
}

echo
echo "== Cleanup =="
run_delete "$JWT_A" "$FAMILY_A/a-hello.txt" | sed -n '1,12p'
run_delete "$JWT_B" "$FAMILY_B/b-hello.txt" | sed -n '1,12p'


