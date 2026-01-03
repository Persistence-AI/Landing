# PersistenceAI Web Installer (PowerShell)
# This script can be downloaded and executed via:
#   iwr -useb https://persistenceai.com/install | iex
#   curl -fsSL https://persistenceai.com/install.ps1 | powershell -ExecutionPolicy Bypass -Command -

$ErrorActionPreference = "Stop"

# Enterprise-grade output functions with animations
$script:spinnerChars = @('⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏')
$script:spinnerIndex = 0
$script:spinnerJob = $null

function Show-Spinner {
    param([string]$Message)
    if ($script:spinnerJob) { Stop-Job $script:spinnerJob -ErrorAction SilentlyContinue; Remove-Job $script:spinnerJob -ErrorAction SilentlyContinue }
    
    $job = Start-Job -ScriptBlock {
        param($chars)
        $i = 0
        while ($true) {
            $char = $chars[$i % $chars.Length]
            Write-Output $char
            Start-Sleep -Milliseconds 100
            $i++
        }
    } -ArgumentList $script:spinnerChars
    
    $script:spinnerJob = $job
    Write-Host "  " -NoNewline
    Write-Host $Message -NoNewline -ForegroundColor White
    Write-Host " " -NoNewline
}

function Hide-Spinner {
    if ($script:spinnerJob) {
        Stop-Job $script:spinnerJob -ErrorAction SilentlyContinue
        Remove-Job $script:spinnerJob -ErrorAction SilentlyContinue
        $script:spinnerJob = $null
    }
    Write-Host ""
}

function Write-ProgressBar {
    param([int]$Percent, [string]$Activity, [string]$Status)
    $barLength = 30
    $filled = [math]::Floor($Percent / 100 * $barLength)
    $empty = $barLength - $filled
    
    $bar = "[" + ("#" * $filled) + ("-" * $empty) + "]"
    Write-Host "`r  " -NoNewline
    Write-Host $bar -NoNewline -ForegroundColor Cyan
    Write-Host " $Percent% " -NoNewline -ForegroundColor White
    Write-Host $Status -NoNewline -ForegroundColor Gray
}

function Write-Info { 
    param([string]$msg) 
    Write-Host "  " -NoNewline
    Write-Host "[i]" -ForegroundColor Cyan -NoNewline
    Write-Host " $msg" -ForegroundColor Gray 
}
function Write-Success { 
    param([string]$msg) 
    Write-Host "  " -NoNewline
    Write-Host "[+]" -ForegroundColor Green -NoNewline
    Write-Host " $msg" -ForegroundColor Gray 
}
function Write-Error { 
    param([string]$msg) 
    Write-Host "  " -NoNewline
    Write-Host "[x]" -ForegroundColor Red -NoNewline
    Write-Host " $msg" -ForegroundColor Gray 
}
function Write-Warning { 
    param([string]$msg) 
    Write-Host "  " -NoNewline
    Write-Host "[!]" -ForegroundColor Yellow -NoNewline
    Write-Host " $msg" -ForegroundColor Gray 
}
function Write-Step { 
    param([string]$msg) 
    Write-Host "  " -NoNewline
    Write-Host "[>]" -ForegroundColor Cyan -NoNewline
    Write-Host " $msg" -ForegroundColor White 
}

