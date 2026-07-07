$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$logDir = Join-Path $root "run-logs"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

if (-not $env:DATABASE_URL) {
  $env:DATABASE_URL = "postgresql://postgres:postgres_password@localhost:5432/rider_db?schema=public"
}
function Start-RiderProcess {
  param(
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter(Mandatory = $true)][string]$WorkingDirectory,
    [Parameter(Mandatory = $true)][string]$Command,
    [Parameter(Mandatory = $true)][string]$Arguments
  )

  $stdout = Join-Path $logDir "$Name.out.log"
  $stderr = Join-Path $logDir "$Name.err.log"

  # Workaround for PowerShell's Start-Process WorkingDirectory single-quote bug:
  # We pass "cd /d [WorkingDirectory]" as part of cmd.exe arguments instead of using -WorkingDirectory.
  $fullArguments = "/c cd /d `"$WorkingDirectory`" && $Arguments"
  if ($Arguments -like "/c *") {
    $fullArguments = "/c cd /d `"$WorkingDirectory`" && " + $Arguments.Substring(3)
  }

  $process = Start-Process `
    -FilePath "cmd.exe" `
    -ArgumentList $fullArguments `
    -NoNewWindow `
    -RedirectStandardOutput $stdout `
    -RedirectStandardError $stderr `
    -PassThru

  Set-Content -Path (Join-Path $logDir "$Name.pid") -Value $process.Id
  Write-Output "$Name PID $($process.Id)"
}

Start-RiderProcess `
  -Name "backend" `
  -WorkingDirectory (Join-Path $root "rider-backend") `
  -Command "cmd.exe" `
  -Arguments "/c npm run start:dev"

Start-RiderProcess `
  -Name "admin" `
  -WorkingDirectory (Join-Path $root "rider-admin-web") `
  -Command "cmd.exe" `
  -Arguments "/c npm run dev"

Start-RiderProcess `
  -Name "customer" `
  -WorkingDirectory (Join-Path $root "rider-customer\build\web") `
  -Command "cmd.exe" `
  -Arguments "/c py -m http.server 8081"

Start-RiderProcess `
  -Name "driver" `
  -WorkingDirectory (Join-Path $root "rider_driver\build\web") `
  -Command "cmd.exe" `
  -Arguments "/c py -m http.server 8082"

Start-RiderProcess `
  -Name "prisma-studio" `
  -WorkingDirectory (Join-Path $root "rider-backend") `
  -Command "cmd.exe" `
  -Arguments "/c npx prisma studio --port 5555"

Write-Output "Logs: $logDir"
