# Script to make existing Gist public
param(
    [Parameter(Mandatory=$true)]
    [string]$GitHubToken,
    
    [Parameter(Mandatory=$true)]
    [string]$GistId
)

Write-Host "Making Gist public..." -ForegroundColor Cyan

$headers = @{
    "Authorization" = "token $GitHubToken"
    "Accept" = "application/vnd.github.v3+json"
    "Content-Type" = "application/json"
}

# First, get the current Gist to preserve its content
try {
    $currentGist = Invoke-RestMethod -Uri "https://api.github.com/gists/$GistId" -Headers $headers
    
    # Build update body with existing files and public flag
    $updateBody = @{
        description = $currentGist.description
        public = $true
        files = @{}
    }
    
    # Preserve all existing files
    foreach ($fileName in $currentGist.files.PSObject.Properties.Name) {
        $file = $currentGist.files.$fileName
        $updateBody.files[$fileName] = @{
            content = $file.content
        }
    }
    
    $body = $updateBody | ConvertTo-Json -Depth 10
} catch {
    # Fallback: just set public flag
    $body = @{
        public = $true
    } | ConvertTo-Json
}

try {
    $response = Invoke-RestMethod -Uri "https://api.github.com/gists/$GistId" -Method Patch -Headers $headers -Body $body
    
    Write-Host "[OK] Gist is now PUBLIC!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Gist ID: $($response.id)" -ForegroundColor Cyan
    Write-Host "Gist URL: $($response.html_url)" -ForegroundColor Cyan
    Write-Host "Public: $($response.public)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Your frontend can now read stats without authentication!" -ForegroundColor Green
    
} catch {
    Write-Host "[ERROR] Failed to make Gist public:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    
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
    exit 1
}