# Function to aggressively remove locked files
function Remove-LockedFile {
    param(
        [string]$FilePath,
        [string]$FileDescription = "file"
    )
    
    if (-not (Test-Path $FilePath)) {
        return $true
    }
    
    Write-Info "Attempting to remove locked $FileDescription..."
    
    # Step 1: Find and kill processes using this file (using multiple methods)
    $fileProcesses = @()
    
    # Method 1: Find by process name (pai, persistenceai)
    try {
        $nameProcesses = Get-Process | Where-Object {
            ($_.ProcessName -eq "pai") -or 
            ($_.ProcessName -eq "persistenceai") -or
            ($_.ProcessName -like "*pai*")
        } -ErrorAction SilentlyContinue
        $fileProcesses += $nameProcesses
    } catch {
        Write-Warning "Could not find processes by name: $_"
    }
    
    # Method 2: Find by executable path
    try {
        $allProcesses = Get-Process -ErrorAction SilentlyContinue
        foreach ($proc in $allProcesses) {
            try {
                if ($proc.Path -and ($proc.Path -eq $FilePath -or $proc.Path -like "*$FilePath*")) {
                    $fileProcesses += $proc
                }
            } catch {
                # Process might have exited, ignore
            }
        }
    } catch {
        Write-Warning "Could not find processes by path: $_"
    }
    
    # Method 3: Use WMI to find processes with open handles to this file (more accurate)
    try {
        $normalizedPath = $FilePath.Replace('\', '\\')
        $wmiQuery = "SELECT * FROM Win32_Process WHERE ExecutablePath = '$normalizedPath'"
        $wmiProcesses = Get-WmiObject -Query $wmiQuery -ErrorAction SilentlyContinue
        foreach ($wmiProc in $wmiProcesses) {
            try {
                $proc = Get-Process -Id $wmiProc.ProcessId -ErrorAction SilentlyContinue
                if ($proc) {
                    $fileProcesses += $proc
                }
            } catch {
                # Process might have exited
            }
        }
    } catch {
        # WMI might not be available or query might fail
    }
    
    $fileProcesses = $fileProcesses | Select-Object -Unique
    
    if ($fileProcesses) {
        Write-Info "Found $($fileProcesses.Count) process(es) that may be using the file..."
        foreach ($proc in $fileProcesses) {
            try {
                Write-Info "  Stopping process: $($proc.ProcessName) (PID: $($proc.Id))"
                # Try graceful shutdown first
                $proc.CloseMainWindow() | Out-Null
                Start-Sleep -Milliseconds 500
                # Then force kill if still running
                if (-not $proc.HasExited) {
                    Stop-Process -Id $proc.Id -Force -ErrorAction Stop
                }
            } catch {
                Write-Warning "  Could not stop process $($proc.ProcessName): $_"
            }
        }
        Start-Sleep -Seconds 3  # Wait longer for processes to fully terminate and release handles
    } else {
        Write-Info "No running processes found that are using the file"
        Write-Warning "File may be locked by:"
        Write-Warning "  - Windows Defender or antivirus (scanning the file)"
        Write-Warning "  - Windows file system cache (file handle not released)"
        Write-Warning "  - System process (explorer.exe, svchost.exe, etc.)"
        Write-Warning "  - File is in use by Windows itself"
        
        # Try to flush file system cache
        try {
            Write-Info "Attempting to flush file system cache..."
            [System.GC]::Collect()
            [System.GC]::WaitForPendingFinalizers()
        } catch {
            # Ignore
        }
    }
    
    # Step 2: Try multiple removal methods
    $methods = @(
        @{ Name = "Remove-Item"; Action = { Remove-Item -Path $FilePath -Force -ErrorAction Stop } },
        @{ Name = ".NET File.Delete"; Action = { [System.IO.File]::Delete($FilePath) } },
        @{ Name = "Remove-Item (recurse)"; Action = { Remove-Item -Path $FilePath -Force -Recurse -ErrorAction Stop } }
    )
    
    foreach ($method in $methods) {
        try {
            Write-Info "  Trying $($method.Name)..."
            & $method.Action
            Start-Sleep -Milliseconds 300
            if (-not (Test-Path $FilePath)) {
                Write-Info "  Successfully removed using $($method.Name)"
                return $true
            }
        } catch {
            Write-Info "  $($method.Name) failed: $_"
        }
    }
    
    # Step 3: Try rename approach (works even when delete doesn't)
    try {
        Write-Info "  Trying rename approach..."
        $backupName = "$(Split-Path $FilePath -Leaf).old.$(Get-Date -Format 'yyyyMMddHHmmss')"
        $backupPath = Join-Path (Split-Path $FilePath -Parent) $backupName
        Rename-Item -Path $FilePath -NewName $backupName -Force -ErrorAction Stop
        Write-Info "  Renamed file to: $backupName"
        
        # Try to delete the renamed file
        Start-Sleep -Milliseconds 500
        try {
            Remove-Item -Path $backupPath -Force -ErrorAction Stop
            Write-Info "  Successfully deleted renamed file"
        } catch {
            Write-Info "  Renamed file exists but couldn't delete: $backupPath (will be cleaned up later)"
        }
        return $true
    } catch {
        Write-Warning "  Rename approach also failed: $_"
    }
    
    # Step 4: Last resort - schedule deletion on reboot using MoveFileEx
    try {
        Write-Warning "  Scheduling file deletion on next reboot..."
        # Check if type already exists (if script runs multiple times)
        $typeName = "Win32MoveFile"
        $namespace = "Win32Functions"
        $fullTypeName = "$namespace.$typeName"
        
        if (-not ([System.Management.Automation.PSTypeName]$fullTypeName).Type) {
            $type = Add-Type -Name $typeName -Namespace $namespace -PassThru -MemberDefinition @"
[DllImport("kernel32.dll", SetLastError=true, CharSet=CharSet.Auto)]
public static extern bool MoveFileEx(string lpExistingFileName, string lpNewFileName, int dwFlags);
"@
        } else {
            $type = [Type]"$fullTypeName"
        }
        
        $MOVEFILE_DELAY_UNTIL_REBOOT = 0x4
        $result = $type::MoveFileEx($FilePath, $null, $MOVEFILE_DELAY_UNTIL_REBOOT)
        if ($result) {
            Write-Info "  File will be deleted on next reboot"
            return $true
        }
    } catch {
        Write-Warning "  Could not schedule reboot deletion: $_"
    }
    
    return $false
}

# Enterprise banner with ASCII
Write-Host ""
Write-Host "  " -NoNewline; Write-Host "========================================" -ForegroundColor Magenta
Write-Host "  " -NoNewline; Write-Host "|" -ForegroundColor Magenta -NoNewline
Write-Host "     " -NoNewline; Write-Host "PersistenceAI" -ForegroundColor Magenta -NoNewline; Write-Host " Installer" -ForegroundColor White -NoNewline; Write-Host "     " -NoNewline; Write-Host "|" -ForegroundColor Magenta
Write-Host "  " -NoNewline; Write-Host "========================================" -ForegroundColor Magenta
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
    Write-Step "Fetching latest version"
    Write-Host "  " -NoNewline; Write-Host "Checking for updates" -NoNewline -ForegroundColor White
    $dots = 0
    try {
        # Try to get latest version from API
        $fetchJob = Start-Job -ScriptBlock {
            param($url)
            try {
                $response = Invoke-RestMethod -Uri $url -ErrorAction SilentlyContinue
                return $response
            } catch {
                return $null
            }
        } -ArgumentList "$BASE_URL/api/latest.json"
        
        while ($fetchJob.State -eq 'Running') {
            $dots = ($dots + 1) % 4
            $dotStr = "." * $dots + " " * (3 - $dots)
            Write-Host "`r  Checking for updates$dotStr" -NoNewline -ForegroundColor White
            Start-Sleep -Milliseconds 200
        }
        Write-Host "`r  Checking for updates... done" -ForegroundColor White
        Write-Host ""
        
        $latestResponse = Receive-Job $fetchJob
        Remove-Job $fetchJob -Force -ErrorAction SilentlyContinue
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
            Write-Warning "Could not fetch latest version, using GitHub Releases"
            $Version = "latest"
        }
    }
    
    if (-not $Version) {
        $Version = "latest"
    }
    Write-Info "Installing version: $Version"
}

# Build download URL - direct from GitHub Releases (like OpenCode)
Write-Step "Getting download URL from GitHub Releases..."

# If version is "latest", fetch the actual version first
if ($Version -eq "latest") {
    Write-Info "Fetching latest version..."
    try {
        # Try website API first
        $latestResponse = Invoke-RestMethod -Uri "$BASE_URL/api/latest.json" -ErrorAction SilentlyContinue
        if ($latestResponse.version) {
            $Version = $latestResponse.version
        }
    } catch {
        # Fallback: try GitHub API directly
        try {
            $ghResponse = Invoke-RestMethod -Uri "https://api.github.com/repos/Persistence-AI/Landing/releases/latest" -ErrorAction SilentlyContinue
            if ($ghResponse.tag_name) {
                $Version = $ghResponse.tag_name -replace '^v', ''
            }
        } catch {
            Write-Warning "Could not fetch latest version, will try 'latest' download URL"
        }
    }
}

