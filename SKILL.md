---
name: reddit-api-skill
description: Implement and operate Reddit Data API integrations with OAuth authentication, required User-Agent headers, listing pagination, rate-limit aware retries, and policy-compliant data handling. Use when Codex needs to acquire or refresh Reddit tokens, call `/dev/api` endpoints, handle 401/403/429 responses, monitor `X-Ratelimit-*` headers, or enforce Reddit Developer Terms, Data API Terms, and Responsible Builder constraints.
---

# Reddit Data API Skill

Follow these steps in order for every implementation.

## 1) Load the right references

Read only what you need:
- Auth and token paths: `references/auth.md`
- Rate limits, failures, and compliance gates: `references/rate-limits-and-compliance.md`
- Endpoint and pagination patterns: `references/endpoint-patterns.md`

Treat `reddit-archive` wiki pages as legacy-only context. Use them for OAuth mechanics only when current Reddit docs do not provide equivalent detail.

## 2) Enforce non-negotiables first

- Require OAuth credentials before API calls.
- Require a unique descriptive `User-Agent` in this exact format:
  `<platform>:<app id>:<version> (by /u/<reddit username>)`
- Use `https://oauth.reddit.com` for bearer-token API calls.
- Monitor and react to `X-Ratelimit-Used`, `X-Ratelimit-Remaining`, and `X-Ratelimit-Reset`.

## 3) Run deterministic request workflow

1. Acquire token (`authorization_code`, `refresh_token`, or `client_credentials`) per `references/auth.md`.
2. Call endpoint with:
   - `Authorization: Bearer <access_token>`
   - required `User-Agent`
   - `raw_json=1` when consuming JSON text content.
3. Handle failures:
   - `401`: refresh token once, then retry once.
   - `403`: stop retries, surface scope/policy/access cause.
   - `429`: wait per `Retry-After` or `X-Ratelimit-Reset`, then back off with jitter.
4. For listings, iterate with `after` cursor until `after=null` or stop condition.

## 4) Run compliance checks before and after storage

Before storing Reddit data:
- Confirm use case is approved and within allowed purpose.
- Confirm no prohibited commercialization, AI training, privacy inference, or deceptive usage.

After storing data:
- Remove deleted posts/comments and deleted-account identifying data.
- Run routine purge jobs (48-hour cadence recommended).
- Keep deletion and retention actions auditable.

Use the checklist and deletion playbook in `references/rate-limits-and-compliance.md`.

## 5) Use scripts when reliability matters

- `scripts/fetch_token.sh`: fetch/refresh OAuth tokens.
- `scripts/reddit_request.sh`: send authenticated requests with rate-limit parsing and 401/429 retry handling.

Prefer these scripts for repeatable tasks instead of rewriting ad hoc curl logic.
