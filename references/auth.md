# Reddit Data API Auth

## Source priority

1. Reddit Data API Wiki (current onboarding + policy pointers, updated 2025-11-11)
2. Reddit Developer Terms + Data API Terms + Responsible Builder Policy
3. Reddit `/dev/api` docs for endpoint behavior
4. Legacy-only context: `reddit-archive` OAuth wiki for endpoint-level OAuth mechanics

Use #4 only when needed for token flow mechanics and explicitly label it as legacy context.

## Required auth posture

- Use OAuth for authenticated Data API access. Unidentified traffic may be throttled or blocked.
- Send a unique descriptive `User-Agent` in this exact format:
  `<platform>:<app id>:<version> (by /u/<reddit username>)`
- For bearer-token API requests, use `https://oauth.reddit.com`.

## OAuth setup checklist

- Create/select a Reddit app and capture:
  - `CLIENT_ID`
  - `CLIENT_SECRET` (confidential clients)
  - `REDIRECT_URI` (authorization code flow)
- Define scopes per endpoint needs (inspect `/dev/api/oauth`).
- Store secrets in environment variables or secret manager, never in repo.

## Token acquisition paths

Note: Endpoint examples below are based on Reddit OAuth mechanics documented in legacy wiki pages linked from the current Data API Wiki.

### A) Authorization code (user context)

1. Direct user to authorize:

```bash
https://www.reddit.com/api/v1/authorize?client_id=$CLIENT_ID&response_type=code&state=$STATE&redirect_uri=$REDIRECT_URI&duration=permanent&scope=identity,read
```

2. Exchange auth code for token:

```bash
curl -sS -u "$CLIENT_ID:$CLIENT_SECRET" \
  -A "$USER_AGENT" \
  -d "grant_type=authorization_code" \
  -d "code=$CODE" \
  -d "redirect_uri=$REDIRECT_URI" \
  https://www.reddit.com/api/v1/access_token
```

3. Persist `refresh_token` securely if returned.

### B) Refresh token

```bash
curl -sS -u "$CLIENT_ID:$CLIENT_SECRET" \
  -A "$USER_AGENT" \
  -d "grant_type=refresh_token" \
  -d "refresh_token=$REFRESH_TOKEN" \
  https://www.reddit.com/api/v1/access_token
```

### C) Client credentials (app-only)

```bash
curl -sS -u "$CLIENT_ID:$CLIENT_SECRET" \
  -A "$USER_AGENT" \
  -d "grant_type=client_credentials" \
  https://www.reddit.com/api/v1/access_token
```

## Authenticated request template

```bash
curl -sS \
  -A "$USER_AGENT" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  "https://oauth.reddit.com/api/v1/me"
```

## Failure handling

- `401 Unauthorized`
  - Likely expired/invalid token.
  - Refresh once (`grant_type=refresh_token`) and retry once.
  - If still 401, fail fast and require re-authorization.
- `403 Forbidden`
  - Do not blind-retry.
  - Verify required scopes, endpoint permissions, and policy eligibility.
- `429 Too Many Requests`
  - Follow rate-limit strategy in `references/rate-limits-and-compliance.md`.

## Script shortcut

Use `scripts/fetch_token.sh`:

```bash
CLIENT_ID=... CLIENT_SECRET=... USER_AGENT='web:myapp:1.0.0 (by /u/me)' \
  scripts/fetch_token.sh --grant client_credentials
```
