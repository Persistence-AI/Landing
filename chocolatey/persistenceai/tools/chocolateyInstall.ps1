$ErrorActionPreference = 'Stop'

$packageName = 'persistenceai'
$toolsDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$version = '1.0.14'
$url = "https://github.com/Persistence-AI/Landing/releases/download/v$version/persistenceai-windows-x64-v$version.zip"
$checksum = ''
$checksumType = 'sha256'

# Create temp directory
$tempDir = Join-Path $env:TEMP "chocolatey-$packageName-$([guid]::NewGuid().ToString('N').Substring(0,8))"
New-Item -ItemType Directory -Force -Path $tempDir | Out-Null

try {
    # Download
    Write-Host "Downloading PersistenceAI v$version..."
    $zipFile = Join-Path $tempDir "persistenceai.zip"
    Invoke-WebRequest -Uri $url -OutFile $zipFile -UseBasicParsing

    # Verify checksum if provided
    if ($checksum) {
        $fileHash = Get-FileHash -Path $zipFile -Algorithm $checksumType
        if ($fileHash.Hash -ne $checksum) {
            throw "Checksum verification failed. Expected $checksum but got $($fileHash.Hash)"
        }
    }

    # Extract
    Write-Host "Extracting archive..."
    Expand-Archive -Path $zipFile -DestinationPath $tempDir -Force

    # Find executable
    $exePath = Get-ChildItem -Path $tempDir -Filter "persistenceai.exe" -Recurse | Select-Object -First 1
    if (-not $exePath) {
        $exePath = Get-ChildItem -Path $tempDir -Filter "pai.exe" -Recurse | Select-Object -First 1
    }

    if (-not $exePath) {
        throw "Executable not found in archive"
    }

    # Install to Chocolatey bin directory
    $binDir = Join-Path $toolsDir "..\..\bin"
    New-Item -ItemType Directory -Force -Path $binDir | Out-Null
    
    $targetPath = Join-Path $binDir "persistenceai.exe"
    Copy-Item $exePath.FullName -Destination $targetPath -Force

    Write-Host "PersistenceAI installed successfully to $targetPath"
    Write-Host "Add $binDir to your PATH to use 'persistenceai' command"
}
finally {
    # Cleanup
    Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
}
