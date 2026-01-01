# Quick Deploy Guide - Easiest Method

## 🚀 Option 1: Vercel (Recommended - 2 minutes)

### Step 1: Install Vercel CLI
```bash
npm install -g vercel
```

### Step 2: Deploy
```bash
cd Landing/api/serverless
vercel
```

Follow the prompts:
- **Link to existing project?** → No (create new)
- **Project name?** → `persistenceai-stats` (or any name)
- **Directory?** → `./` (current directory)

### Step 3: Set Environment Variables
1. Go to [Vercel Dashboard](https://vercel.com/dashboard)
2. Click your project → **Settings** → **Environment Variables**
3. Add these:
   - **Name:** `GITHUB_TOKEN` → **Value:** `YOUR_GITHUB_TOKEN_HERE` (get from GitHub Settings → Developer settings → Personal access tokens)
   - **Name:** `GIST_ID` → **Value:** `d91c13368227583a3456fe3f5c29ef34`
4. Click **Save**

### Step 4: Redeploy
```bash
vercel --prod
```

### Step 5: Get Your URL
Vercel will show you: `https://persistenceai-stats.vercel.app/api/write-stats`

**Copy this URL!**

### Step 6: Update Frontend
Edit `Landing/index.html` line ~2584:
```javascript
const STATS_API_URL = 'https://persistenceai-stats.vercel.app/api/write-stats';
```

---

## 🌐 Option 2: Netlify (Alternative)

### Step 1: Install Netlify CLI
```bash
npm install -g netlify-cli
```

### Step 2: Create `netlify.toml` in `api/serverless/`:
```toml
[build]
  functions = "."

[[redirects]]
  from = "/api/*"
  to = "/.netlify/functions/:splat"
  status = 200
```

### Step 3: Deploy
```bash
cd Landing/api/serverless
netlify deploy --prod
```

### Step 4: Set Environment Variables
1. Go to [Netlify Dashboard](https://app.netlify.com)
2. Your site → **Site settings** → **Environment variables**
3. Add `GITHUB_TOKEN` and `GIST_ID`

### Step 5: Get Your URL
Netlify will give you: `https://your-site.netlify.app/api/write-stats`

---

## ✅ After Deployment

1. **Update `index.html`** with your API URL
2. **Deploy the updated HTML:**
   ```bash
   cd Landing
   git add index.html
   git commit -m "feat: Add serverless stats API integration"
   git push origin main
   ```

3. **Test it:**
   - Visit your website
   - Click a "Copy" button
   - Check browser console for `[Stats] Successfully synced to Gist`
   - Refresh page - counts should update globally!

---

## 🔒 Security Notes

- ✅ GitHub token is stored securely in Vercel/Netlify (not in code)
- ✅ CORS is restricted to your domain only
- ✅ Token never exposed to frontend

---

## 🐛 Troubleshooting

**"Failed to sync stats" error:**
- Check environment variables are set correctly
- Verify CORS allows your domain
- Check Vercel/Netlify function logs

**Counts not updating:**
- Make sure `STATS_API_URL` is set in `index.html`
- Check browser console for errors
- Verify Gist is public (for reading)