# Build direct GitHub Releases URL (like OpenCode)
# Query GitHub API to find the actual asset filename
Write-Step "Finding Windows x64 asset in release v$Version..."
try {
    if ($Version -eq "latest") {
        $releaseUrl = "https://api.github.com/repos/Persistence-AI/Landing/releases/latest"
    } else {
        $releaseUrl = "https://api.github.com/repos/Persistence-AI/Landing/releases/tags/v$Version"
    }
    
    $release = Invoke-RestMethod -Uri $releaseUrl -ErrorAction Stop
    
    # Update version from release tag if needed
    if ($Version -eq "latest") {
        $Version = $release.tag_name -replace '^v', ''
        Write-Info "Latest version: $Version"
    }
    
    # Find Windows x64 zip asset
    $windowsAsset = $release.assets | Where-Object { 
        ($_.name -like "*windows*x64*.zip") -or 
        ($_.name -like "*win*x64*.zip")
    } | Select-Object -First 1
    
    if ($windowsAsset) {
        $downloadUrl = $windowsAsset.browser_download_url
        Write-Info "Found asset: $($windowsAsset.name)"
    } else {
        # Fallback: try standard naming pattern
        $downloadUrl = "https://github.com/Persistence-AI/Landing/releases/download/v$Version/persistenceai-windows-x64-v$Version.zip"
        Write-Warning "Asset not found via API, trying standard URL pattern"
    }
} catch {
    # Fallback to standard URL pattern if API fails
    if ($Version -eq "latest") {
        $downloadUrl = "https://github.com/Persistence-AI/Landing/releases/latest/download/persistenceai-windows-x64.zip"
    } else {
        $downloadUrl = "https://github.com/Persistence-AI/Landing/releases/download/v$Version/persistenceai-windows-x64-v$Version.zip"
    }
    Write-Warning "Could not query GitHub API, using standard URL pattern"
}

Write-Info "Download URL: $downloadUrl"

# Check if already installed
$existingPath = Get-Command -Name $APP_NAME -ErrorAction SilentlyContinue
if ($existingPath) {
    Write-Info "PersistenceAI is already installed at: $($existingPath.Source)"
    $currentVersion = & $existingPath.Source --version 2>&1 | Select-Object -First 1
    Write-Info "Current version: $currentVersion"
    
    # Detect if running non-interactively (piped from web via iwr | iex)
    # When stdin is redirected, Read-Host will fail or hang
    $isNonInteractive = [Console]::IsInputRedirected
    
    # Handle different scenarios
    if ($currentVersion -ne $Version) {
        # Versions differ - always upgrade (user wants new version)
        Write-Info "Upgrading from $currentVersion to $Version..."
    } elseif ($isNonInteractive) {
        # Same version but non-interactive (website link) - always reinstall
        # This allows bug fixes and updates to same version to be applied
        Write-Info "Reinstalling version $Version (applying latest changes)..."
    } else {
        # Same version and interactive - ask user
        Write-Info "Version $Version is already installed."
        $reinstall = Read-Host "Reinstall anyway? (y/N)"
        if ($reinstall -ne "y" -and $reinstall -ne "Y") {
            Write-Success "Installation skipped."
            exit 0
        }
        Write-Info "Reinstalling version $Version..."
    }
    # Continue with installation (will overwrite existing binary)
}

# Create directories
Write-Step "Preparing installation directories..."
New-Item -ItemType Directory -Force -Path $INSTALL_DIR | Out-Null

