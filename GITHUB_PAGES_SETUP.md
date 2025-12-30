# GitHub Pages Setup Guide

This guide explains how to configure your website and install scripts to work with GitHub Pages at `https://persistence-ai.github.io/Landi`.

## Current Setup

- **Website URL:** `https://persistence-ai.github.io/Landi`
- **Repository:** `persistence-ai/Landi` (assumed)
- **Install Scripts:** Need to be served from GitHub Pages
- **Download Files:** Need to be served from GitHub Pages or GitHub Releases

## GitHub Pages Structure

When deployed to GitHub Pages, your files will be served from:

```
https://persistence-ai.github.io/Landi/
├── index.html          # Main website
├── install.ps1        # PowerShell installer
├── install.sh         # Bash installer
├── download/          # Distribution files
│   ├── latest/
│   │   └── persistenceai-windows-x64.zip
│   └── v1.0.202/
│       └── persistenceai-windows-x64.zip
└── api/
    └── latest         # Version API (if using GitHub Pages Functions)
```

## Step 1: Update Website URLs

Update `website/index.html` to use GitHub Pages URLs instead of `persistenceai.com`:

### Option A: Use GitHub Pages Directly

Replace all instances of `https://persistenceai.com` with `https://persistence-ai.github.io/Landi`:

```javascript
// In index.html, find and replace:
'https://persistenceai.com/install' → 'https://persistence-ai.github.io/Landi/install'
'https://persistenceai.com/download' → 'https://persistence-ai.github.io/Landi/download'
'https://persistenceai.com/docs' → 'https://persistence-ai.github.io/Landi/docs'
```

### Option B: Use Custom Domain (Recommended for Production)

If you have a custom domain `persistenceai.com`:

1. **Configure GitHub Pages** to use your custom domain
2. **Update DNS** to point to GitHub Pages
3. **Keep URLs as `https://persistenceai.com`** - GitHub Pages will serve them

## Step 2: Deploy Install Scripts

### Method 1: Direct File Upload (Simple)

1. **Copy install scripts** to your website repository:
   ```bash
   cp Persistencedev/install.ps1 website/
   cp Persistencedev/install.sh website/
   ```

2. **Update install script URLs** to point to GitHub Pages:
   
   In `install.ps1`, change:
   ```powershell
   $BASE_URL = "https://persistence-ai.github.io/Landi"
   ```
   
   In `install.sh`, change:
   ```bash
   BASE_URL="https://persistence-ai.github.io/Landi"
   ```

3. **Commit and push** to your repository:
   ```bash
   cd website
   git add install.ps1 install.sh
   git commit -m "Add install scripts for GitHub Pages"
   git push
   ```

4. **Access install scripts:**
   - PowerShell: `https://persistence-ai.github.io/Landi/install.ps1`
   - Bash: `https://persistence-ai.github.io/Landi/install.sh`

### Method 2: GitHub Pages Functions (Advanced)

For dynamic routing (e.g., `/install` that serves the right script):

1. **Create `_functions/install.ts`** in your website directory:
   ```typescript
   export async function onRequest(context: EventContext) {
     const userAgent = context.request.headers.get('user-agent') || '';
     
     // Detect platform from User-Agent
     if (userAgent.includes('Windows') || userAgent.includes('PowerShell')) {
       // Serve PowerShell script
       const script = await context.env.ASSETS.fetch(
         new URL('/install.ps1', context.request.url)
       );
       return new Response(script.body, {
         headers: { 'Content-Type': 'text/plain' }
       });
     } else {
       // Serve Bash script
       const script = await context.env.ASSETS.fetch(
         new URL('/install.sh', context.request.url)
       );
       return new Response(script.body, {
         headers: { 'Content-Type': 'text/plain' }
       });
     }
   }
   ```

2. **Deploy** using GitHub Actions or Cloudflare Pages

## Step 3: Host Download Files

### Option A: GitHub Releases (Recommended)

1. **Create GitHub Release:**
   ```bash
   # Tag your release
   git tag v1.0.202
   git push origin v1.0.202
   ```

2. **Upload ZIP files** to GitHub Releases:
   - Go to: `https://github.com/persistence-ai/Landi/releases/new`
   - Upload: `persistenceai-windows-x64-v1.0.202.zip`
   - Tag: `v1.0.202`

3. **Update install scripts** to download from GitHub Releases:
   
   In `install.ps1`:
   ```powershell
   # Primary: Try GitHub Releases first
   $ghUrl = "https://github.com/persistence-ai/Landi/releases/download/v$Version/$zipName"
   Invoke-WebRequest -Uri $ghUrl -OutFile $zipPath
   ```
   
   In `install.sh`:
   ```bash
   # Primary: Try GitHub Releases first
   GH_URL="https://github.com/persistence-ai/Landi/releases/download/v$VERSION/$ZIP_NAME"
   curl -fsSL -o "$ZIP_PATH" "$GH_URL"
   ```

### Option B: GitHub Pages Static Files

