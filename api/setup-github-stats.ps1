# Setup script for GitHub Gist-based stats
# This creates the initial Gist and outputs the Gist ID

param(
    [Parameter(Mandatory=$true)]
    [string]$GitHubToken,
    
    [string]$GistDescription = "PersistenceAI Website Analytics & Copy Stats"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  GitHub Stats Gist Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Default stats structure
$defaultStats = @{
    copyCounts = @{
        windows = 0
        linux = 0
        mac = 0
        total = 0
    }
    visitors = @{
        total = 0
        daily = @{}
        fingerprints = @{}
    }
    pageViews = @{
        total = 0
        daily = @{}
    }
    lastUpdated = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
} | ConvertTo-Json -Depth 10

# Create Gist
$body = @{
    description = $GistDescription
    public = $true  # Public Gist allows frontend to read without authentication
    files = @{
        "persistenceai-stats.json" = @{
            content = $defaultStats
        }
    }
} | ConvertTo-Json -Depth 10

try {
    $headers = @{
        "Authorization" = "token $GitHubToken"
        "Accept" = "application/vnd.github.v3+json"
        "Content-Type" = "application/json"
    }

    $response = Invoke-RestMethod -Uri "https://api.github.com/gists" -Method Post -Headers $headers -Body $body
    
    Write-Host "[OK] Gist created successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Gist ID: $($response.id)" -ForegroundColor Cyan
    Write-Host "Gist URL: $($response.html_url)" -ForegroundColor Cyan
    Write-Host ""
    
    # Try to automatically update index.html
    $indexHtmlPath = Join-Path (Split-Path $PSScriptRoot -Parent) "index.html"
    if (Test-Path $indexHtmlPath) {
        Write-Host "[INFO] Attempting to update index.html automatically..." -ForegroundColor Cyan
        try {
            $indexContent = Get-Content $indexHtmlPath -Raw -Encoding UTF8
            $gistIdPattern = 'const GITHUB_STATS_GIST_ID = [''"]?([^''";]*)[''"]?;'
            
            if ($indexContent -match $gistIdPattern) {
                $updatedContent = $indexContent -replace $gistIdPattern, "const GITHUB_STATS_GIST_ID = '$($response.id)';"
                Set-Content -Path $indexHtmlPath -Value $updatedContent -Encoding UTF8 -NoNewline
                Write-Host "[OK] index.html updated successfully with Gist ID!" -ForegroundColor Green
            } else {
                Write-Host "[WARN] Could not find GITHUB_STATS_GIST_ID pattern in index.html" -ForegroundColor Yellow
                Write-Host "       Please update manually:" -ForegroundColor Yellow
                Write-Host "       const GITHUB_STATS_GIST_ID = '$($response.id)';" -ForegroundColor Gray
            }
        } catch {
            Write-Host "[WARN] Could not auto-update index.html: $($_.Exception.Message)" -ForegroundColor Yellow
            Write-Host "       Please update manually:" -ForegroundColor Yellow
            Write-Host "       const GITHUB_STATS_GIST_ID = '$($response.id)';" -ForegroundColor Gray
        }
    } else {
        Write-Host "[INFO] index.html not found at expected path: $indexHtmlPath" -ForegroundColor Yellow
        Write-Host "       Please update manually:" -ForegroundColor Yellow
        Write-Host "       const GITHUB_STATS_GIST_ID = '$($response.id)';" -ForegroundColor Gray
    }
    Write-Host ""
    
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Verify Gist ID is set in index.html (auto-updated if found)" -ForegroundColor White
    Write-Host "2. If you made the gist public, you can read without authentication" -ForegroundColor White
    Write-Host "3. For writes, you'll need to set up GitHub Actions (see github-stats-setup.md)" -ForegroundColor White
    Write-Host ""
    
    # Save to file for reference
    $config = @{
        gistId = $response.id
        gistUrl = $response.html_url
        createdAt = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    } | ConvertTo-Json
    
    $config | Out-File -FilePath "gist-config.json" -Encoding UTF8
    Write-Host "[INFO] Configuration saved to gist-config.json" -ForegroundColor Cyan
    
} catch {
    Write-Host "[ERROR] Failed to create Gist:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    
    # Try to extract more details from the error
    if ($_.Exception.Response) {
        try {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $responseBody = $reader.ReadToEnd()
            $errorDetails = $responseBody | ConvertFrom-Json -ErrorAction SilentlyContinue
            if ($errorDetails.message) {
                Write-Host "GitHub API Error: $($errorDetails.message)" -ForegroundColor Red
            }
        } catch {
            # Ignore JSON parsing errors
        }
    }
    
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "  - Verify your GitHub token has 'gist' scope" -ForegroundColor White
    Write-Host "  - Check that the token is valid and not expired" -ForegroundColor White
    Write-Host "  - Ensure you have permission to create gists" -ForegroundColor White
    Write-Host "  - Token format should be: ghp_xxxxxxxxxxxxx" -ForegroundColor White
    exit 1
}
