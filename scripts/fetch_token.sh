#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  fetch_token.sh [--grant GRANT_TYPE] [--token-only]

Grant types:
  client_credentials (default)
  refresh_token
  authorization_code

Required env vars:
  CLIENT_ID
  USER_AGENT

Grant-specific env vars:
  client_credentials: CLIENT_SECRET
  refresh_token: CLIENT_SECRET, REFRESH_TOKEN
  authorization_code: CLIENT_SECRET, CODE, REDIRECT_URI
USAGE
}

GRANT_TYPE="client_credentials"
TOKEN_ONLY=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --grant)
      GRANT_TYPE="${2:-}"
      shift 2
      ;;
    --token-only)
      TOKEN_ONLY=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 2
      ;;
  esac
done

require_env() {
  local key="$1"
  if [[ -z "${!key:-}" ]]; then
    echo "Missing required env var: $key" >&2
    exit 2
  fi
}

require_env CLIENT_ID
require_env USER_AGENT

declare -a data
case "$GRANT_TYPE" in
  client_credentials)
    require_env CLIENT_SECRET
    data=(
      --data-urlencode "grant_type=client_credentials"
    )
    ;;
  refresh_token)
    require_env CLIENT_SECRET
    require_env REFRESH_TOKEN
    data=(
      --data-urlencode "grant_type=refresh_token"
      --data-urlencode "refresh_token=${REFRESH_TOKEN}"
    )
    ;;
  authorization_code)
    require_env CLIENT_SECRET
    require_env CODE
    require_env REDIRECT_URI
    data=(
      --data-urlencode "grant_type=authorization_code"
      --data-urlencode "code=${CODE}"
      --data-urlencode "redirect_uri=${REDIRECT_URI}"
    )
    ;;
  *)
    echo "Unsupported grant type: ${GRANT_TYPE}" >&2
    usage
    exit 2
    ;;
esac

headers_file="$(mktemp)"
body_file="$(mktemp)"
cleanup() {
  rm -f "$headers_file" "$body_file"
}
trap cleanup EXIT

http_status="$(
  curl -sS \
    -D "$headers_file" \
    -o "$body_file" \
    -w "%{http_code}" \
    -u "${CLIENT_ID}:${CLIENT_SECRET:-}" \
    -A "$USER_AGENT" \
    "${data[@]}" \
    "https://www.reddit.com/api/v1/access_token"
)"

if [[ "$http_status" != "200" ]]; then
  echo "Token request failed with HTTP ${http_status}" >&2
  cat "$body_file" >&2
  exit 1
fi

if [[ "$TOKEN_ONLY" -eq 1 ]]; then
  if command -v jq >/dev/null 2>&1; then
    jq -r '.access_token // empty' "$body_file"
  else
    sed -n 's/.*"access_token"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$body_file" | head -n1
  fi
else
  if command -v jq >/dev/null 2>&1; then
    jq '.' "$body_file"
  else
    cat "$body_file"
  fi
fi
