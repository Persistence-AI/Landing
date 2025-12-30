# Replace Logo with Optimized Version

## Steps to Replace

1. **Locate your optimized logo file** (downloaded from TinyPNG)
   - Usually in your Downloads folder
   - Filename might be: `logo.png` or `logo-tinypng.png`

2. **Replace the current logo:**
   - Copy your optimized logo file
   - Paste it into: `website/assets/`
   - **Replace** the existing `logo.png` file

## Quick PowerShell Command

If your optimized logo is in Downloads:

```powershell
cd "c:\Users\Legion\Desktop\PersistenceCLI\website\assets"
Copy-Item "$env:USERPROFILE\Downloads\logo*.png" -Destination "logo.png" -Force
```

Or manually:
1. Open `website/assets/` folder
2. Delete or rename current `logo.png`
3. Copy your optimized logo from Downloads
4. Paste into `website/assets/`
5. Rename to `logo.png` (if needed)

## Verify Optimization

After replacing, check the file size:

```powershell
cd "c:\Users\Legion\Desktop\PersistenceCLI\website\assets"
(Get-Item logo.png).Length / 1KB
```

**Expected:** Should be ~50-100 KB (down from ~1100 KB)

## Current Setup

- **Location:** `website/assets/logo.png`
- **HTML Path:** `src="assets/logo.png"`
- **Display Size:** 1.1rem × 1.1rem (~17.6px)

The optimized logo will:
- ✅ Load much faster
- ✅ Reduce page size significantly
- ✅ Still display clearly at small size
- ✅ Maintain recognizable shape and colors
