# PersistenceAI GitHub Pages Deployment Guide

This guide explains how to deploy PersistenceAI to GitHub Pages so users can install it using the install scripts.

## Prerequisites

1. **GitHub Repository**: `Persistence-AI/Landing` must exist and be accessible
2. **GitHub Pages**: Enabled in repository settings (Settings → Pages)
3. **Build Scripts**: `build-distribution.ps1` and `deploy-to-github-pages.ps1` in `Persistencedev/`

## Deployment Steps

### Step 1: Build Distribution Packages

```powershell
cd Persistencedev
.\build-distribution.ps1 -Version "1.0.13"
```

This will:
- Build the binary for your platform (or all platforms with `-AllPlatforms`)
- Create ZIP files in `dist/` directory
- Verify no source code is included
- Generate SHA256 checksums

**Output**: `dist/persistenceai-{platform}-v{version}.zip`

### Step 2: Prepare Website Files

```powershell
cd Persistencedev
.\deploy-to-github-pages.ps1 -Version "1.0.13"
```

This will:
- Verify ZIP files are secure (no source code)
- Update `website/api/latest.json` with the new version
- Ensure install scripts are in `website/` directory
- Verify all required files are present

### Step 3: Create GitHub Release

1. Go to https://github.com/Persistence-AI/Landing/releases/new
2. **Tag**: `v1.0.13` (must match version exactly)
3. **Title**: `PersistenceAI 1.0.13`
4. **Description**: Copy from `CHANGELOG.md` or create release notes
5. **Upload Assets**:
   - Upload all ZIP files from `Persistencedev/dist/`
   - Upload all `.sha256` checksum files
6. **Publish Release**

### Step 4: Deploy Website to GitHub Pages

#### Option A: Manual Deployment (Recommended for first time)

1. **Clone the Landing repository** (if not already):
   ```powershell
   cd ..
   git clone https://github.com/Persistence-AI/Landing.git
   cd Landing
   ```

2. **Copy website files**:
   ```powershell
   # From PersistenceCLI directory
   Copy-Item -Path "website\*" -Destination "Landing\" -Recurse -Force
   ```

3. **Commit and push**:
   ```powershell
   git add .
   git commit -m "Deploy website v1.0.13"
   git push origin main
   ```

4. **Enable GitHub Pages** (if not already):
   - Go to repository Settings → Pages
   - Source: `Deploy from a branch`
   - Branch: `main` / `root`
   - Save

#### Option B: GitHub Actions (Automated)

Create `.github/workflows/deploy-pages.yml` in the Landing repository:

```yaml
name: Deploy to GitHub Pages

on:
  push:
    branches:
      - main
    paths:
      - 'website/**'
      - '.github/workflows/deploy-pages.yml'

permissions:
  contents: read
  pages: write
  id-token: write

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Pages
        uses: actions/configure-pages@v4
      
      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: '.'
      
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
```

### Step 5: Verify Deployment

1. **Check website**: https://persistence-ai.github.io/Landing/
2. **Test install scripts**:
   ```powershell
   # Windows
   iwr -useb https://persistence-ai.github.io/Landing/install.ps1 | iex
   
   # Linux/macOS
   curl -fsSL https://persistence-ai.github.io/Landing/install.sh | bash
   ```
3. **Verify API endpoint**: https://persistence-ai.github.io/Landing/api/latest.json
4. **Check GitHub Release**: https://github.com/Persistence-AI/Landing/releases

## Install Commands for Users

Once deployed, users can install using:

### Install Script (Recommended)

**Windows:**
```powershell
iwr -useb https://persistence-ai.github.io/Landing/install.ps1 | iex
```

**Linux/macOS:**
```bash
curl -fsSL https://persistence-ai.github.io/Landing/install.sh | bash
```

### Direct Download

Users can also download ZIP files directly from GitHub Releases:
- https://github.com/Persistence-AI/Landing/releases

## Package Manager Installation (Future)

The following install methods require additional setup:

### npm/bun/pnpm/yarn
- **Status**: Not yet implemented
- **Requires**: Publishing to npm registry
- **Future**: `npm install -g persistenceai`

### Homebrew
- **Status**: Not yet implemented
- **Requires**: Creating Homebrew formula
- **Future**: `brew install persistenceai`

### Chocolatey
- **Status**: Not yet implemented
- **Requires**: Creating Chocolatey package
- **Future**: `choco install persistenceai`

### Scoop
- **Status**: Not yet implemented
- **Requires**: Adding to Scoop bucket
- **Future**: `scoop install persistenceai`

### Arch Linux (Paru)
- **Status**: Not yet implemented
- **Requires**: Creating AUR package
- **Future**: `paru -S persistenceai-bin`

## Troubleshooting

### Install Script Not Found (404)

**Problem**: `https://persistence-ai.github.io/Landing/install.ps1` returns 404

**Solution**:
1. Verify files are in `website/` directory
2. Check GitHub Pages is enabled
3. Ensure files are committed and pushed to `main` branch
4. Wait 1-2 minutes for GitHub Pages to rebuild

### Version Not Found

**Problem**: Install script says "version not found"

**Solution**:
1. Verify `website/api/latest.json` exists and has correct version
2. Check GitHub Release exists with tag `v{version}`
3. Verify ZIP file name matches: `persistenceai-{platform}-v{version}.zip`

### Source Code Leakage Warning

**Problem**: Build script warns about source files

**Solution**:
1. Check `build-distribution.ps1` is using explicit file inclusion
2. Verify `build.ts` is cleaning source maps
3. Manually inspect ZIP contents before uploading

## File Structure After Deployment

```
Landing/ (GitHub repository)
├── index.html              # Main website
├── install.ps1             # Windows installer
├── install.sh              # Unix installer
├── api/
│   └── latest.json         # Version API
└── assets/                 # Website assets
```

## Security Checklist

Before each deployment:

- [ ] ZIP files verified (no `.ts`, `.tsx`, `.map`, `src/`, `node_modules/`)
- [ ] Install scripts updated with correct BASE_URL
- [ ] `latest.json` has correct version
- [ ] GitHub Release created with correct tag
- [ ] Website files committed and pushed
- [ ] Install commands tested on clean system

## Next Steps

1. **Test installation** on a clean Windows/Linux/macOS system
2. **Update website** with any additional documentation
3. **Monitor GitHub Pages** deployment status
4. **Set up automated releases** (optional, using GitHub Actions)
