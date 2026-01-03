# PersistenceAI Uninstaller (PowerShell)
# This script can be downloaded and executed via:
#   iwr -useb https://persistence-ai.github.io/Landing/uninstall.ps1 | iex
#   curl -fsSL https://persistence-ai.github.io/Landing/uninstall.ps1 | powershell -ExecutionPolicy Bypass -Command -

$ErrorActionPreference = "Continue"

# ============================================================================
# Output Functions (Matching install.ps1 style)
# ============================================================================

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

# ============================================================================
# Banner
# ============================================================================

Write-Host ""
Write-Host "  " -NoNewline; Write-Host "========================================" -ForegroundColor Magenta
Write-Host "  " -NoNewline; Write-Host "|" -ForegroundColor Magenta -NoNewline
Write-Host "    " -NoNewline; Write-Host "PersistenceAI" -ForegroundColor Magenta -NoNewline; Write-Host " Uninstaller" -ForegroundColor White -NoNewline; Write-Host "    " -NoNewline; Write-Host "|" -ForegroundColor Magenta
Write-Host "  " -NoNewline; Write-Host "========================================" -ForegroundColor Magenta
Write-Host ""

# ============================================================================
# Windows API for MoveFileEx (Delete on Reboot)
# ============================================================================

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("kernel32.dll", SetLastError=true, CharSet=CharSet.Auto)]
    public static extern bool MoveFileEx(string lpExistingFileName, string lpNewFileName, int dwFlags);
    public const int MOVEFILE_DELAY_UNTIL_REBOOT = 0x4;
}
"@

function Register-ForDeletionOnReboot {
    param([string]$FilePath)
    try {
        if (Test-Path $FilePath) {
            $result = [Win32]::MoveFileEx($FilePath, $null, [Win32]::MOVEFILE_DELAY_UNTIL_REBOOT)
            if ($result) {
                Write-Info "Marked for deletion on reboot: $FilePath"
                return $true
            }
        }
    } catch {
        # Silently fail - not critical
    }
    return $false
}

# ============================================================================
# Process Termination (Aggressive - handles file locks)
# ============================================================================

function Stop-PersistenceAIProcesses {
    Write-Step "Terminating PersistenceAI processes..."
    
    # Find processes by name
    $processes = Get-Process | Where-Object {
        ($_.ProcessName -eq "pai") -or 
        ($_.ProcessName -eq "persistenceai") -or
        ($_.ProcessName -like "*persistenceai*")
    } -ErrorAction SilentlyContinue
    
    if ($processes) {
        Write-Info "Found $($processes.Count) process(es) to terminate"
        foreach ($proc in $processes) {
            try {
                Write-Info "Terminating process: $($proc.ProcessName) (PID: $($proc.Id))"
                # Use taskkill with /T to kill process tree (child processes)
                $result = Start-Process -FilePath "taskkill" -ArgumentList "/F", "/T", "/PID", $proc.Id -Wait -NoNewWindow -PassThru -ErrorAction SilentlyContinue
                if ($result -and $result.ExitCode -eq 0) {
                    Write-Success "Terminated process tree: $($proc.ProcessName)"
                } else {
                    # Fallback to Stop-Process
                    Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
                }
            } catch {
                Write-Warning "Error terminating process: $_"
            }
        }
    } else {
        Write-Info "No PersistenceAI processes found"
    }
    
    # Wait for processes to fully terminate
    Start-Sleep -Seconds 3
}

# ============================================================================
# File/Directory Removal with Retry and Reboot Marking
# ============================================================================

function Remove-ItemWithRetry {
    param(
        [string]$Path,
        [int]$MaxRetries = 3,
        [int]$DelaySeconds = 2
    )
    
    if (-not (Test-Path $Path)) {
        return $true
    }
    
    for ($i = 1; $i -le $MaxRetries; $i++) {
        try {
            if (Test-Path $Path -PathType Container) {
                Remove-Item -Path $Path -Recurse -Force -ErrorAction Stop
            } else {
                Remove-Item -Path $Path -Force -ErrorAction Stop
            }
            Write-Success "Removed: $Path"
            return $true
        } catch {
            if ($i -lt $MaxRetries) {
                Write-Warning "Attempt $i failed, retrying in $DelaySeconds seconds..."
                Start-Sleep -Seconds $DelaySeconds
            } else {
                Write-Warning "Failed to remove after $MaxRetries attempts: $Path"
                Write-Info "Marking for deletion on reboot..."
                if (Test-Path $Path -PathType Container) {
                    # For directories, mark all files inside
                    Get-ChildItem -Path $Path -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
                        Register-ForDeletionOnReboot $_.FullName
                    }
                    Register-ForDeletionOnReboot $Path
                } else {
                    Register-ForDeletionOnReboot $Path
                }
                return $false
            }
        }
    }
    return $false
}

