# Next Steps: Deploy to GitHub Pages

## ✅ What's Been Done

1. **Build Scripts Enhanced** - Secure packaging with source code protection
2. **Install Scripts Updated** - Correct URLs pointing to GitHub Pages
3. **Website HTML Updated** - Install commands now use correct URLs
4. **Deployment Script Created** - `deploy-to-github-pages.ps1` ready to use
5. **API Endpoint Created** - `api/latest.json` for version checking

## 🚀 What You Need to Do Now

### Prerequisites: Set Up GitHub CLI (One-Time, 2 minutes)

If you haven't already, install and authenticate GitHub CLI:

```powershell
# Install (if needed)
winget install --id GitHub.cli

# Authenticate
gh auth login
```

See `Persistencedev/GITHUB_CLI_SETUP.md` for detailed instructions.

### Step 1: Automated Deployment (One Command!)

```powershell
cd Persistencedev
.\deploy-to-github-pages.ps1 -Version "1.0.13"
```

This single command will:
1. ✅ Build distribution packages
2. ✅ Verify no source code leaks
3. ✅ Update `latest.json`
4. ✅ Create GitHub Release
5. ✅ Upload ZIP files and checksums
6. ✅ Deploy website to GitHub Pages

**That's it!** 🎉

### Manual Steps (If GitHub CLI Not Available)

If you don't have GitHub CLI set up, you can still deploy manually:

#### Step 1: Build Packages
```powershell
cd Persistencedev
.\build-distribution.ps1 -Version "1.0.13"
.\deploy-to-github-pages.ps1 -Version "1.0.13" -SkipRelease -SkipWebsite
```

#### Step 2: Create GitHub Release
1. Go to: https://github.com/Persistence-AI/Landing/releases/new
2. **Tag**: `v1.0.13`
3. Upload ZIP files from `Persistencedev/dist/`
4. Publish

#### Step 3: Deploy Website
```powershell
# Clone Landing repo
cd ..
git clone https://github.com/Persistence-AI/Landing.git
cd Landing

# Copy website files
Copy-Item -Path "..\PersistenceCLI\website\*" -Destination "." -Recurse -Force

# Commit and push
git add .
git commit -m "Deploy website v1.0.13"
git push origin main
```

### Step 2: Enable GitHub Pages (One-Time Setup)

1. Go to: https://github.com/Persistence-AI/Landing/settings/pages
2. **Source**: `Deploy from a branch`
3. **Branch**: `main` / `root`
4. **Folder**: `/ (root)`
5. Click **Save**

Wait 1-2 minutes for GitHub Pages to build.

## ✅ Verify It Works

1. **Website**: https://persistence-ai.github.io/Landing/
   - Should show install commands
   - Version badge should show `v1.0.13`

2. **Install Scripts**:
   ```powershell
   # Windows - should download and install
   iwr -useb https://persistence-ai.github.io/Landing/install.ps1 | iex
   
   # Linux/macOS - should download and install
   curl -fsSL https://persistence-ai.github.io/Landing/install.sh | bash
   ```

3. **API Endpoint**: https://persistence-ai.github.io/Landing/api/latest.json
   - Should return: `{"version":"1.0.13","channel":"latest",...}`

## 📋 Install Commands for Your Website

Once deployed, users can use these commands:

### ✅ Working Now (After Deployment)

**Install Script (Recommended):**
- **Windows**: `iwr -useb https://persistence-ai.github.io/Landing/install.ps1 | iex`
- **Linux/macOS**: `curl -fsSL https://persistence-ai.github.io/Landing/install.sh | bash`

**Direct Download:**
- Users can download ZIP files from: https://github.com/Persistence-AI/Landing/releases

### ⚠️ Not Yet Implemented (Future Work)

These require additional setup:

- **npm/bun/pnpm/yarn**: Need to publish to npm registry
- **Homebrew**: Need to create Homebrew formula
- **Chocolatey**: Need to create Chocolatey package
- **Scoop**: Need to add to Scoop bucket
- **Arch Linux (Paru)**: Need to create AUR package

## 🔄 For Future Releases

When releasing a new version (e.g., v1.0.14):

1. Update version in `build-distribution.ps1` call
2. Run `deploy-to-github-pages.ps1` with new version
3. Create new GitHub Release with new tag
4. Push website files (they auto-update `latest.json`)

## 📝 Notes

- **Install scripts are PUBLIC** - This is fine, they're just installation logic
- **ZIP files are SECURE** - Verified to contain no source code
- **GitHub Pages is FREE** - No hosting costs
- **Custom Domain**: You can add `persistenceai.com` later if desired

## 🆘 Troubleshooting

**404 on install scripts?**
- Wait 1-2 minutes after pushing (GitHub Pages rebuilds)
- Check files are in `website/` directory
- Verify GitHub Pages is enabled

**Version not found?**
- Check GitHub Release exists with correct tag
- Verify `api/latest.json` has correct version
- Ensure ZIP filename matches pattern

**Need help?** See `DEPLOYMENT_GUIDE.md` for detailed instructions.
