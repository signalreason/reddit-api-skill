# Reddit Data API Wiki learnings (2026-02-25)

- The official Reddit Data API Wiki was updated on 2025-11-11 and should be treated as the current onboarding summary.
- Reddit flags old API docs/support pages as potentially outdated and points developers to Developer Terms and Data API Terms for current requirements.
- OAuth is required for authenticated API usage; un-authed traffic can be rate-limited or blocked.
- User-Agent must be unique and descriptive: `<platform>:<app ID>:<version> (by /u/<username>)`.
- Free usage baseline is 100 queries/minute per OAuth client id, averaged over a 10-minute window.
- Rate-limit headers to monitor are `X-Ratelimit-Used`, `X-Ratelimit-Remaining`, and `X-Ratelimit-Reset`.
- Data retention obligations include quickly removing deleted content and deleted-user identifying data; 48-hour purge is strongly recommended by Reddit.
