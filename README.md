# reddit-api-skill

Codex skill for implementing and operating integrations with Reddit's Data API using OAuth, required `User-Agent` formatting, pagination patterns, and policy-aware data handling.

## What this repo contains

- `SKILL.md`: Primary skill contract and workflow.
- `references/`: Detailed guidance for auth, rate limits/compliance, and endpoint/pagination patterns.
- `scripts/`: Reusable shell helpers for token fetch/refresh and authenticated requests.
- `PROMPT.md`: Implementation prompt for building/extending the skill.
- `notes/`: Learnings and tool ideas captured during development.

## Quick start

1. Export credentials and headers:

```bash
export CLIENT_ID='...'
export CLIENT_SECRET='...'
export USER_AGENT='web:my-app:1.0.0 (by /u/your_username)'
```

2. Fetch an app token:

```bash
ACCESS_TOKEN="$(
  CLIENT_ID="$CLIENT_ID" \
  CLIENT_SECRET="$CLIENT_SECRET" \
  USER_AGENT="$USER_AGENT" \
  scripts/fetch_token.sh --grant client_credentials --token-only
)"
export ACCESS_TOKEN
```

3. Call an endpoint through the retry/rate-limit wrapper:

```bash
scripts/reddit_request.sh --path /api/v1/me
```

## Policy and source guidance

- Treat Reddit's Data API Wiki as onboarding context and always prioritize current Terms/policies for normative rules.
- Consider `reddit-archive` docs legacy-only context for OAuth mechanics when current docs are insufficient.

Authoritative sources are listed in `PROMPT.md`.