# ============================================================================
# Main Uninstall Logic
# ============================================================================

Write-Step "Starting uninstall of PersistenceAI..."

# Step 1: Stop all processes (aggressive termination)
Stop-PersistenceAIProcesses

# Step 2: Find all installation directories
Write-Step "Locating installation directories..."

$dirsToRemove = @(
    "$env:USERPROFILE\.persistenceai",
    "$env:USERPROFILE\.pai",
    "$env:USERPROFILE\.config\persistenceai",
    "$env:USERPROFILE\.config\pai",
    "$env:LOCALAPPDATA\persistenceai",
    "$env:LOCALAPPDATA\pai"
)

# Also find installation directories from PATH
$paiCmd = Get-Command -Name "pai" -ErrorAction SilentlyContinue
$persistenceaiCmd = Get-Command -Name "persistenceai" -ErrorAction SilentlyContinue

if ($paiCmd) {
    $binDir = Split-Path $paiCmd.Source -Parent
    $installDir = Split-Path $binDir -Parent
    if ($installDir -and $installDir -notin $dirsToRemove) {
        $dirsToRemove += $installDir
    }
    # Also add the bin directory itself
    if ($binDir -and $binDir -notin $dirsToRemove) {
        $dirsToRemove += $binDir
    }
}

if ($persistenceaiCmd) {
    $binDir = Split-Path $persistenceaiCmd.Source -Parent
    $installDir = Split-Path $binDir -Parent
    if ($installDir -and $installDir -notin $dirsToRemove) {
        $dirsToRemove += $installDir
    }
    # Also add the bin directory itself
    if ($binDir -and $binDir -notin $dirsToRemove) {
        $dirsToRemove += $binDir
    }
}

# Remove duplicates
$dirsToRemove = $dirsToRemove | Select-Object -Unique

# Step 3: Remove directories with retry logic
Write-Step "Removing installation directories..."

$removedCount = 0
$markedForReboot = 0

foreach ($dir in $dirsToRemove) {
    if (Test-Path $dir) {
        Write-Info "Removing: $dir"
        if (Remove-ItemWithRetry -Path $dir) {
            $removedCount++
        } else {
            $markedForReboot++
        }
    }
}

# Step 4: Clean PATH
Write-Step "Cleaning PATH environment variable..."

$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath) {
    $newUserPath = ($userPath -split ";" | Where-Object { 
        $_ -and $_ -notmatch "\.persistenceai" -and $_ -notmatch "\.pai" 
    }) -join ";"
    [Environment]::SetEnvironmentVariable("Path", $newUserPath, "User")
    Write-Success "Cleaned user PATH"
}

# Update current session PATH
$env:Path = ($env:Path -split ";" | Where-Object { 
    $_ -and $_ -notmatch "\.persistenceai" -and $_ -notmatch "\.pai" 
}) -join ";"

# Step 5: Summary
Write-Host ""
Write-Host "  " -NoNewline; Write-Host "================================" -ForegroundColor DarkGray
if ($markedForReboot -gt 0) {
    Write-Warning "Some files could not be removed and were marked for deletion on reboot"
    Write-Info "Please restart your computer to complete the uninstallation"
    Write-Info "Removed $removedCount directory/directories"
    Write-Info "$markedForReboot item(s) marked for deletion on reboot"
} else {
    Write-Success "PersistenceAI uninstalled successfully"
    Write-Info "Removed $removedCount directory/directories"
}
Write-Host "  " -NoNewline; Write-Host "================================" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  " -NoNewline; Write-Host "Note:" -ForegroundColor Yellow -NoNewline; Write-Host " Restart PowerShell for PATH changes to take effect" -ForegroundColor Gray
Write-Host ""
