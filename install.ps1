<#
.SYNOPSIS
  Automated installer for Lako Configuration Platform on Windows.
.DESCRIPTION
  Downloads the latest release from GitHub Releases (Rommel96/lako-config),
  installs it into %LOCALAPPDATA%\Programs\Lako, adds it to User PATH, and optionally
  configures the background service (Production Mode).
#>

[CmdletBinding()]
param (
    [string]$Version = "latest",
    [string]$InstallDir = "$env:LOCALAPPDATA\Programs\Lako",
    [switch]$StartNow,
    [switch]$RegisterService
)

$ErrorActionPreference = "Stop"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   Lako Configuration Platform Installer (Windows)        " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

$Repo = "Rommel96/lako-releases"
$Arch = if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") { "arm64" } else { "amd64" }
$AssetPattern = "*windows-$Arch.zip"

Write-Host "-> Detected Architecture: Windows $Arch" -ForegroundColor Gray
Write-Host "-> Target Installation Directory: $InstallDir" -ForegroundColor Gray

$TempDir = Join-Path $env:TEMP ("lako-install-" + [System.Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
$ZipPath = Join-Path $TempDir "lako-windows.zip"

try {
    # 1. Direct download from GitHub Releases (no gh CLI or token required)
    $Downloaded = $false
    $Tag = if ($Version -eq "latest") { "v1.0.0" } elseif ($Version.StartsWith("v")) { $Version } else { "v$Version" }
    $DownloadUrl = if ($Version -eq "latest") {
        "https://github.com/$Repo/releases/latest/download/lako-$Tag-windows-$Arch.zip"
    } else {
        "https://github.com/$Repo/releases/download/$Tag/lako-$Tag-windows-$Arch.zip"
    }

    Write-Host "-> Downloading Lako for Windows $Arch from GitHub Releases..." -ForegroundColor Yellow
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipPath -UseBasicParsing -ErrorAction Stop
        if ((Test-Path $ZipPath) -and (Get-Item $ZipPath).Length -gt 1000) {
            $Downloaded = $true
        }
    } catch {
        Write-Host "   (Direct download unavailable, trying fallback methods...)" -ForegroundColor Gray
    }

    # 2. Fallback: GitHub CLI (gh) if installed
    if (-not $Downloaded -and (Get-Command gh -ErrorAction SilentlyContinue)) {
        Write-Host "-> Downloading using GitHub CLI (gh)..." -ForegroundColor Yellow
        $ghArgs = @("release", "download", "--repo", $Repo, "--pattern", $AssetPattern, "--dir", $TempDir, "--clobber")
        if ($Version -ne "latest") {
            $ghArgs += $Version
        }
        & gh @ghArgs 2>$null
        $MatchedZip = Get-ChildItem -Path $TempDir -Filter "*.zip" | Select-Object -First 1
        if ($MatchedZip) {
            $ZipPath = $MatchedZip.FullName
            $Downloaded = $true
        }
    }

    # 3. Fallback: GitHub API with Token
    if (-not $Downloaded) {
        $Token = $env:GH_TOKEN
        if (-not $Token) { $Token = $env:GITHUB_TOKEN }
        if ($Token) {
            Write-Host "-> Downloading via GitHub API with authentication..." -ForegroundColor Yellow
            $ApiUrl = if ($Version -eq "latest") {
                "https://api.github.com/repos/$Repo/releases/latest"
            } else {
                "https://api.github.com/repos/$Repo/releases/tags/$Version"
            }
            $Headers = @{
                "Authorization" = "Bearer $Token"
                "Accept" = "application/vnd.github.v3+json"
                "User-Agent" = "Lako-Installer"
            }
            $Release = Invoke-RestMethod -Uri $ApiUrl -Headers $Headers
            $Asset = $Release.assets | Where-Object { $_.name -like $AssetPattern } | Select-Object -First 1
            if ($Asset) {
                $DownloadHeaders = @{
                    "Authorization" = "Bearer $Token"
                    "Accept" = "application/octet-stream"
                    "User-Agent" = "Lako-Installer"
                }
                Invoke-WebRequest -Uri $Asset.url -Headers $DownloadHeaders -OutFile $ZipPath -UseBasicParsing
                $Downloaded = $true
            }
        }
    }

    if (-not $Downloaded) {
        throw "Failed to download Lako release. Please check your internet connection or visit https://github.com/$Repo/releases."
    }

    # 3. Extract and Install
    Write-Host "-> Installing to $InstallDir ..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null

    Expand-Archive -Path $ZipPath -DestinationPath $TempDir -Force

    # If extracted into a subdirectory (lako-v*-windows-*), move files up
    $InnerDir = Get-ChildItem -Path $TempDir -Directory | Where-Object { $_.Name -like "lako-*" } | Select-Object -First 1
    $SourceDir = if ($InnerDir) { $InnerDir.FullName } else { $TempDir }

    Copy-Item -Path "$SourceDir\*" -Destination $InstallDir -Recurse -Force

    # 4. Add to User PATH
    $UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($UserPath -notlike "*$InstallDir*") {
        Write-Host "-> Adding $InstallDir to User PATH..." -ForegroundColor Yellow
        $NewPath = if ($UserPath.EndsWith(";")) { "$UserPath$InstallDir" } else { "$UserPath;$InstallDir" }
        [Environment]::SetEnvironmentVariable("Path", $NewPath, "User")
        $env:Path += ";$InstallDir"
    }

    # 5. Optional Production Mode: Register background service / scheduled task
    if ($RegisterService -or (Test-Path "$InstallDir\install-service.ps1")) {
        Write-Host ""
        Write-Host "Would you like to enable permanent PRODUCTION MODE? (Starts Lako in background on Windows logon)" -ForegroundColor Cyan
        $EnableService = if ($RegisterService) { "Y" } else { Read-Host "Enable background service on logon? (Y/N) [Default: Y]" }
        if ($EnableService -ne "N" -and $EnableService -ne "n") {
            try {
                & "$InstallDir\install-service.ps1"
            } catch {
                Write-Host "Warning: Could not register scheduled task: $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }
    }

    Write-Host ""
    Write-Host "==========================================================" -ForegroundColor Green
    Write-Host "  ✅ Lako Configuration Platform installed successfully! " -ForegroundColor Green
    Write-Host "==========================================================" -ForegroundColor Green
    Write-Host "Available commands:" -ForegroundColor Gray
    Write-Host "  lako version              Check installed version" -ForegroundColor Gray
    Write-Host "  lako doctor               Diagnose detected runtimes" -ForegroundColor Gray
    Write-Host "  lako ui --port 8080       Launch local UI server" -ForegroundColor Gray
    Write-Host "  start.bat                 1-Click launcher in $InstallDir" -ForegroundColor Gray
    Write-Host ""

    # 6. Start now if requested
    if ($StartNow) {
        Write-Host "Starting Lako..." -ForegroundColor Cyan
        Start-Process "http://127.0.0.1:8080/"
        & "$InstallDir\lako.exe" ui --port 8080
    } else {
        $RunNow = Read-Host "Would you like to launch the Lako UI now? (Y/N) [Default: Y]"
        if ($RunNow -ne "N" -and $RunNow -ne "n") {
            Start-Process "http://127.0.0.1:8080/"
            & "$InstallDir\lako.exe" ui --port 8080
        }
    }

} finally {
    Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
}
