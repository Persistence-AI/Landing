# GitHub Pages Quick Start

## Current Situation

- **Your website:** `https://persistence-ai.github.io/Landi`
- **Website files:** In `website/` directory
- **Install scripts:** Need to be deployed to GitHub Pages
- **Download files:** Need to be hosted (GitHub Releases recommended)

## Quick Setup (5 Minutes)

### Step 1: Update Website URLs

**Option A: Use PowerShell Script (Easiest)**

```powershell
cd website
.\update-urls-for-github-pages.ps1
```

**Option B: Manual Update**

Replace all instances of `https://persistenceai.com` with `https://persistence-ai.github.io/Landi` in `index.html`.

### Step 2: Copy Install Scripts

```powershell
# From project root
cp Persistencedev/install.ps1 website/
cp Persistencedev/install.sh website/
```

### Step 3: Update Install Script URLs

**In `website/install.ps1`:**
```powershell
# Change line 21:
$BASE_URL = "https://persistence-ai.github.io/Landi"
```

**In `website/install.sh`:**
```bash
# Change line 29:
BASE_URL="https://persistence-ai.github.io/Landi"
```

### Step 4: Create Version API

Create `website/api/latest.json`:

```json
{
  "version": "1.0.202",
  "channel": "latest",
  "download_url": "https://persistence-ai.github.io/Landi/download/v1.0.202/"
}
```

### Step 5: Deploy to GitHub Pages

**Option A: GitHub Actions (Automatic)**

Create `.github/workflows/deploy-website.yml`:

```yaml
name: Deploy Website

on:
  push:
    branches: [main]
    paths: ['website/**']

jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      pages: write
      id-token: write
    steps:
      - uses: actions/checkout@v4
      - uses: actions/configure-pages@v4
      - uses: actions/upload-pages-artifact@v3
        with:
          path: './website'
      - uses: actions/deploy-pages@v4
```

**Option B: Manual (Settings)**

1. Go to repository **Settings** → **Pages**
2. Source: **Deploy from a branch**
3. Branch: **main** / **website/**
4. Save

### Step 6: Host Download Files

**Recommended: GitHub Releases**

1. Build your distribution:
   ```powershell
   cd Persistencedev
   .\build-distribution.ps1 -Version "1.0.202"
   ```

2. Create GitHub Release:
   - Go to: `https://github.com/persistence-ai/Landi/releases/new`
   - Tag: `v1.0.202`
   - Upload: `dist/persistenceai-windows-x64-v1.0.202.zip`

3. Update install scripts to use GitHub Releases (already configured as fallback)

## Test Installation

**Windows:**
```powershell
iwr -useb https://persistence-ai.github.io/Landi/install.ps1 | iex
```

**Linux/macOS:**
```bash
curl -fsSL https://persistence-ai.github.io/Landi/install.sh | bash
```

## File Structure After Deployment

```
https://persistence-ai.github.io/Landi/
├── index.html          ✅ Main website
├── install.ps1        ✅ PowerShell installer
├── install.sh          ✅ Bash installer
├── api/
│   └── latest.json     ✅ Version API
└── assets/
    └── logo.png        ✅ Logo
```

## Custom Domain Setup (Optional)

If you want to use `persistenceai.com` instead:

1. **Update URLs:**
   ```powershell
   cd website
   .\update-urls-for-github-pages.ps1 -CustomDomain "persistenceai.com"
   ```

2. **Configure GitHub Pages:**
   - Go to repository **Settings** → **Pages**
   - Add custom domain: `persistenceai.com`

3. **Update DNS:**
   - Add CNAME record: `persistenceai.com` → `persistence-ai.github.io`

## Troubleshooting

### 404 Errors

- Check file paths (GitHub Pages is case-sensitive)
- Ensure files are in the correct branch
- Wait a few minutes for GitHub Pages to update

### Install Scripts Not Working

- Verify URLs in install scripts match GitHub Pages URL
- Check that scripts are in the repository root or correct subdirectory
- Test direct access: `https://persistence-ai.github.io/Landi/install.ps1`

### Downloads Fail

- Use GitHub Releases for large files (>100MB)
- Check file permissions in repository
- Verify download URLs in install scripts

## Next Steps

1. ✅ Update website URLs
2. ✅ Deploy install scripts
3. ✅ Set up version API
4. ✅ Configure GitHub Pages
5. ✅ Test installation
6. ⏭️ Set up custom domain (optional)
7. ⏭️ Configure automatic deployment (GitHub Actions)

## Full Documentation

See `GITHUB_PAGES_SETUP.md` for detailed instructions.
