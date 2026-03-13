#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
load_env

# Create two users
EMAIL_A="ela.a@example.com"
EMAIL_B="ela.b@example.com"
PASS="Passw0rd!123"

echo "Seeding users..."
signup "$EMAIL_A" "$PASS" || true
signup "$EMAIL_B" "$PASS" || true

mkdir -p tmp
login "$EMAIL_A" "$PASS" tmp/a.json
login "$EMAIL_B" "$PASS" tmp/b.json

JWT_A="$(extract_access_token tmp/a.json)"
JWT_B="$(extract_access_token tmp/b.json)"

USER_A_ID="$(get_user_id "$JWT_A")"
USER_B_ID="$(get_user_id "$JWT_B")"

echo "User A: $USER_A_ID"
echo "User B: $USER_B_ID"

# Fetch profile ids (created by trigger)
PROFILE_A_ID="$(sr_get "$SUPABASE_URL/rest/v1/profiles?select=id&user_id=eq.$USER_A_ID" | sed -n 's/.*"id":"\([^"]*\)".*/\1/p')"
PROFILE_B_ID="$(sr_get "$SUPABASE_URL/rest/v1/profiles?select=id&user_id=eq.$USER_B_ID" | sed -n 's/.*"id":"\([^"]*\)".*/\1/p')"

echo "Profile A: $PROFILE_A_ID"
echo "Profile B: $PROFILE_B_ID"

# Create family owned by A
FAM_JSON="$(sr_post "families" "{\"owner_user_id\":\"$USER_A_ID\"}")"
FAMILY_ID="$(echo "$FAM_JSON" | sed -n 's/.*"id":"\([^"]*\)".*/\1/p')"
echo "Family: $FAMILY_ID"

# Add memberships
sr_post "family_members" "{\"family_id\":\"$FAMILY_ID\",\"user_id\":\"$USER_A_ID\",\"role\":\"owner\"}" >/dev/null
sr_post "family_members" "{\"family_id\":\"$FAMILY_ID\",\"user_id\":\"$USER_B_ID\",\"role\":\"member\"}" >/dev/null

# Add posts for both
sr_post "posts" "{\"family_id\":\"$FAMILY_ID\",\"owner_profile_id\":\"$PROFILE_A_ID\",\"body\":\"Post by A\"}" >/dev/null
sr_post "posts" "{\"family_id\":\"$FAMILY_ID\",\"owner_profile_id\":\"$PROFILE_B_ID\",\"body\":\"Post by B\"}" >/dev/null

echo "✅ Seed done."
echo "Tip: JWT_A and JWT_B are in tmp/a.json and tmp/b.json"