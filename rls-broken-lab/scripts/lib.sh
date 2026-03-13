#!/usr/bin/env bash
set -euo pipefail

# Loads local Supabase env from CLI (works after `supabase start`)
load_env() {
  local envout
  envout="$(supabase status -o env | grep -E '^[A-Z0-9_]+=' )"

  export SUPABASE_URL
  export SUPABASE_ANON_KEY
  export SUPABASE_SERVICE_ROLE_KEY
  export FUNCTIONS_URL
  export SUPABASE_REST_URL
  export SUPABASE_FUNCTIONS_URL

  # strip surrounding quotes if present
  stripq() {
    local s="$1"
    s="${s#\"}"  # remove leading "
    s="${s%\"}"  # remove trailing "
    printf '%s' "$s"
  }

  SUPABASE_URL="$(stripq "$(echo "$envout" | sed -n 's/^API_URL=\(.*\)$/\1/p')")"
  SUPABASE_ANON_KEY="$(stripq "$(echo "$envout" | sed -n 's/^ANON_KEY=\(.*\)$/\1/p')")"
  SUPABASE_SERVICE_ROLE_KEY="$(stripq "$(echo "$envout" | sed -n 's/^SERVICE_ROLE_KEY=\(.*\)$/\1/p')")"
  FUNCTIONS_URL="$(stripq "$(echo "$envout" | sed -n 's/^FUNCTIONS_URL=\(.*\)$/\1/p')")"
  SUPABASE_REST_URL="$(stripq "$(echo "$envout" | sed -n 's/^REST_URL=\(.*\)$/\1/p')")"
  SUPABASE_FUNCTIONS_URL="$(stripq "$(echo "$envout" | sed -n 's/^FUNCTIONS_URL=\(.*\)$/\1/p')")"


  if [[ -z "${SUPABASE_URL:-}" || -z "${SUPABASE_ANON_KEY:-}" || -z "${SUPABASE_SERVICE_ROLE_KEY:-}" ]]; then
    echo "❌ Could not load env from 'supabase status -o env'. Is supabase running?"
    exit 1
  fi
}

signup() {
  local email="$1"
  local password="$2"
  curl -sS -X POST "$SUPABASE_URL/auth/v1/signup" \
    -H "apikey: $SUPABASE_ANON_KEY" \
    -H "Content-Type: application/json" \
    --data "{\"email\":\"$email\",\"password\":\"$password\"}" >/dev/null
}

login() {
  local email="$1"
  local password="$2"
  local outfile="$3"

  curl -sS -X POST "$SUPABASE_URL/auth/v1/token?grant_type=password" \
    -H "apikey: $SUPABASE_ANON_KEY" \
    -H "Content-Type: application/json" \
    --data "{\"email\":\"$email\",\"password\":\"$password\"}" > "$outfile"
}

extract_access_token() {
  local file="$1"
  sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p' "$file"
}

get_user_id() {
  local jwt="$1"
  curl -sS "$SUPABASE_URL/auth/v1/user" \
    -H "apikey: $SUPABASE_ANON_KEY" \
    -H "Authorization: Bearer $jwt" \
  | sed -n 's/.*"id":"\([^"]*\)".*/\1/p'
}

# Service role PostgREST helper
sr_post() {
  local path="$1"
  local json="$2"
  curl -sS -X POST "$SUPABASE_URL/rest/v1/$path" \
    -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
    -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
    -H "Content-Type: application/json" \
    -H "Prefer: return=representation" \
    --data "$json"
}

sr_get() {
  local url="$1"
  curl -sS "$url" \
    -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
    -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY"
}