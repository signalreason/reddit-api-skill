# Prompt: Implement `reddit-api-skill`

You are implementing this repository as a Codex skill for working with Reddit's Data API.

Goal:
- Create a practical, policy-aware skill that helps an agent authenticate, call Reddit Data API endpoints, handle pagination/rate limits, and avoid policy violations.

Primary source to study first:
- https://support.reddithelp.com/hc/en-us/articles/16160319875092-Reddit-Data-API-Wiki

Additional authoritative sources to use:
- https://www.reddit.com/dev/api
- https://www.redditinc.com/policies/developer-terms
- https://www.redditinc.com/policies/data-api-terms
- https://support.reddithelp.com/hc/en-us/articles/42728983564564-Responsible-Builder-Policy

Important context from the Reddit Data API Wiki (Updated November 11, 2025):
- Legacy API docs/support pages may be outdated; prioritize current Terms and policy pages.
- OAuth is required for authenticated API access; unidentified traffic can be throttled/blocked.
- Use a unique descriptive User-Agent in format:
  `<platform>:<app id>:<version> (by /u/<reddit username>)`
- Free access rate limit is 100 queries per minute per OAuth client id, averaged over a 10-minute window.
- Monitor `X-Ratelimit-Used`, `X-Ratelimit-Remaining`, and `X-Ratelimit-Reset`.
- Data deletion obligations are strict: remove deleted posts/comments and deleted-user identifying data, with 48-hour routine purge strongly recommended.

Implementation requirements:
1. Create `SKILL.md` as the primary contract for this skill.
2. Keep `SKILL.md` concise; move detailed guidance into `references/`.
3. Include clear workflows for:
   - OAuth setup and token acquisition paths
   - Making authenticated requests with required headers
   - Handling rate-limit responses and backoff
   - Pagination/listing traversal patterns
   - Compliance checks before/after data storage
4. Add high-value references under `references/` (for example: `auth.md`, `rate-limits-and-compliance.md`, `endpoint-patterns.md`).
5. If useful, add lightweight scripts under `scripts/` for repeatable tasks (token fetch/request wrapper), with safe placeholders (no real credentials).
6. Keep edits focused; avoid unrelated churn.
7. Record learnings in `notes/` and missing tool ideas in `notes/tool-ideas.md`.

Quality bar:
- Use only current, primary sources for normative rules (Terms, official Reddit Help/Reddit API docs).
- Mark archived `reddit-archive` wiki pages as legacy-only context.
- Ensure skill instructions are actionable and deterministic where failure risk is high (auth, rate limits, policy constraints).
- Include concrete request examples (`curl` or equivalent) with required headers and parameter patterns.
- Explicitly describe failure handling for 401/403/429 and token refresh/retry behavior.

Validation before finishing:
- Verify `SKILL.md` frontmatter is valid (`name`, `description`) and triggering description is specific.
- Ensure every referenced file path exists and is actually linked from `SKILL.md`.
- Run available repo checks; if no automated validators exist, perform manual validation and report exactly what was checked.

Deliverable:
- A complete, usable `reddit-api-skill` implementation in this repo, plus a short summary of design choices and validation results.
