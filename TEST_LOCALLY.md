# Testing Website Locally

## Issue: Logo 404 Error

If you see a 404 error for `logo.png` when opening `index.html` directly in a browser, it's because browsers restrict loading local files when using the `file://` protocol.

## Solutions

### Option 1: Use a Local Web Server (Recommended)

**Python:**
```bash
cd website
python -m http.server 8000
```
Then open: `http://localhost:8000`

**Node.js:**
```bash
cd website
npx http-server
```

**VS Code:**
- Install "Live Server" extension
- Right-click `index.html` → "Open with Live Server"

### Option 2: Use Absolute Path (Windows)

If you must use `file://`, try:
```html
<img src="file:///C:/Users/Legion/Desktop/PersistenceCLI/website/assets/logo.png" />
```

**Note:** This only works on your machine and won't work when deployed.

### Option 3: Convert to Base64 (For Testing)

For a self-contained HTML file, you can embed the logo as base64, but this makes the HTML file very large (~1MB+).

## Current Setup

- **Logo location:** `website/assets/logo.png`
- **HTML path:** `src="assets/logo.png"`
- **Works when:** Served from a web server (not file://)

## When Deployed

When you deploy to a web server (Cloudflare Pages, Vercel, etc.), the relative path `assets/logo.png` will work perfectly.
