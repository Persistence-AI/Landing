# Website Deployment Guide

## Overview

This website includes real-time copy tracking for install scripts with session-based rate limiting (1 copy per 10 minutes per session).

## File Structure

```
website/
├── index.html              # Main website
├── api/
│   ├── copy-stats.ts      # Cloudflare Worker API
│   └── README.md          # API documentation
└── DEPLOYMENT.md          # This file
```

## Backend API Setup

### Option 1: Cloudflare Workers (Recommended)

1. **Install Wrangler CLI:**
   ```bash
   npm install -g wrangler
   ```

2. **Create KV Namespace:**
   ```bash
   wrangler kv:namespace create "COPY_STATS_KV"
   wrangler kv:namespace create "COPY_STATS_KV" --preview
   ```

3. **Create `wrangler.toml` in `website/api/`:**
   ```toml
   name = "copy-stats-api"
   main = "copy-stats.ts"
   compatibility_date = "2024-01-01"

   [[kv_namespaces]]
   binding = "COPY_STATS_KV"
   id = "your-kv-namespace-id"
   preview_id = "your-preview-kv-namespace-id"
   ```

4. **Deploy:**
   ```bash
   cd website/api
   wrangler deploy
   ```

5. **Update API URL in `index.html`:**
   ```javascript
   const API_BASE_URL = 'https://copy-stats-api.your-subdomain.workers.dev';
   ```

### Option 2: Cloudflare Pages Functions

1. **Create KV Namespace** in Cloudflare Dashboard
2. **Place API file** in `functions/api/copy-stats.ts`
3. **Bind KV** in Pages settings → Functions → KV Namespace Bindings
4. **Update API URL** to your Pages domain

### Option 3: Vercel Serverless Function

1. **Create `api/copy-stats.js`** (convert TypeScript to JavaScript)
2. **Use Vercel KV** or **Upstash Redis** for storage
3. **Deploy** to Vercel

## Frontend Configuration

### Update API Endpoint

In `index.html`, update the API base URL:

```javascript
const API_BASE_URL = 'https://your-api-domain.com';
```

### How It Works

1. **Session Management:**
   - Each user gets a unique session ID stored in `sessionStorage`
   - Session persists for the browser tab lifetime

2. **Rate Limiting:**
   - One copy per session per 10 minutes
   - Tracked server-side using session ID
   - Prevents abuse while allowing legitimate users

3. **Real-time Updates:**
   - Counts fetched on page load
   - Polls API every 30 seconds for updates
   - Updates displayed immediately when user copies

4. **Platform Detection:**
   - Automatically detects Windows/Linux/Mac
   - Tracks platform-specific counts
   - Cross-platform methods (npm, bun) use detected platform

## Testing

### Local Testing

1. **Test API locally** (if using Wrangler):
   ```bash
   wrangler dev
   ```

2. **Test frontend:**
   - Open `index.html` in browser
   - Open DevTools → Network tab
   - Click copy buttons
   - Verify API calls are made

### Production Testing

1. **Test rate limiting:**
   - Copy a script
   - Immediately try to copy again
   - Should see "Rate limited" message
   - Wait 10 minutes and try again

2. **Test real-time updates:**
   - Open site in two browsers
   - Copy in one browser
   - Count should update in both within 30 seconds

## Security Considerations

1. **CORS:** API allows all origins (`*`). For production, restrict to your domain:
   ```typescript
   'Access-Control-Allow-Origin': 'https://persistenceai.com'
   ```

2. **Rate Limiting:** Current implementation uses session-based limiting. Consider adding:
   - IP-based rate limiting
   - CAPTCHA for suspicious activity
   - Maximum daily copies per IP

3. **API Key:** For production, consider adding API key authentication:
   ```typescript
   const API_KEY = request.headers.get('X-API-Key');
   if (API_KEY !== env.API_KEY) {
     return new Response('Unauthorized', { status: 401 });
   }
   ```

## Monitoring

### Cloudflare Analytics

- Monitor KV operations
- Track API request volume
- Monitor error rates

### Custom Logging

Add logging to track:
- Copy events
- Rate limit hits
- API errors

## Troubleshooting

### Counts Not Updating

1. Check API endpoint is accessible
2. Verify CORS headers
3. Check browser console for errors
4. Verify KV namespace is bound correctly

### Rate Limiting Not Working

1. Verify session ID is being generated
2. Check KV namespace TTL settings
3. Verify session storage is working (not in incognito mode)

### Counts Reset

1. KV namespace data persists unless manually deleted
2. Check KV namespace retention settings
3. Verify no accidental namespace deletion
