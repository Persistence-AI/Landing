# PersistenceAI Web Installer (PowerShell)
# This script can be downloaded and executed via:
#   iwr -useb https://persistenceai.com/install | iex
#   curl -fsSL https://persistenceai.com/install.ps1 | powershell -ExecutionPolicy Bypass -Command -

$ErrorActionPreference = "Stop"

# Colors for output
function Write-Info { param([string]$msg) Write-Host "ℹ️  $msg" -ForegroundColor Cyan }
function Write-Success { param([string]$msg) Write-Host "✅ $msg" -ForegroundColor Green }
function Write-Error { param([string]$msg) Write-Host "❌ $msg" -ForegroundColor Red }
function Write-Warning { param([string]$msg) Write-Host "⚠️  $msg" -ForegroundColor Yellow }

Write-Host ""
Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║     PersistenceAI Installer           ║" -ForegroundColor Magenta
Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Magenta
Write-Host ""

# Configuration
$BASE_URL = "https://persistence-ai.github.io/Landing"
$APP_NAME = "persistenceai"
$INSTALL_DIR = "$env:USERPROFILE\.persistenceai\bin"
$TEMP_DIR = "$env:TEMP\persistenceai-install"

# Detect platform and architecture
$os = "windows"
$arch = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }

if ($arch -ne "x64") {
    Write-Error "Unsupported architecture: $arch. PersistenceAI requires x64."
    exit 1
}

$platform = "$os-$arch"
$zipName = "$APP_NAME-$platform.zip"

# Determine version
$Version = $null
if ($args.Count -gt 0) {
    $Version = $args[0]
    Write-Info "Installing version: $Version"
} else {
    Write-Info "Fetching latest version..."
    try {
        # Try to get latest version from API or releases page
        $latestResponse = Invoke-RestMethod -Uri "$BASE_URL/api/latest" -ErrorAction SilentlyContinue
        if ($latestResponse.version) {
            $Version = $latestResponse.version
        }
    } catch {
        # Fallback: try GitHub API if website API not available
        try {
            $ghResponse = Invoke-RestMethod -Uri "https://api.github.com/repos/Persistence-AI/Landing/releases/latest" -ErrorAction SilentlyContinue
            if ($ghResponse.tag_name) {
                $Version = $ghResponse.tag_name -replace '^v', ''
            }
        } catch {
            Write-Warning "Could not fetch latest version, using 'latest'"
            $Version = "latest"
        }
    }
    
    if (-not $Version) {
        $Version = "latest"
    }
    Write-Info "Latest version: $Version"
}

# Build download URL
if ($Version -eq "latest") {
    $downloadUrl = "$BASE_URL/download/$zipName"
} else {
    $downloadUrl = "$BASE_URL/download/v$Version/$zipName"
}

# Check if already installed
$existingPath = Get-Command -Name $APP_NAME -ErrorAction SilentlyContinue
if ($existingPath) {
    Write-Info "PersistenceAI is already installed at: $($existingPath.Source)"
    $currentVersion = & $existingPath.Source --version 2>&1 | Select-Object -First 1
    Write-Info "Current version: $currentVersion"
    
    if ($Version -ne "latest" -and $currentVersion -eq $Version) {
        Write-Success "Version $Version is already installed!"
        exit 0
    }
    
    Write-Info "To upgrade, run: $APP_NAME upgrade"
    $upgrade = Read-Host "Upgrade now? (y/N)"
    if ($upgrade -ne "y" -and $upgrade -ne "Y") {
        exit 0
    }
}

# Create directories
Write-Info "Creating installation directory: $INSTALL_DIR"
New-Item -ItemType Directory -Force -Path $INSTALL_DIR | Out-Null

