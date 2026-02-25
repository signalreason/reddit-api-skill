# Endpoint Patterns

## Host and request shape

- Token endpoint host: `https://www.reddit.com/api/v1/access_token`
- Authenticated API host: `https://oauth.reddit.com`
- Include:
  - `Authorization: Bearer <token>`
  - `User-Agent: <platform>:<app id>:<version> (by /u/<username>)`

## Listing pagination model

Reddit listing endpoints use cursor pagination and return a listing object with:
- `data.children[]`
- `data.after`
- `data.before`

Common query params:
- `limit`: max `100` (default often `25`)
- `after`: fullname cursor for next page
- `before`: fullname cursor for previous page
- `count`: number of items already seen in this traversal

`before` and `after` are mutually exclusive in one request.

## Traversal pattern (forward)

```bash
BASE='https://oauth.reddit.com/r/python/new'
AFTER=''
COUNT=0

while :; do
  URL="$BASE?limit=100&raw_json=1"
  if [ -n "$AFTER" ]; then
    URL="$URL&after=$AFTER&count=$COUNT"
  fi

  RESP=$(curl -sS -A "$USER_AGENT" -H "Authorization: Bearer $ACCESS_TOKEN" "$URL")

  # parse children and after with jq in real usage
  # AFTER=$(echo "$RESP" | jq -r '.data.after // empty')
  # PAGE_COUNT=$(echo "$RESP" | jq '.data.children | length')
  # COUNT=$((COUNT + PAGE_COUNT))

  [ -z "$AFTER" ] && break
done
```

## Endpoint examples

### Identity check

```bash
curl -sS -A "$USER_AGENT" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  "https://oauth.reddit.com/api/v1/me"
```

### Subreddit new posts (paged)

```bash
curl -sS -A "$USER_AGENT" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  "https://oauth.reddit.com/r/{subreddit}/new?limit=100&after={cursor}&raw_json=1"
```

### Batch hydrate by fullname ids

```bash
curl -sS -A "$USER_AGENT" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  "https://oauth.reddit.com/api/info?id=t3_abcd,t1_efgh&raw_json=1"
```

## Robustness rules

- Always stop when `after` is `null` or empty.
- Always cap maximum pages/items per run to avoid runaway crawls.
- Always de-duplicate by fullname (`t1_...`, `t3_...`) before storage.
- Always log pagination cursors for resumable jobs.
