#Requires -Version 5.1
<#
.SYNOPSIS
    One-click installer for the Aptly MCP server for Claude Desktop.
.DESCRIPTION
    Downloads the Aptly MCP server from GitHub, installs dependencies,
    and configures Claude Desktop. The API key should be passed via
    the APTLY_KEY environment variable (set by the Teams one-liner).
#>

param(
    [string]$ApiKey = $env:APTLY_KEY
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repo = "WindsorPM/aptly-mcp"
$branch = "main"
$installDir = Join-Path $env:USERPROFILE ".aptly-mcp"
$configPath = Join-Path $env:APPDATA "Claude\claude_desktop_config.json"

Write-Host ""
Write-Host "=== Aptly MCP Server Installer ===" -ForegroundColor Cyan
Write-Host ""

# --- Validate prerequisites ---

# Check Node.js
try {
    $nodeVer = & node -v 2>$null
    Write-Host "Found Node.js $nodeVer" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Node.js is not installed." -ForegroundColor Red
    Write-Host "Download it from https://nodejs.org/ (pick LTS) and re-run." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# Check API key
if (-not $ApiKey) {
    Write-Host "No API key provided." -ForegroundColor Yellow
    Write-Host "You can get it from: Aptly > Work Orders > Card Sources > API > API Keys" -ForegroundColor Yellow
    $ApiKey = Read-Host "Paste your Aptly API key"
    if (-not $ApiKey) {
        Write-Host "ERROR: No API key provided. Exiting." -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
}

# --- Download from GitHub ---

Write-Host "Downloading from GitHub..." -ForegroundColor Cyan
$zipUrl = "https://github.com/$repo/archive/refs/heads/$branch.zip"
$zipPath = Join-Path $env:TEMP "aptly-mcp.zip"
$extractPath = Join-Path $env:TEMP "aptly-mcp-extract"

# Clean up previous downloads
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
if (Test-Path $extractPath) { Remove-Item $extractPath -Recurse -Force }

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing
} catch {
    Write-Host "ERROR: Failed to download from GitHub." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Extract
Write-Host "Extracting files..." -ForegroundColor Cyan
Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force

# GitHub zips contain a top-level folder like "aptly-mcp-main"
$extracted = Get-ChildItem $extractPath | Select-Object -First 1

# Copy to install directory
if (Test-Path $installDir) {
    # Preserve node_modules if they exist (saves reinstall time)
    $existingModules = Join-Path $installDir "node_modules"
    $tempModules = Join-Path $env:TEMP "aptly-mcp-node_modules"
    if (Test-Path $existingModules) {
        if (Test-Path $tempModules) { Remove-Item $tempModules -Recurse -Force }
        Move-Item $existingModules $tempModules
    }
    Remove-Item $installDir -Recurse -Force
}

Copy-Item $extracted.FullName -Destination $installDir -Recurse

# Restore node_modules if we saved them
$tempModules = Join-Path $env:TEMP "aptly-mcp-node_modules"
if (Test-Path $tempModules) {
    Move-Item $tempModules (Join-Path $installDir "node_modules")
}

Write-Host "Installed to $installDir" -ForegroundColor Green

# Clean up temp files
Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
Remove-Item $extractPath -Recurse -Force -ErrorAction SilentlyContinue

# --- Install npm dependencies ---

Write-Host "Installing dependencies..." -ForegroundColor Cyan
Push-Location $installDir
try {
    & npm install --silent 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "npm install failed" }
    Write-Host "Dependencies installed." -ForegroundColor Green
} catch {
    Write-Host "ERROR: npm install failed." -ForegroundColor Red
    Pop-Location
    Read-Host "Press Enter to exit"
    exit 1
}
Pop-Location

# --- Configure Claude Desktop ---

Write-Host "Configuring Claude Desktop..." -ForegroundColor Cyan

# Use configure.ps1 from the install directory (same fix as the .bat)
$configScript = Join-Path $installDir "configure.ps1"
$serverPath = Join-Path $installDir "server.mjs"

& $configScript -ServerPath $serverPath -ApiKey $ApiKey
Write-Host "Claude Desktop configured." -ForegroundColor Green

# --- Done ---

Write-Host ""
Write-Host "=== Setup Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Restart Claude Desktop to connect." -ForegroundColor Yellow
Write-Host "Server installed at: $installDir" -ForegroundColor Gray
Write-Host "Config written to:   $configPath" -ForegroundColor Gray
Write-Host ""
Read-Host "Press Enter to close"