Write-Info "Creating temporary directory: $TEMP_DIR"
if (Test-Path $TEMP_DIR) {
    Remove-Item $TEMP_DIR -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $TEMP_DIR | Out-Null

# Download
Write-Info "Downloading PersistenceAI from: $downloadUrl"
try {
    $zipPath = Join-Path $TEMP_DIR $zipName
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath -ErrorAction Stop
    Write-Success "Download completed"
} catch {
    Write-Error "Download failed: $_"
    Write-Info "Trying alternative download method..."
    
    # Fallback: Try GitHub Releases
    try {
        if ($Version -eq "latest") {
            $ghUrl = "https://github.com/Persistence-AI/Landing/releases/latest/download/persistenceai-windows-x64-v$Version.zip"
        } else {
            $ghUrl = "https://github.com/Persistence-AI/Landing/releases/download/v$Version/persistenceai-windows-x64-v$Version.zip"
        }
        Invoke-WebRequest -Uri $ghUrl -OutFile $zipPath -ErrorAction Stop
        Write-Success "Download completed from GitHub"
    } catch {
        Write-Error "All download methods failed: $_"
        Remove-Item -Path $TEMP_DIR -Recurse -Force -ErrorAction SilentlyContinue
        exit 1
    }
}

# Verify download
if (-not (Test-Path $zipPath)) {
    Write-Error "Downloaded file not found"
    Remove-Item -Path $TEMP_DIR -Recurse -Force -ErrorAction SilentlyContinue
    exit 1
}

# Extract
Write-Info "Extracting archive..."
try {
    Expand-Archive -Path $zipPath -DestinationPath $TEMP_DIR -Force
    
    # Find executable (could be in bin/ subdirectory or root)
    $exePath = Join-Path $TEMP_DIR "bin\$APP_NAME.exe"
    if (-not (Test-Path $exePath)) {
        $exePath = Join-Path $TEMP_DIR "$APP_NAME.exe"
    }
    
    if (-not (Test-Path $exePath)) {
        throw "Executable not found in archive. Contents: $((Get-ChildItem $TEMP_DIR -Recurse | Select-Object -First 10 | ForEach-Object { $_.FullName }) -join ', ')"
    }
    
    # Move to install directory
    $targetPath = Join-Path $INSTALL_DIR "$APP_NAME.exe"
    Move-Item -Path $exePath -Destination $targetPath -Force
    Write-Success "Extraction completed"
} catch {
    Write-Error "Extraction failed: $_"
    Remove-Item -Path $TEMP_DIR -Recurse -Force -ErrorAction SilentlyContinue
    exit 1
}

# Cleanup
Remove-Item -Path $TEMP_DIR -Recurse -Force -ErrorAction SilentlyContinue

# Add to PATH
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($currentPath -notlike "*$INSTALL_DIR*") {
    Write-Info "Adding PersistenceAI to PATH..."
    $newPath = "$currentPath;$INSTALL_DIR"
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    
    # Also add to current session
    $env:Path += ";$INSTALL_DIR"
    Write-Success "Added to PATH"
} else {
    Write-Info "PersistenceAI is already in PATH"
}

# Verify installation
Write-Info "Verifying installation..."
$exeFullPath = Join-Path $INSTALL_DIR "$APP_NAME.exe"
if (Test-Path $exeFullPath) {
    try {
        $versionOutput = & $exeFullPath --version 2>&1 | Select-Object -First 1
        Write-Host ""
        Write-Success "Installation successful!"
        Write-Host ""
        Write-Info "PersistenceAI version: $versionOutput"
        Write-Info "Installation location: $INSTALL_DIR"
        Write-Host ""
        Write-Warning "Note: You may need to restart PowerShell for the PATH changes to take effect."
        Write-Host ""
        Write-Info "To use PersistenceAI, open a new PowerShell window and run: $APP_NAME"
        Write-Info "For more information, visit: $BASE_URL/docs"
        Write-Host ""
    } catch {
        Write-Warning "Installation completed, but version check failed. You may need to restart PowerShell."
        Write-Info "Try running: $exeFullPath --version"
    }
} else {
    Write-Error "Installation verification failed: executable not found"
    exit 1
}
