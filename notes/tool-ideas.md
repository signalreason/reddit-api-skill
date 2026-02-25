# Tool ideas

- Add a `scripts/check_reddit_request.sh` helper that validates required OAuth and User-Agent headers and prints retry/backoff guidance from rate-limit headers.
- Add a `scripts/reddit_policy_checklist.sh` preflight that fails fast on missing OAuth/User-Agent, unset deletion policy metadata, and clearly disallowed use-case flags.
- Add a `scripts/reddit_policy_drift_watch.sh` checker that fetches policy pages, records effective/update dates, and alerts when they change.
