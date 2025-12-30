# Copy Stats API

This API tracks install script copy events with session-based rate limiting.

## Deployment

### Option 1: Cloudflare Workers (Recommended)

1. **Create KV Namespace:**
   ```bash
   wrangler kv:namespace create "COPY_STATS_KV"
   ```

2. **Add to `wrangler.toml`:**
   ```toml
   [[kv_namespaces]]
   binding = "COPY_STATS_KV"
   id = "your-kv-namespace-id"
   ```

3. **Deploy:**
   ```bash
   wrangler deploy
   ```

### Option 2: Cloudflare Pages Functions

1. Place `copy-stats.ts` in `functions/api/copy-stats.ts`
2. Create KV namespace in Cloudflare dashboard
3. Bind KV namespace in Pages settings

### Option 3: Vercel/Netlify Serverless Function

Convert to Node.js format and deploy as serverless function.

## API Endpoints

### GET `/api/copy-stats`
Returns current copy counts:
```json
{
  "windows": 123,
  "linux": 456,
  "mac": 789,
  "total": 1368
}
```

### POST `/api/copy-stats`
Tracks a copy event. Body:
```json
{
  "platform": "windows" | "linux" | "mac",
  "sessionId": "unique-session-id"
}
```

Returns updated counts or rate limit message if copied within 10 minutes.

## Rate Limiting

- One copy per session per 10 minutes
- Session tracked via `sessionId` (generated client-side)
- Stored in KV with 10-minute TTL
