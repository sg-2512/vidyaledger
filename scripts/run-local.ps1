param(
  [string]$Device = "chrome",
  [int]$WebPort = 0
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$EnvFile = Join-Path $ProjectRoot ".env.local"

if (-not (Test-Path -LiteralPath $EnvFile)) {
  Write-Error "Missing .env.local. Copy .env.local.example to .env.local and add your Supabase values."
}

$Values = @{}
Get-Content -LiteralPath $EnvFile | ForEach-Object {
  $Line = $_.Trim()
  if ($Line.Length -eq 0 -or $Line.StartsWith("#")) {
    return
  }

  $Parts = $Line -split "=", 2
  if ($Parts.Count -ne 2) {
    return
  }

  $Key = $Parts[0].Trim()
  $Value = $Parts[1].Trim().Trim('"').Trim("'")
  $Values[$Key] = $Value
}

$RequiredKeys = @("SUPABASE_URL", "SUPABASE_PUBLISHABLE_KEY")
foreach ($Key in $RequiredKeys) {
  if (-not $Values.ContainsKey($Key) -or [string]::IsNullOrWhiteSpace($Values[$Key])) {
    Write-Error "Missing $Key in .env.local."
  }
}

$FlutterArgs = @(
  "run",
  "-d",
  $Device,
  "--dart-define=SUPABASE_URL=$($Values["SUPABASE_URL"])",
  "--dart-define=SUPABASE_PUBLISHABLE_KEY=$($Values["SUPABASE_PUBLISHABLE_KEY"])"
)

if ($WebPort -gt 0) {
  $FlutterArgs += @("--web-port", $WebPort)
}

Write-Host "Starting VidyaLedger on $Device with Supabase values from .env.local..."
& flutter @FlutterArgs
