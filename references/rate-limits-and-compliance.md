# Rate Limits And Compliance

## Normative constraints (current)

From current Reddit sources (Data API Wiki, Developer Terms, Data API Terms, Responsible Builder Policy):

- Free access baseline: `100` queries per minute per OAuth client id, averaged over a 10-minute window.
- Monitor every response for:
  - `X-Ratelimit-Used`
  - `X-Ratelimit-Remaining`
  - `X-Ratelimit-Reset`
- Reddit can throttle or block unidentified traffic.
- Free Data API access is non-commercial unless separately approved.
- Do not sell/redistribute API access or Reddit data, and do not use Reddit data for AI model training without a written agreement.
- Remove deleted content and deleted-user identifying data promptly; routine purge within 48 hours is strongly recommended.

## Pre-request compliance gate

Block execution unless all checks pass:

1. OAuth token present and not expired.
2. `User-Agent` matches required Reddit format.
3. Use case is allowed by Developer Terms, Data API Terms, and Responsible Builder Policy.
4. Requested endpoint scopes are least-privilege and documented.
5. Storage/deletion plan is defined before ingesting data.

## Runtime rate-limit strategy

Apply this strategy deterministically:

1. Parse `X-Ratelimit-*` headers on every call.
2. If `X-Ratelimit-Remaining <= 1`, sleep until `X-Ratelimit-Reset` (plus small jitter).
3. On `429`:
   - Prefer `Retry-After` header.
   - Else wait `X-Ratelimit-Reset` seconds.
   - Else exponential backoff (`2^attempt`, capped) + jitter.
4. Log request id/path, status, and header values for auditing.

## 401/403/429 failure playbook

- `401 Unauthorized`
  - Refresh token once and retry once.
  - If second attempt fails, stop and require re-auth.
- `403 Forbidden`
  - Stop retries.
  - Check scope mismatch, endpoint permissions, quarantined/private resources, and policy restrictions.
- `429 Too Many Requests`
  - Back off and retry with bounded attempts.
  - Reduce concurrency and/or polling frequency before continuing.

## Storage and deletion obligations

Before writing data:
- Minimize fields to required business purpose only.
- Avoid retaining identifying data not needed for the use case.

After writing data:
- Detect tombstones/deleted users each sync cycle.
- Delete removed posts/comments from downstream stores.
- Delete identifying data tied to deleted users.
- Run automated purge job at least every 48 hours.
- Keep deletion audit logs (`entity_id`, `reason`, `timestamp`, `job_id`).

## Disallowed pattern checklist

Reject or escalate if a design includes:
- Commercial monetization on free tier.
- Redistributing substantial Reddit content as a substitute for Reddit.
- Building advertising profiles or sensitive-trait inference from Reddit data.
- Collecting data about children.
- AI model training/fine-tuning on Reddit data without written authorization.

## Legacy-doc handling rule

If implementation details are taken from `reddit-archive` docs, tag them as `legacy-only context` in design notes and validate behavior against live API responses before production rollout.
