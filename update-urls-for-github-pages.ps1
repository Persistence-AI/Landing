# Update Website URLs for GitHub Pages
# Usage: .\update-urls-for-github-pages.ps1 [-CustomDomain "persistenceai.com"]

param(
    [string]$CustomDomain = "",
    [string]$GitHubPagesUrl = "https://persistence-ai.github.io/Landi"
)

$ErrorActionPreference = "Stop"

# Determine base URL
$BaseUrl = if ($CustomDomain) {
    "https://$CustomDomain"
} else {
    $GitHubPagesUrl
}

Write-Host "Updating website URLs to: $BaseUrl" -ForegroundColor Cyan

$indexHtml = "index.html"

if (-not (Test-Path $indexHtml)) {
    Write-Error "index.html not found in current directory"
    exit 1
}

# Read file
$content = Get-Content $indexHtml -Raw

# Replace all instances of persistenceai.com with the base URL
$content = $content -replace 'https://persistenceai\.com', $BaseUrl
$content = $content -replace 'https://api\.persistenceai\.com', "$BaseUrl/api"

# Write back
Set-Content -Path $indexHtml -Value $content -NoNewline

Write-Host "✅ Updated all URLs in index.html" -ForegroundColor Green
Write-Host ""
Write-Host "Updated URLs:" -ForegroundColor Yellow
Write-Host "  Install: $BaseUrl/install" -ForegroundColor White
Write-Host "  Download: $BaseUrl/download" -ForegroundColor White
Write-Host "  API: $BaseUrl/api" -ForegroundColor White
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Review index.html to verify changes" -ForegroundColor White
Write-Host "  2. Update install.ps1 and install.sh base URLs" -ForegroundColor White
Write-Host "  3. Commit and push to GitHub" -ForegroundColor White
