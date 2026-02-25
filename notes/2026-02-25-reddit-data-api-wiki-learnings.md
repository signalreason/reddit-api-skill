# Reddit Data API Wiki learnings (2026-02-25)

- The official Reddit Data API Wiki was updated on 2025-11-11 and should be treated as the current onboarding summary.
- Reddit flags old API docs/support pages as potentially outdated and points developers to Developer Terms and Data API Terms for current requirements.
- OAuth is required for authenticated API usage; un-authed traffic can be rate-limited or blocked.
- User-Agent must be unique and descriptive: `<platform>:<app ID>:<version> (by /u/<username>)`.
- Free usage baseline is 100 queries/minute per OAuth client id, averaged over a 10-minute window.
- Rate-limit headers to monitor are `X-Ratelimit-Used`, `X-Ratelimit-Remaining`, and `X-Ratelimit-Reset`.
- Data retention obligations include quickly removing deleted content and deleted-user identifying data; 48-hour purge is strongly recommended by Reddit.

## Additional primary-source learnings (2026-02-25)

- The Reddit Data API Terms (effective 2025-09-10) prohibit selling/licensing/redistributing Reddit data access and prohibit AI model training on Reddit data without a written agreement.
- The Data API Terms require deletion handling: remove deleted user content and deleted-user identifying personal data from downstream systems, with a 48-hour routine purge strongly recommended.
- Developer Terms (effective 2024-09-24) explicitly reserve Reddit's right to set and enforce rate and usage limits and prohibit abuse/circumvention of API restrictions.
- Responsible Builder Policy states free Data API access is non-commercial and policy violations can result in revoked access.
