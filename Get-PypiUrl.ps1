# Model Security Private PyPI Authentication Script for Windows
# Authenticates with SCM and retrieves PyPI repository URL

$ErrorActionPreference = "Stop"

# --- 1. .env File Loader ---
# Looks for a .env file in the same folder as this script
$envFile = "$PSScriptRoot\.env"
if (Test-Path $envFile) {
    Get-Content $envFile | Where-Object { $_ -match '=' -and $_ -notmatch '^#' } | ForEach-Object {
        $parts = $_.Split('=', 2)
        $name = $parts[0].Trim()
        $value = $parts[1].Trim().Trim('"').Trim("'")
        [System.Environment]::SetEnvironmentVariable($name, $value, "Process")
    }
}

# --- 2. Variable Validation & Defaults ---
$ClientId     = $env:MODEL_SECURITY_CLIENT_ID
$ClientSecret = $env:MODEL_SECURITY_CLIENT_SECRET
$TsgId        = $env:TSG_ID

if (-not $ClientId -or -not $ClientSecret -or -not $TsgId) {
    Write-Host "Error: Missing required environment variables (ID, Secret, or TSG_ID)." -ForegroundColor Red
    Write-Host "Check that your .env file exists at: $envFile" -ForegroundColor Gray
    exit 1
}

# Handle API Endpoint with default fallback
$RawEndpoint = $env:MODEL_SECURITY_API_ENDPOINT
if ([string]::IsNullOrWhiteSpace($RawEndpoint)) {
    $ApiEndpoint = "https://api.sase.paloaltonetworks.com/aims"
} else {
    $ApiEndpoint = $RawEndpoint.Trim().Trim('"').Split(',')[0].TrimEnd('/')
}

$TokenEndpoint = "https://auth.apps.paloaltonetworks.com/oauth2/access_token"

# --- 3. Get SCM Access Token (Using curl.exe for maximum compatibility) ---
try {
    # Using curl.exe directly as it handles Palo Alto's Auth headers more reliably than Invoke-RestMethod
    $TokenRaw = curl.exe -s -X POST "$TokenEndpoint" `
        -u "${ClientId}:${ClientSecret}" `
        -d "grant_type=client_credentials&scope=tsg_id:$TsgId"
    
    if ($LASTEXITCODE -ne 0) { throw "curl.exe failed with exit code $LASTEXITCODE" }

    $TokenResponse = $TokenRaw | ConvertFrom-Json
    $ScmToken = $TokenResponse.access_token
}
catch {
    Write-Host "--- Authentication Failure ---" -ForegroundColor Red
    Write-Host "Raw Response: $TokenRaw" -ForegroundColor Gray
    exit 1
}

if (-not $ScmToken) {
    Write-Host "Error: Access token not found in response." -ForegroundColor Red
    exit 1
}

# --- 4. Retrieve PyPI URL ---
$FullUrl = "$ApiEndpoint/mgmt/v1/pypi/authenticate"

try {
    $PypiResponse = Invoke-RestMethod -Method Get -Uri $FullUrl `
        -Headers @{ Authorization = "Bearer $ScmToken" }
    
    if ($PypiResponse.url) {
        # Output ONLY the URL so it can be captured by other scripts
        Write-Output $PypiResponse.url
    } else {
        throw "URL field missing from API response."
    }
}
catch {
    Write-Host "--- API Request Failure ---" -ForegroundColor Red
    Write-Host "Target URL: $FullUrl" -ForegroundColor Gray
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}