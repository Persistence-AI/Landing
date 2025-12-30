# Quick Deployment Guide

## TL;DR - Deploy in 4 Steps

### 1. Build Packages
```powershell
cd Persistencedev
.\build-distribution.ps1 -Version "1.0.13"
```

### 2. Prepare Website
```powershell
.\deploy-to-github-pages.ps1 -Version "1.0.13"
```

### 3. Create GitHub Release
- Go to: https://github.com/Persistence-AI/Landing/releases/new
- Tag: `v1.0.13`
- Upload ZIP files from `Persistencedev/dist/`
- Publish

### 4. Deploy Website
```powershell
# Clone Landing repo (if needed)
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

## Verify

1. **Website**: https://persistence-ai.github.io/Landing/
2. **Install Scripts**:
   - Windows: `iwr -useb https://persistence-ai.github.io/Landing/install.ps1 | iex`
   - Linux/macOS: `curl -fsSL https://persistence-ai.github.io/Landing/install.sh | bash`
3. **API**: https://persistence-ai.github.io/Landing/api/latest.json

## That's It! 🎉

Users can now install PersistenceAI using the install commands shown on your website.
