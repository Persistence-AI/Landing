# Create minimal placeholder PNG files to prevent 404 errors
# These are 1x1 transparent PNG files

# Base64 encoded 1x1 transparent PNG
$transparentPng = [System.Convert]::FromBase64String('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==')

# Create placeholder files
$files = @('tui-home-preview.png', 'tui-multipane-preview.png')

foreach ($file in $files) {
    $path = Join-Path $PSScriptRoot $file
    [System.IO.File]::WriteAllBytes($path, $transparentPng)
    Write-Host "Created: $file" -ForegroundColor Green
}

Write-Host "`nPlaceholder images created successfully!" -ForegroundColor Cyan
Write-Host "These prevent 404 errors. Replace with actual screenshots when ready." -ForegroundColor Yellow
