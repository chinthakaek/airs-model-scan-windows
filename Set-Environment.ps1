<#
.SYNOPSIS
    Automated Model Security Scanner Wrapper
.DESCRIPTION
    1. Sets up a Python Virtual Environment (if missing).
    2. Authenticates using Get-PypiUrl.ps1.
    3. Installs the package using a "Hybrid" index approach:
       - Private Repo for your security tools.
       - Public PyPI for standard dependencies (like 'click').
#>

$ErrorActionPreference = "Stop"

# --- CONFIGURATION ---
# Updated to match the package found in your logs
$PACKAGE_NAME = "model-security-client" 
# ---------------------

Write-Host "=== Starting Model Security Setup ===" -ForegroundColor Cyan

# 1. Check for Python
if (-not (Get-Command "python" -ErrorAction SilentlyContinue)) {
    Write-Error "Python is not installed or not in your PATH."
    exit 1
}

# 2. Setup Virtual Environment
$VenvDir = "$PSScriptRoot\.venv"
if (-not (Test-Path $VenvDir)) {
    Write-Host "Creating virtual environment..." -ForegroundColor Yellow
    python -m venv $VenvDir
}

# 3. Activate Virtual Environment
Write-Host "Activating virtual environment..." -ForegroundColor Yellow
$ActivateScript = "$VenvDir\Scripts\Activate.ps1"

# Check execution policy to allow the activation script to run
if ((Get-ExecutionPolicy) -in 'Restricted', 'AllSigned') {
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
}
. $ActivateScript

# 4. Retrieve Secure PyPI URL
Write-Host "Authenticating and retrieving PyPI URL..." -ForegroundColor Yellow
$AuthScript = "$PSScriptRoot\Get-PypiUrl.ps1"

if (-not (Test-Path $AuthScript)) {
    Write-Error "Could not find auth script at $AuthScript"
    exit 1
}

try {
    # Run the auth script and capture the output (The URL)
    $PypiUrl = & $AuthScript
} catch {
    Write-Error "Authentication failed. Stopping scan."
    exit 1
}

if (-not $PypiUrl) {
    Write-Error "Authentication script ran but returned no URL."
    exit 1
}

# 5. Run the Install
Write-Host "Installing $PACKAGE_NAME using hybrid index..." -ForegroundColor Green

# Extract hostname for trusted-host flag
$HostName = ($PypiUrl -split '/')[2]

# --index-url: Points to your Private Repo (for model-security-client)
# --extra-index-url: Points to Public PyPI (for dependencies like 'click')
pip install $PACKAGE_NAME `
    --index-url $PypiUrl `
    --extra-index-url https://pypi.org/simple `
    --trusted-host $HostName `
    --upgrade

if ($LASTEXITCODE -eq 0) {
    Write-Host "=== Installation Complete Successfully ===" -ForegroundColor Green
    
    # Optional: Verify installation by printing version
    pip show $PACKAGE_NAME
} else {
    Write-Error "Installation failed with exit code $LASTEXITCODE"
}