1. **Create download directory:**
   ```bash
   mkdir -p website/download/v1.0.202
   ```

2. **Copy ZIP files:**
   ```bash
   cp dist/persistenceai-windows-x64-v1.0.202.zip website/download/v1.0.202/
   ```

3. **Commit and push:**
   ```bash
   git add website/download/
   git commit -m "Add distribution files"
   git push
   ```

4. **Access files:**
   - `https://persistence-ai.github.io/Landi/download/v1.0.202/persistenceai-windows-x64.zip`

**Note:** GitHub Pages has a 1GB repository size limit. For large files, use GitHub Releases instead.

## Step 4: Create Version API

### Option A: Static JSON File

1. **Create `website/api/latest.json`:**
   ```json
   {
     "version": "1.0.202",
     "channel": "latest",
     "download_url": "https://persistence-ai.github.io/Landi/download/v1.0.202/"
   }
   ```

2. **Update install scripts** to fetch from:
   ```powershell
   $latestResponse = Invoke-RestMethod -Uri "https://persistence-ai.github.io/Landi/api/latest.json"
   ```

### Option B: GitHub Pages Functions

Create `_functions/api/latest.ts`:

```typescript
export async function onRequest(context: EventContext) {
  // Fetch latest release from GitHub API
  const response = await fetch('https://api.github.com/repos/persistence-ai/Landi/releases/latest');
  const release = await response.json();
  const version = release.tag_name.replace('^v', '');
  
  return new Response(JSON.stringify({
    version,
    channel: 'latest',
    download_url: `https://persistence-ai.github.io/Landi/download/v${version}/`
  }), {
    headers: { 'Content-Type': 'application/json' }
  });
}
```

## Step 5: Update Website HTML

Update `website/index.html` to use GitHub Pages URLs:

```javascript
// Replace all instances:
const INSTALL_URL = 'https://persistence-ai.github.io/Landi/install';
const DOWNLOAD_BASE = 'https://persistence-ai.github.io/Landi/download';
const API_BASE = 'https://persistence-ai.github.io/Landi/api';
```

Or use a configuration variable:

```javascript
// At the top of the script section
const WEBSITE_BASE_URL = 'https://persistence-ai.github.io/Landi';
// Or for custom domain:
// const WEBSITE_BASE_URL = 'https://persistenceai.com';

// Then use throughout:
const installUrl = `${WEBSITE_BASE_URL}/install`;
```

## Step 6: Deploy to GitHub Pages

### Method 1: GitHub Actions (Recommended)

Create `.github/workflows/deploy-website.yml`:

```yaml
name: Deploy Website

on:
  push:
    branches:
      - main
    paths:
      - 'website/**'

jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      pages: write
      id-token: write
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Pages
        uses: actions/configure-pages@v4
      
      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: './website'
      
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
```

### Method 2: Manual Deployment

1. **Enable GitHub Pages** in repository settings:
   - Go to: `Settings` → `Pages`
   - Source: `Deploy from a branch`
   - Branch: `main` / `website/`

2. **Push website files** to the repository

3. **GitHub Pages** will automatically deploy

## Step 7: Test Installation

### Test PowerShell Installer

```powershell
iwr -useb https://persistence-ai.github.io/Landi/install.ps1 | iex
```

### Test Bash Installer

```bash
curl -fsSL https://persistence-ai.github.io/Landi/install.sh | bash
```

## Troubleshooting

### Install Scripts Not Found (404)

- **Check file paths:** GitHub Pages is case-sensitive
- **Check branch:** Ensure files are in the branch used for Pages
- **Check directory:** If using `website/` subdirectory, update base path

### Downloads Fail

- **Check file size:** GitHub Pages has 1GB limit (use Releases for large files)
- **Check MIME types:** Ensure `.zip` files are served correctly
- **Check CORS:** GitHub Pages allows cross-origin by default

### Version API Not Working

- **Check JSON format:** Ensure valid JSON
- **Check CORS headers:** GitHub Pages serves JSON with correct headers
- **Check path:** Ensure `/api/latest.json` is accessible

## Quick Reference

```bash
# Update install script URLs
sed -i 's|https://persistenceai.com|https://persistence-ai.github.io/Landi|g' website/index.html

# Copy install scripts
cp Persistencedev/install.ps1 website/
cp Persistencedev/install.sh website/

# Update install script base URLs
sed -i 's|BASE_URL = "https://persistenceai.com"|BASE_URL = "https://persistence-ai.github.io/Landi"|g' website/install.ps1
sed -i 's|BASE_URL="https://persistenceai.com"|BASE_URL="https://persistence-ai.github.io/Landi"|g' website/install.sh

# Deploy
cd website
git add .
git commit -m "Deploy website to GitHub Pages"
git push
```

## Next Steps

1. **Set up custom domain** (optional but recommended)
2. **Configure GitHub Actions** for automatic deployment
3. **Set up version API** for dynamic version detection
4. **Test installation** from multiple platforms
5. **Monitor downloads** and installation success rates