if (Test-Path $TEMP_DIR) {
    Remove-Item $TEMP_DIR -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $TEMP_DIR | Out-Null

# Download with progress indication
Write-Step "Downloading PersistenceAI..."
Write-Info "Source: $downloadUrl"
$zipPath = Join-Path $TEMP_DIR $zipName
try {
    # Suppress verbose progress to avoid byte-by-byte output loop
    $ProgressPreference = 'SilentlyContinue'
    
    # Show animated status with timeout protection
    Write-Host "  " -NoNewline; Write-Host "Downloading" -NoNewline -ForegroundColor White
    $downloadJob = Start-Job -ScriptBlock {
        param($url, $outFile)
        # Suppress progress in background job
        $ProgressPreference = 'SilentlyContinue'
        try {
            # Add timeout to prevent infinite hanging
            $webClient = New-Object System.Net.WebClient
            $webClient.DownloadFile($url, $outFile)
            $webClient.Dispose()
            return @{Success=$true; Error=$null}
        } catch {
            return @{Success=$false; Error=$_.Exception.Message}
        }
    } -ArgumentList $downloadUrl, $zipPath
    
    $dots = 0
    $timeoutSeconds = 600  # 10 minute timeout
    $startTime = Get-Date
    $lastFileSize = 0
    $stallCount = 0
    
    while ($downloadJob.State -eq 'Running') {
        $elapsed = (Get-Date) - $startTime
        
        # Timeout check
        if ($elapsed.TotalSeconds -gt $timeoutSeconds) {
            Stop-Job $downloadJob -ErrorAction SilentlyContinue
            Remove-Job $downloadJob -Force -ErrorAction SilentlyContinue
            throw "Download timeout after $timeoutSeconds seconds - file may be too large or connection too slow"
        }
        
        # Check if download is making progress (detect stalls)
        if (Test-Path $zipPath) {
            $currentFileSize = (Get-Item $zipPath -ErrorAction SilentlyContinue).Length
            if ($currentFileSize -eq $lastFileSize -and $currentFileSize -gt 0) {
                $stallCount++
                # If file size hasn't changed for 2 minutes, likely stalled
                if ($stallCount -gt 40) {  # 40 * 3 seconds = 2 minutes
                    Stop-Job $downloadJob -ErrorAction SilentlyContinue
                    Remove-Job $downloadJob -Force -ErrorAction SilentlyContinue
                    throw "Download appears stalled - file size hasn't increased in 2 minutes"
                }
            } else {
                $stallCount = 0
                $lastFileSize = $currentFileSize
            }
        }
        
        $dots = ($dots + 1) % 4
        $dotStr = "." * $dots + " " * (3 - $dots)
        $sizeInfo = if (Test-Path $zipPath) { " ($([math]::Round((Get-Item $zipPath -ErrorAction SilentlyContinue).Length/1MB, 1)) MB)" } else { "" }
        Write-Host "`r  Downloading$dotStr$sizeInfo" -NoNewline -ForegroundColor White
        Start-Sleep -Milliseconds 300
    }
    
    # Wait a moment for job to finish completely
    Start-Sleep -Milliseconds 500
    
    $downloadResult = Receive-Job $downloadJob -ErrorAction SilentlyContinue
    Remove-Job $downloadJob -Force -ErrorAction SilentlyContinue
    
    if (-not $downloadResult -or -not $downloadResult.Success) {
        $errorMsg = if ($downloadResult -and $downloadResult.Error) { $downloadResult.Error } else { "Unknown error" }
        throw "Download failed: $errorMsg"
    }
    
    # Verify file was actually downloaded
    if (-not (Test-Path $zipPath)) {
        throw "Downloaded file not found at expected location"
    }
    
    $finalSize = (Get-Item $zipPath).Length
    if ($finalSize -eq 0) {
        throw "Downloaded file is empty (0 bytes)"
    }
    
    Write-Host "`r  Downloading... done" -ForegroundColor White
    Write-Host ""
    Write-Success "Download completed successfully"
} catch {
    Write-Host ""
    Write-Error "Download failed: $_"
    Write-Error "URL attempted: $downloadUrl"
    Write-Info ""
    Write-Info "Please check:"
    Write-Info "1. The version exists in GitHub Releases: https://github.com/Persistence-AI/Landing/releases"
    Write-Info "2. The file name matches: persistenceai-windows-x64-v$Version.zip (or similar)"
    Write-Info "3. Your internet connection is working"
    Remove-Item -Path $TEMP_DIR -Recurse -Force -ErrorAction SilentlyContinue
    exit 1
}

# Verify download
if (-not (Test-Path $zipPath)) {
    Write-Error "Downloaded file not found"
    Remove-Item -Path $TEMP_DIR -Recurse -Force -ErrorAction SilentlyContinue
    exit 1
}

# Extract with progress indication
Write-Step "Extracting archive..."
try {
    Write-Host "  " -NoNewline; Write-Host "Extracting files" -NoNewline -ForegroundColor White
    $dots = 0
    $extractJob = Start-Job -ScriptBlock {
        param($zipPath, $destPath)
        try {
            Expand-Archive -Path $zipPath -DestinationPath $destPath -Force
            return $true
        } catch {
            return $false
        }
    } -ArgumentList $zipPath, $TEMP_DIR

    # Show animated dots while extracting
    while ($extractJob.State -eq 'Running') {
        $dots = ($dots + 1) % 4
        $dotStr = "." * $dots + " " * (3 - $dots)
        Write-Host "`r  Extracting files$dotStr" -NoNewline -ForegroundColor White
        Start-Sleep -Milliseconds 300
    }
    
    $extractResult = Receive-Job $extractJob
    Remove-Job $extractJob -Force -ErrorAction SilentlyContinue
    
    if (-not $extractResult) {
        throw "Extraction failed"
    }
    
    Write-Host "`r  Extracting files... done" -ForegroundColor White
    Write-Host ""
    
    # Find executable (could be in bin/ subdirectory or root)
    # Try persistenceai.exe first (for backward compatibility)
    $exePath = Join-Path $TEMP_DIR "bin\$APP_NAME.exe"
    if (-not (Test-Path $exePath)) {
        $exePath = Join-Path $TEMP_DIR "$APP_NAME.exe"
    }
    
    # Also check for pai.exe (alternative command name)
    $paiExePath = Join-Path $TEMP_DIR "bin\pai.exe"
    if (-not (Test-Path $paiExePath)) {
        $paiExePath = Join-Path $TEMP_DIR "pai.exe"
    }
    
    if (-not (Test-Path $exePath) -and -not (Test-Path $paiExePath)) {
        throw "Executable not found in archive. Contents: $((Get-ChildItem $TEMP_DIR -Recurse | Select-Object -First 10 | ForEach-Object { $_.FullName }) -join ', ')"
    }
    
    # Install both commands: 'pai' and 'persistenceai'
    # Fully uninstall existing version first to ensure clean replacement
    if (Test-Path $INSTALL_DIR) {
        Write-Step "Removing existing installation..."
        
        # Try to stop any running processes that might be using the binaries
        $processes = Get-Process | Where-Object {
            ($_.Path -like "*$INSTALL_DIR\*") -or 
            ($_.ProcessName -eq "pai") -or 
            ($_.ProcessName -eq "persistenceai")
        } -ErrorAction SilentlyContinue
        
        if ($processes) {
            Write-Info "Stopping running PersistenceAI processes..."
            foreach ($proc in $processes) {
                try {
                    Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
                } catch {
                    # Ignore errors - process might have already stopped
                }
            }
            # Wait longer for processes to fully release file handles (Windows needs time)
            Write-Info "Waiting for processes to release file handles..."
            Start-Sleep -Seconds 3  # Increased from 200ms to 3 seconds
        }
        
        # Remove all files in install directory (not just .exe) using aggressive unlocking
        $allFiles = Get-ChildItem -Path $INSTALL_DIR -File -ErrorAction SilentlyContinue
        foreach ($file in $allFiles) {
            $removed = Remove-LockedFile -FilePath $file.FullName -FileDescription $file.Name
            if (-not $removed) {
                Write-Warning "Could not remove $($file.Name), will attempt overwrite"
            }
        }
        
        # Additional wait to ensure file handles are released
        Start-Sleep -Milliseconds 500
        
        Write-Success "Existing installation removed"
    }
    
    if (Test-Path $exePath) {
        $targetPath = Join-Path $INSTALL_DIR "$APP_NAME.exe"
        $sourceFileInfo = Get-Item $exePath
        $sourceHash = (Get-FileHash -Path $exePath -Algorithm SHA256).Hash
        
        # Check version of downloaded file BEFORE installing
        Write-Step "Checking version of downloaded binary..."
        try {
            $downloadedVersion = & $exePath --version 2>&1 | Select-Object -First 1
            Write-Info "Downloaded binary version: $downloadedVersion"
        } catch {
            Write-Warning "Could not check downloaded binary version: $_"
        }
        
        # Get old file info if it exists
        $oldHash = $null
        $oldVersion = $null
        $oldModTime = $null
        if (Test-Path $targetPath) {
            $oldFileInfo = Get-Item $targetPath
            $oldHash = (Get-FileHash -Path $targetPath -Algorithm SHA256 -ErrorAction SilentlyContinue).Hash
            $oldModTime = $oldFileInfo.LastWriteTime
            try {
                $oldVersion = & $targetPath --version 2>&1 | Select-Object -First 1
                Write-Info "Existing binary version: $oldVersion (modified: $oldModTime)"
            } catch {
                Write-Warning "Could not check existing binary version"
            }
        }
        
        # Remove target FIRST to ensure clean replacement (aggressive removal for locked files)
        if (Test-Path $targetPath) {
            Write-Step "Removing existing $APP_NAME.exe (unlocking if necessary)..."
            
            # Try to unlock and remove the file using aggressive method
            $removed = Remove-LockedFile -FilePath $targetPath -FileDescription "$APP_NAME.exe"
            
            if (-not $removed) {
                Write-Warning "Could not remove $APP_NAME.exe - file is locked"
                Write-Warning "The file may be in use by another process or Windows is caching it"
                Write-Info "Attempting to install anyway (may overwrite on next reboot)..."
            } else {
                Write-Success "Successfully removed existing $APP_NAME.exe"
            }
            
            # Additional wait to ensure file handles are fully released
            Start-Sleep -Seconds 1
        }
        
        # Replace file - use Move-Item for atomic replacement (like OpenCode's mv command)
        # Move-Item is more atomic than Copy-Item and can replace locked files better
        $fileReplaced = $false
        
        if (Test-Path $targetPath) {
            Write-Info "Replacing existing file (using atomic move operation)..."
            
            # Strategy 1: Try Move-Item directly (most atomic, like Unix mv)
            try {
                # Move new file to target (this atomically replaces the old file)
                Move-Item -Path $exePath -Destination $targetPath -Force -ErrorAction Stop
                Write-Success "Successfully replaced file using Move-Item (atomic operation)"
                $fileReplaced = $true
            } catch {
                Write-Warning "Move-Item failed: $_"
                Write-Info "Trying alternative strategies..."
            }
            
            # Strategy 2: If Move-Item failed, try robocopy
            if (-not $fileReplaced) {
                try {
                    Write-Info "Attempting robocopy replacement..."
                    $tempDir = Join-Path $env:TEMP "pai-replace-$(Get-Date -Format 'yyyyMMddHHmmss')"
                    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
                    $tempFile = Join-Path $tempDir (Split-Path $targetPath -Leaf)
                    Copy-Item -Path $exePath -Destination $tempFile -Force
                    
                    # Robocopy with /PURGE to delete destination files, /MOV to move (delete source)
                    $null = & robocopy $tempDir (Split-Path $targetPath -Parent) (Split-Path $targetPath -Leaf) /PURGE /MOV /R:10 /W:3 /NP /NFL /NDL /NJH /NJS 2>&1
                    $robocopyExitCode = $LASTEXITCODE
                    
                    if ($robocopyExitCode -le 7) {
                        Write-Success "Successfully replaced file using robocopy"
                        $fileReplaced = $true
                    } else {
                        Write-Warning "Robocopy exit code: $robocopyExitCode"
                    }
                    
                    Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
                } catch {
                    Write-Warning "Robocopy approach failed: $_"
                }
            }
            
            # Strategy 3: Rename old file, then move new file
            if (-not $fileReplaced) {
                try {
                    Write-Info "Attempting rename-then-move strategy..."
                    $oldFileBackup = "$targetPath.old.$(Get-Date -Format 'yyyyMMddHHmmss')"
                    Rename-Item -Path $targetPath -NewName (Split-Path $oldFileBackup -Leaf) -Force -ErrorAction Stop
                    Start-Sleep -Milliseconds 500
                    Move-Item -Path $exePath -Destination $targetPath -Force -ErrorAction Stop
                    Write-Success "Successfully replaced file using rename-then-move"
                    $fileReplaced = $true
                    
                    # Try to delete the renamed old file
                    try {
                        Remove-Item -Path (Join-Path (Split-Path $targetPath -Parent) (Split-Path $oldFileBackup -Leaf)) -Force -ErrorAction SilentlyContinue
                    } catch {
                        # Old file will be cleaned up later
                    }
                } catch {
                    Write-Warning "Rename-then-move approach failed: $_"
                }
            }
            
            # Strategy 4: Last resort - Copy-Item (least reliable for locked files)
            if (-not $fileReplaced) {
                Write-Warning "All move strategies failed, attempting Copy-Item (may not work if file is locked)..."
                Copy-Item -Path $exePath -Destination $targetPath -Force
                $fileReplaced = $true  # Assume it worked, verification will catch if it didn't
            }
        } else {
            # File doesn't exist, move new file into place
            Move-Item -Path $exePath -Destination $targetPath -Force
            $fileReplaced = $true
        }
        
        # Try to clean up the old backup file if it exists
        $oldBackups = Get-ChildItem -Path $INSTALL_DIR -Filter "$APP_NAME.exe.old.*" -ErrorAction SilentlyContinue
        foreach ($backup in $oldBackups) {
            try {
                Remove-Item -Path $backup.FullName -Force -ErrorAction SilentlyContinue
            } catch {
                # Ignore - will be cleaned up later or on reboot
            }
        }
        
        # Verify the file was actually replaced (check hash, modification time, and size)
        Start-Sleep -Seconds 1  # Give Windows time to update file system metadata
        $targetFileInfo = Get-Item $targetPath -ErrorAction Stop
        $targetHash = (Get-FileHash -Path $targetPath -Algorithm SHA256 -ErrorAction Stop).Hash
        $targetModTime = $targetFileInfo.LastWriteTime
        $targetSize = $targetFileInfo.Length
        $timeDiff = (Get-Date) - $targetModTime
        
        Write-Info "Verification:"
        Write-Info "  Target hash: $($targetHash.Substring(0, 16))..."
        Write-Info "  Target size: $([math]::Round($targetSize/1MB, 2)) MB"
        Write-Info "  Modified: $targetModTime ($([math]::Round($timeDiff.TotalMinutes, 1)) minutes ago)"
        
        if ($targetHash -eq $sourceHash) {
            Write-Success "File verified: Hash matches downloaded binary"
            if ($oldHash -and $targetHash -ne $oldHash) {
                Write-Success "File updated: Hash changed from old version"
            } elseif ($oldHash -and $targetHash -eq $oldHash) {
                Write-Warning "File hash matches old version - file may not have been updated"
            }
            
            # Critical check: modification time must be recent (within last 2 minutes)
            if ($timeDiff.TotalMinutes -gt 2) {
                Write-Warning "WARNING: File modification time is $([math]::Round($timeDiff.TotalMinutes, 1)) minutes old!"
                Write-Warning "This indicates the file was NOT updated despite hash match."
                Write-Warning "The old file is still present. Windows may be caching the file."
                Write-Info "Try:"
                Write-Info "  1. Close all PowerShell/terminal windows"
                Write-Info "  2. Restart your computer"
                Write-Info "  3. Run the installer again"
            } else {
                Write-Success "File modification time is recent - file was successfully updated"
            }
        } else {
            Write-Warning "File verification FAILED - hash mismatch!"
            Write-Warning "Source hash: $($sourceHash.Substring(0, 16))..."
            Write-Warning "Target hash: $($targetHash.Substring(0, 16))..."
            Write-Warning "Source size: $([math]::Round($sourceFileInfo.Length/1MB, 2)) MB"
            Write-Warning "Target size: $([math]::Round($targetSize/1MB, 2)) MB"
            Write-Warning "The file was NOT properly replaced!"
        }
    }
    
    if (Test-Path $paiExePath) {
        $paiTargetPath = Join-Path $INSTALL_DIR "pai.exe"
        $sourcePaiInfo = Get-Item $paiExePath
        $sourcePaiHash = (Get-FileHash -Path $paiExePath -Algorithm SHA256).Hash
        
        # Get old file hash if it exists
        $oldPaiHash = $null
        if (Test-Path $paiTargetPath) {
            $oldPaiHash = (Get-FileHash -Path $paiTargetPath -Algorithm SHA256 -ErrorAction SilentlyContinue).Hash
        }
        
        # Remove target FIRST to ensure clean replacement (aggressive removal for locked files)
        if (Test-Path $paiTargetPath) {
            Write-Step "Removing existing pai.exe (unlocking if necessary)..."
            
            # Try to unlock and remove the file using aggressive method
            $removed = Remove-LockedFile -FilePath $paiTargetPath -FileDescription "pai.exe"
            
            if (-not $removed) {
                Write-Warning "Could not remove pai.exe - file is locked"
                Write-Warning "The file may be in use by another process or Windows is caching it"
                Write-Info "Attempting to install anyway (may overwrite on next reboot)..."
            } else {
                Write-Success "Successfully removed existing pai.exe"
            }
            
            # Additional wait to ensure file handles are fully released
            Start-Sleep -Seconds 1
        }
        
        # Replace file - use Move-Item for atomic replacement (like OpenCode's mv command)
        $paiFileReplaced = $false
        
        if (Test-Path $paiTargetPath) {
            Write-Info "Replacing existing pai.exe (using atomic move operation)..."
            
            # Strategy 1: Try Move-Item directly (most atomic)
            try {
                Move-Item -Path $paiExePath -Destination $paiTargetPath -Force -ErrorAction Stop
                Write-Success "Successfully replaced pai.exe using Move-Item"
                $paiFileReplaced = $true
            } catch {
                Write-Warning "Move-Item failed: $_"
            }
            
            # Strategy 2: Robocopy
            if (-not $paiFileReplaced) {
                try {
                    $tempDir = Join-Path $env:TEMP "pai-replace-$(Get-Date -Format 'yyyyMMddHHmmss')"
                    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
                    $tempFile = Join-Path $tempDir (Split-Path $paiTargetPath -Leaf)
                    Copy-Item -Path $paiExePath -Destination $tempFile -Force
                    
                    $null = & robocopy $tempDir (Split-Path $paiTargetPath -Parent) (Split-Path $paiTargetPath -Leaf) /PURGE /MOV /R:10 /W:3 /NP /NFL /NDL /NJH /NJS 2>&1
                    if ($LASTEXITCODE -le 7) {
                        Write-Success "Successfully replaced pai.exe using robocopy"
                        $paiFileReplaced = $true
                    }
                    Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
                } catch {
                    Write-Warning "Robocopy approach failed: $_"
                }
            }
            
            # Strategy 3: Rename-then-move
            if (-not $paiFileReplaced) {
                try {
                    $oldFileBackup = "$paiTargetPath.old.$(Get-Date -Format 'yyyyMMddHHmmss')"
                    Rename-Item -Path $paiTargetPath -NewName (Split-Path $oldFileBackup -Leaf) -Force -ErrorAction Stop
                    Start-Sleep -Milliseconds 500
                    Move-Item -Path $paiExePath -Destination $paiTargetPath -Force -ErrorAction Stop
                    Write-Success "Successfully replaced pai.exe using rename-then-move"
                    $paiFileReplaced = $true
                } catch {
                    Write-Warning "Rename-then-move approach failed: $_"
                    Copy-Item -Path $paiExePath -Destination $paiTargetPath -Force
                }
            }
        } else {
            Move-Item -Path $paiExePath -Destination $paiTargetPath -Force
            $paiFileReplaced = $true
        }
        
        # Try to clean up the old backup file if it exists
        $oldBackups = Get-ChildItem -Path $INSTALL_DIR -Filter "pai.exe.old.*" -ErrorAction SilentlyContinue
        foreach ($backup in $oldBackups) {
            try {
                Remove-Item -Path $backup.FullName -Force -ErrorAction SilentlyContinue
            } catch {
                # Ignore - will be cleaned up later or on reboot
            }
        }
        
        # Verify the file was actually replaced (check hash and modification time)
        Start-Sleep -Milliseconds 300  # Ensure file system has updated
        $targetPaiInfo = Get-Item $paiTargetPath
        $targetPaiHash = (Get-FileHash -Path $paiTargetPath -Algorithm SHA256).Hash
        $targetPaiModTime = $targetPaiInfo.LastWriteTime
        
        if ($targetPaiInfo.Length -eq $sourcePaiInfo.Length -and $targetPaiHash -eq $sourcePaiHash) {
            if ($oldPaiHash -and $targetPaiHash -eq $oldPaiHash) {
                Write-Warning "WARNING: pai.exe hash matches old version - binary was NOT updated!"
                Write-Warning "File modification time: $targetPaiModTime"
                Write-Info "This usually means the file is locked. Try closing all terminals and reinstalling."
            } else {
                Write-Success "Installed 'pai' command ($([math]::Round($targetPaiInfo.Length/1MB, 2)) MB)"
                Write-Info "File updated at: $targetPaiModTime"
                
                # Verify modification time is recent (within last 5 minutes)
                $timeDiff = (Get-Date) - $targetPaiModTime
                if ($timeDiff.TotalMinutes -gt 5) {
                    Write-Warning "WARNING: File modification time is $([math]::Round($timeDiff.TotalMinutes, 1)) minutes old!"
                    Write-Warning "This indicates the file was NOT updated. The old file is still present."
                }
            }
        } else {
            Write-Warning "File verification failed for pai.exe - size or hash mismatch"
            Write-Info "Source size: $($sourcePaiInfo.Length) bytes, Target size: $($targetPaiInfo.Length) bytes"
        }
    } elseif (Test-Path $exePath) {
        # If only persistenceai.exe exists, create pai.exe as a copy
        $paiTargetPath = Join-Path $INSTALL_DIR "pai.exe"
        
        # Remove target FIRST if it exists (aggressive removal)
        if (Test-Path $paiTargetPath) {
            Write-Step "Removing existing pai.exe (unlocking if necessary)..."
            
            # Try to unlock and remove the file using aggressive method
            $removed = Remove-LockedFile -FilePath $paiTargetPath -FileDescription "pai.exe"
            
            if (-not $removed) {
                Write-Warning "Could not remove pai.exe - file is locked"
            } else {
                Write-Success "Successfully removed existing pai.exe"
            }
            
            Start-Sleep -Seconds 1
        }
        
        Copy-Item -Path $exePath -Destination $paiTargetPath -Force
        Write-Success "Installed 'pai' command (created from persistenceai.exe)"
    }
    
    # Verify installed binary is production and matches expected version
    if (Test-Path $targetPath) {
        try {
            $installedVersion = & $targetPath --version 2>&1 | Select-Object -First 1
            if ($installedVersion -match "0\.0\.0-local") {
                Write-Warning "Installed binary appears to be DEV version (0.0.0-local-*)"
                Write-Warning "This should not happen with production ZIP. Please report this issue."
            } elseif ($installedVersion -match "1\.\d+\.\d+") {
                # Check if version matches what we downloaded
                if ($Version -and $installedVersion -like "*$Version*") {
                    Write-Success "Verified installed binary version: $installedVersion (matches expected: $Version)"
                } else {
                    Write-Success "Verified installed binary version: $installedVersion"
                    if ($Version) {
                        Write-Info "Expected version: $Version (version may differ if using 'latest')"
                    }
                }
            } else {
                Write-Warning "Installed binary version format unexpected: $installedVersion"
            }
        } catch {
            Write-Warning "Could not verify installed binary version: $_"
        }
    }
    
    # Also verify pai.exe if it exists
    if (Test-Path $paiTargetPath) {
        try {
            $paiVersion = & $paiTargetPath --version 2>&1 | Select-Object -First 1
            Write-Info "Verified pai.exe version: $paiVersion"
        } catch {
            # Ignore - pai.exe might be a copy
        }
    }
    
    Write-Success "Extraction completed - both 'pai' and 'persistenceai' commands available"
} catch {
    Write-Error "Extraction failed: $_"
    Remove-Item -Path $TEMP_DIR -Recurse -Force -ErrorAction SilentlyContinue
    exit 1
}

# Cleanup
Remove-Item -Path $TEMP_DIR -Recurse -Force -ErrorAction SilentlyContinue

# Add to PATH (prepend to ensure our executables are found first)
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($currentPath -notlike "*$INSTALL_DIR*") {
    Write-Step "Adding PersistenceAI to PATH..."
    # Prepend to PATH to ensure our executables take precedence over npm/other tools
    $newPath = "$INSTALL_DIR;$currentPath"
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    
    # Also add to current session (prepend)
    $env:Path = "$INSTALL_DIR;$env:Path"
    Write-Success "PATH updated successfully (prepended for priority)"
} else {
    Write-Info "Already in PATH"
    # Ensure it's at the beginning even if already there
    $pathParts = $currentPath -split ';'
    if ($pathParts[0] -ne $INSTALL_DIR) {
        $pathParts = $pathParts | Where-Object { $_ -ne $INSTALL_DIR }
        $newPath = "$INSTALL_DIR;" + ($pathParts -join ';')
        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
        $env:Path = "$INSTALL_DIR;$env:Path"
        Write-Info "Moved PersistenceAI to beginning of PATH for priority"
    }
}

# Verify installation
Write-Step "Verifying installation..."
$exeFullPath = Join-Path $INSTALL_DIR "$APP_NAME.exe"
$paiExeFullPath = Join-Path $INSTALL_DIR "pai.exe"

# Verify both executables exist
if (-not (Test-Path $exeFullPath)) {
    Write-Error "Installation verification failed: persistenceai.exe not found"
    exit 1
}

if (-not (Test-Path $paiExeFullPath)) {
    Write-Error "Installation verification failed: pai.exe not found"
    exit 1
}

try {
    # Check if there are other pai installations in PATH that might take precedence
    $allPaiCommands = Get-Command -Name "pai" -All -ErrorAction SilentlyContinue
    $ourPaiPath = $paiExeFullPath
    $otherPaiPaths = $allPaiCommands | Where-Object { $_.Source -ne $ourPaiPath }
    
    if ($otherPaiPaths) {
        Write-Warning "Found other 'pai' installations in PATH that may take precedence:"
        foreach ($other in $otherPaiPaths) {
            Write-Info "  - $($other.Source)"
        }
        Write-Info "Our installation is at: $ourPaiPath"
        Write-Info "Make sure our PATH entry comes first (it should after restarting PowerShell)"
    }
    
    # Check which binary is actually being executed
    Write-Step "Verifying installed binaries..."
    $actualPaiCmd = Get-Command -Name "pai" -ErrorAction SilentlyContinue
    $actualPersistenceaiCmd = Get-Command -Name "persistenceai" -ErrorAction SilentlyContinue
    
    if ($actualPaiCmd) {
        Write-Info "Command 'pai' resolves to: $($actualPaiCmd.Source)"
        if ($actualPaiCmd.Source -ne $paiExeFullPath) {
            Write-Warning "WARNING: 'pai' command is NOT using our installed binary!"
            Write-Warning "Expected: $paiExeFullPath"
            Write-Warning "Actual: $($actualPaiCmd.Source)"
        }
    }
    
    if ($actualPersistenceaiCmd) {
        Write-Info "Command 'persistenceai' resolves to: $($actualPersistenceaiCmd.Source)"
        if ($actualPersistenceaiCmd.Source -ne $exeFullPath) {
            Write-Warning "WARNING: 'persistenceai' command is NOT using our installed binary!"
            Write-Warning "Expected: $exeFullPath"
            Write-Warning "Actual: $($actualPersistenceaiCmd.Source)"
        }
    }
    
    # Check file info of installed binaries
    if (Test-Path $exeFullPath) {
        $installedFileInfo = Get-Item $exeFullPath
        Write-Info "Installed persistenceai.exe:"
        Write-Info "  Location: $exeFullPath"
        Write-Info "  Size: $([math]::Round($installedFileInfo.Length/1MB, 2)) MB"
        Write-Info "  Modified: $($installedFileInfo.LastWriteTime)"
    }
    
    if (Test-Path $paiExeFullPath) {
        $installedPaiFileInfo = Get-Item $paiExeFullPath
        Write-Info "Installed pai.exe:"
        Write-Info "  Location: $paiExeFullPath"
        Write-Info "  Size: $([math]::Round($installedPaiFileInfo.Length/1MB, 2)) MB"
        Write-Info "  Modified: $($installedPaiFileInfo.LastWriteTime)"
    }
    
    $versionOutput = & $exeFullPath --version 2>&1 | Select-Object -First 1
    
    # Verify version matches what we downloaded
    if ($Version -and $versionOutput -notlike "*$Version*") {
        Write-Warning "Installed version ($versionOutput) does not match expected version ($Version)"
        Write-Info "The binary may not have been updated correctly"
        Write-Info "This could indicate:"
        Write-Info "  1. The file is locked and wasn't replaced"
        Write-Info "  2. Windows is caching the old executable"
        Write-Info "  3. A different binary is being executed (check PATH above)"
    }
    
    # Verify both commands work
    $paiVersionOutput = & $paiExeFullPath --version 2>&1 | Select-Object -First 1
    
    Write-Host ""
    Write-Host "  " -NoNewline; Write-Host "================================" -ForegroundColor DarkGray
    Write-Host "  " -NoNewline; Write-Host "Installation Complete!" -ForegroundColor Green
    Write-Host "  " -NoNewline; Write-Host "================================" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  " -NoNewline; Write-Host "Version:" -ForegroundColor Cyan -NoNewline; Write-Host " $versionOutput" -ForegroundColor White
    if ($paiVersionOutput -and $paiVersionOutput -ne $versionOutput) {
        Write-Host "  " -NoNewline; Write-Host "pai version:" -ForegroundColor Cyan -NoNewline; Write-Host " $paiVersionOutput" -ForegroundColor White
    }
    Write-Host "  " -NoNewline; Write-Host "Location:" -ForegroundColor Cyan -NoNewline; Write-Host " $INSTALL_DIR" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  " -NoNewline; Write-Host "Installed Commands:" -ForegroundColor Magenta
    Write-Host "  " -NoNewline; Write-Host "  persistenceai" -ForegroundColor White -NoNewline; Write-Host " - Run PersistenceAI" -ForegroundColor Gray
    Write-Host "  " -NoNewline; Write-Host "  pai" -ForegroundColor White -NoNewline; Write-Host " - Run PersistenceAI (short alias)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  " -NoNewline; Write-Host "Quick Start:" -ForegroundColor Magenta
    Write-Host "  " -NoNewline; Write-Host "  $APP_NAME" -ForegroundColor White -NoNewline; Write-Host " or " -ForegroundColor Gray -NoNewline; Write-Host "pai" -ForegroundColor White -NoNewline; Write-Host " - Launch PersistenceAI" -ForegroundColor Gray
    Write-Host "  " -NoNewline; Write-Host "  $APP_NAME --help" -ForegroundColor White -NoNewline; Write-Host " or " -ForegroundColor Gray -NoNewline; Write-Host "pai --help" -ForegroundColor White -NoNewline; Write-Host " - Show help" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  " -NoNewline; Write-Host "Note:" -ForegroundColor Yellow -NoNewline; Write-Host " Restart PowerShell for PATH changes to take effect" -ForegroundColor Gray
    Write-Host "  " -NoNewline; Write-Host "Docs:" -ForegroundColor Cyan -NoNewline; Write-Host " $BASE_URL/docs" -ForegroundColor Gray
    Write-Host ""
} catch {
    Write-Warning "Installation completed, but version check failed. You may need to restart PowerShell."
    Write-Info "Try running: $exeFullPath --version or $paiExeFullPath --version"
}

# Final diagnostic summary
Write-Host ""
Write-Host "  " -NoNewline; Write-Host "========================================" -ForegroundColor DarkGray
Write-Host "  " -NoNewline; Write-Host "Diagnostic Information" -ForegroundColor Cyan
Write-Host "  " -NoNewline; Write-Host "========================================" -ForegroundColor DarkGray
Write-Host ""
Write-Info "If you're seeing an older version after installation, check:"
Write-Info "  1. Restart PowerShell - PATH changes require a new session"
Write-Info "  2. Close all terminals - file locks prevent updates"
Write-Info "  3. Check which binary is executed: Get-Command pai | Select-Object Source"
Write-Info "  4. Verify file was updated: (Get-Item '$exeFullPath').LastWriteTime"
Write-Info "  5. Check for multiple installations: Get-Command pai -All"
Write-Host ""
