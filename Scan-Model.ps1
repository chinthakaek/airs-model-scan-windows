<#
.SYNOPSIS
    Runs a Model Security Scan with CLI arguments.
.DESCRIPTION
    Dynamically selects the correct UUID from .env based on scan type (hf or local).
.PARAMETER Target
    The Hugging Face URL (for -Type hf) or Local Folder Path (for -Type local).
.PARAMETER Type
    The type of scan: 'hf' (Hugging Face) or 'local' (Local Disk).
.EXAMPLE
    .\Scan-Model.ps1 -Type hf -Target "https://huggingface.co/microsoft/DialoGPT-medium"
.EXAMPLE
    .\Scan-Model.ps1 -Type local -Target "C:\Models\MyLlama"
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]$Target,

    [Parameter(Mandatory=$true)]
    [ValidateSet("hf", "local")]
    [string]$Type
)

$ErrorActionPreference = "Stop"

# --- 1. Load .env File ---
$envFile = "$PSScriptRoot\.env"
if (Test-Path $envFile) {
    Get-Content $envFile | Where-Object { $_ -match '=' -and $_ -notmatch '^#' } | ForEach-Object {
        $parts = $_.Split('=', 2)
        $name = $parts[0].Trim()
        $value = $parts[1].Trim().Trim('"').Trim("'")
        [System.Environment]::SetEnvironmentVariable($name, $value, "Process")
    }
} else {
    Write-Error "Could not find .env file at $envFile"
    exit 1
}

# --- 2. Activate Virtual Environment ---
$VenvScript = "$PSScriptRoot\.venv\Scripts\Activate.ps1"
if (-not (Test-Path $VenvScript)) {
    Write-Error "Virtual environment missing. Run 'Run-ModelScan.ps1' first."
    exit 1
}

# Temporarily allow script execution for this process
if ((Get-ExecutionPolicy) -in 'Restricted', 'AllSigned') {
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
}
. $VenvScript

# --- 3. Configure Scan Logic ---
$ArgsList = @("scan")

if ($Type -eq "hf") {
    # HUGGING FACE LOGIC
    $Uuid = $env:SECURITY_GROUP_UUID_HF
    if (-not $Uuid) { Write-Error "Missing SECURITY_GROUP_UUID_HF in .env file."; exit 1 }
    
    Write-Host "--- Scanning Hugging Face Model ---" -ForegroundColor Cyan
    Write-Host "URL:  $Target"
    Write-Host "UUID: $Uuid" -ForegroundColor Gray
    
    $ArgsList += "--security-group-uuid", $Uuid
    $ArgsList += "--model-uri", $Target

} elseif ($Type -eq "local") {
    # LOCAL PATH LOGIC
    $Uuid = $env:SECURITY_GROUP_UUID_LOCAL
    if (-not $Uuid) { Write-Error "Missing SECURITY_GROUP_UUID_LOCAL in .env file."; exit 1 }
    
    if (-not (Test-Path $Target)) { Write-Error "Path not found: $Target"; exit 1 }

    Write-Host "--- Scanning Local Model ---" -ForegroundColor Cyan
    Write-Host "Path: $Target"
    Write-Host "UUID: $Uuid" -ForegroundColor Gray

    $ArgsList += "--security-group-uuid", $Uuid
    $ArgsList += "--model-path", $Target
}

# --- 4. Execute ---
Write-Host "`nLaunching Scanner..." -ForegroundColor Yellow
model-security @ArgsList