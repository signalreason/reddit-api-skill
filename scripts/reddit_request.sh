#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  reddit_request.sh --path /api/v1/me [--method GET] [--query k=v] [--data k=v] [--max-retries N]

Required env vars:
  ACCESS_TOKEN
  USER_AGENT

Optional env vars for automatic refresh on 401:
  CLIENT_ID
  CLIENT_SECRET
  REFRESH_TOKEN

Notes:
  - Sends requests to https://oauth.reddit.com by default.
  - Retries bounded for 429 and 5xx.
  - Refreshes token once on first 401 if refresh credentials are available.
USAGE
}

METHOD="GET"
REQUEST_PATH=""
MAX_RETRIES="3"
BASE_URL="${BASE_URL:-https://oauth.reddit.com}"
declare -a QUERY_ARGS
declare -a DATA_ARGS

while [[ $# -gt 0 ]]; do
  case "$1" in
    --method)
      METHOD="${2:-}"
      shift 2
      ;;
    --path)
      REQUEST_PATH="${2:-}"
      shift 2
      ;;
    --query)
      QUERY_ARGS+=("${2:-}")
      shift 2
      ;;
    --data)
      DATA_ARGS+=("${2:-}")
      shift 2
      ;;
    --max-retries)
      MAX_RETRIES="${2:-}"
      shift 2
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

if [[ -z "$REQUEST_PATH" ]]; then
  echo "Missing required argument: --path" >&2
  usage
  exit 2
fi

require_env() {
  local key="$1"
  if [[ -z "${!key:-}" ]]; then
    echo "Missing required env var: $key" >&2
    exit 2
  fi
}

require_env ACCESS_TOKEN
require_env USER_AGENT

if ! [[ "$MAX_RETRIES" =~ ^[0-9]+$ ]]; then
  echo "--max-retries must be a non-negative integer" >&2
  exit 2
fi

build_url() {
  local url="${BASE_URL}${REQUEST_PATH}"
  local sep='?'
  local q
  for q in "${QUERY_ARGS[@]}"; do
    url+="${sep}${q}"
    sep='&'
  done
  printf '%s' "$url"
}

header_value() {
  local file="$1"
  local key="$2"
  awk -v k="$key" 'tolower($1)==tolower(k)":" {print $2}' "$file" | tr -d '\r' | tail -n1
}

sleep_seconds() {
  local attempt="$1"
  local retry_after="$2"
  local reset="$3"

  if [[ -n "$retry_after" && "$retry_after" =~ ^[0-9]+$ ]]; then
    printf '%s' "$retry_after"
    return
  fi

  if [[ -n "$reset" && "$reset" =~ ^[0-9]+$ ]]; then
    printf '%s' "$reset"
    return
  fi

  local base=$((2 ** attempt))
  local jitter=$((RANDOM % 3))
  local total=$((base + jitter))
  if (( total > 60 )); then
    total=60
  fi
  printf '%s' "$total"
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
refreshed=0
attempt=0

while (( attempt <= MAX_RETRIES )); do
  attempt=$((attempt + 1))
  url="$(build_url)"

  headers_file="$(mktemp)"
  body_file="$(mktemp)"

  curl_args=(
    -sS
    -D "$headers_file"
    -o "$body_file"
    -w "%{http_code}"
    -X "$METHOD"
    -A "$USER_AGENT"
    -H "Authorization: Bearer $ACCESS_TOKEN"
  )

  if [[ ${#DATA_ARGS[@]} -gt 0 ]]; then
    curl_args+=( -H "Content-Type: application/x-www-form-urlencoded" )
    for item in "${DATA_ARGS[@]}"; do
      curl_args+=( --data-urlencode "$item" )
    done
  fi

  http_status="$(curl "${curl_args[@]}" "$url")"

  ratelimit_used="$(header_value "$headers_file" "X-Ratelimit-Used")"
  ratelimit_remaining="$(header_value "$headers_file" "X-Ratelimit-Remaining")"
  ratelimit_reset="$(header_value "$headers_file" "X-Ratelimit-Reset")"
  retry_after="$(header_value "$headers_file" "Retry-After")"

  echo "status=${http_status} used=${ratelimit_used:-na} remaining=${ratelimit_remaining:-na} reset=${ratelimit_reset:-na}" >&2

  if [[ "$http_status" =~ ^2[0-9][0-9]$ ]]; then
    cat "$body_file"
    rm -f "$headers_file" "$body_file"
    exit 0
  fi

  if [[ "$http_status" == "401" ]]; then
    if (( refreshed == 0 )) && [[ -n "${CLIENT_ID:-}" && -n "${CLIENT_SECRET:-}" && -n "${REFRESH_TOKEN:-}" ]]; then
      echo "401 received; attempting one token refresh" >&2
      new_token="$(CLIENT_ID="$CLIENT_ID" CLIENT_SECRET="$CLIENT_SECRET" REFRESH_TOKEN="$REFRESH_TOKEN" USER_AGENT="$USER_AGENT" "$SCRIPT_DIR/fetch_token.sh" --grant refresh_token --token-only)"
      if [[ -n "$new_token" ]]; then
        ACCESS_TOKEN="$new_token"
        refreshed=1
        rm -f "$headers_file" "$body_file"
        continue
      fi
    fi
    echo "401 unauthorized after refresh handling" >&2
    cat "$body_file" >&2
    rm -f "$headers_file" "$body_file"
    exit 1
  fi

  if [[ "$http_status" == "403" ]]; then
    echo "403 forbidden; check scopes, endpoint access, and policy eligibility" >&2
    cat "$body_file" >&2
    rm -f "$headers_file" "$body_file"
    exit 1
  fi

  if [[ "$http_status" == "429" ]]; then
    if (( attempt > MAX_RETRIES )); then
      echo "429 rate limited and retry budget exhausted" >&2
      cat "$body_file" >&2
      rm -f "$headers_file" "$body_file"
      exit 1
    fi
    wait_for="$(sleep_seconds "$attempt" "$retry_after" "$ratelimit_reset")"
    echo "429 rate limited; sleeping ${wait_for}s before retry" >&2
    rm -f "$headers_file" "$body_file"
    sleep "$wait_for"
    continue
  fi

  if [[ "$http_status" =~ ^5[0-9][0-9]$ ]]; then
    if (( attempt > MAX_RETRIES )); then
      echo "Server error ${http_status}; retry budget exhausted" >&2
      cat "$body_file" >&2
      rm -f "$headers_file" "$body_file"
      exit 1
    fi
    wait_for="$(sleep_seconds "$attempt" "" "")"
    echo "Server error ${http_status}; sleeping ${wait_for}s before retry" >&2
    rm -f "$headers_file" "$body_file"
    sleep "$wait_for"
    continue
  fi

  echo "Request failed with HTTP ${http_status}" >&2
  cat "$body_file" >&2
  rm -f "$headers_file" "$body_file"
  exit 1
done

echo "Retry loop ended unexpectedly" >&2
exit 1
