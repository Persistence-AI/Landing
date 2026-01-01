# Serverless Function for Stats Sync

This serverless function allows the frontend to securely write stats to the GitHub Gist.

## Deployment Options

### Option 1: Vercel (Recommended - Easiest)

1. **Install Vercel CLI:**
   ```bash
   npm i -g vercel
   ```

2. **Deploy:**
   ```bash
   cd api/serverless
   vercel
   ```

3. **Set Environment Variables:**
   - Go to Vercel Dashboard → Your Project → Settings → Environment Variables
   - Add:
     - `GITHUB_TOKEN` = `YOUR_GITHUB_TOKEN_HERE` (get from GitHub Settings → Developer settings → Personal access tokens)
     - `GIST_ID` = `d91c13368227583a3456fe3f5c29ef34`

4. **Get your endpoint URL:**
   - Vercel will give you: `https://your-project.vercel.app/api/write-stats`
   - Update `index.html` with this URL

### Option 2: Netlify Functions

1. **Create `netlify.toml` in project root:**
   ```toml
   [build]
     functions = "api/serverless"
   
   [[redirects]]
     from = "/api/*"
     to = "/.netlify/functions/:splat"
     status = 200
   ```

2. **Deploy:**
   ```bash
   npm install -g netlify-cli
   netlify deploy --prod
   ```

3. **Set Environment Variables:**
   - Netlify Dashboard → Site Settings → Environment Variables
   - Add `GITHUB_TOKEN` and `GIST_ID`

### Option 3: Cloudflare Workers (Free)

1. **Install Wrangler:**
   ```bash
   npm install -g wrangler
   ```

2. **Create `wrangler.toml`:**
   ```toml
   name = "persistenceai-stats"
   main = "api/serverless/write-stats.js"
   compatibility_date = "2024-01-01"
   ```

3. **Deploy:**
   ```bash
   wrangler publish
   ```

4. **Set Secrets:**
   ```bash
   wrangler secret put GITHUB_TOKEN
   wrangler secret put GIST_ID
   ```

## Update Frontend

After deployment, update `index.html` to use the endpoint:

```javascript
const STATS_API_URL = 'https://your-endpoint.vercel.app/api/write-stats';

async function syncStatsToGist(data) {
  try {
    const response = await fetch(STATS_API_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    });
    return await response.json();
  } catch (error) {
    console.error('Failed to sync stats:', error);
    return null;
  }
}
```

## Security

- ✅ GitHub token stored securely in environment variables
- ✅ CORS restricted to your domain
- ✅ Only POST requests allowed
- ✅ No token exposed in client-side code
