# PowerShell script to build APK with manual artifact handling
$projectRoot = Get-Location
$apkSource = "$projectRoot\android\app\build\outputs\apk\release\app-release.apk"
$buildDir = "$projectRoot\build"

Write-Host "Starting Flutter APK build..." -ForegroundColor Cyan

# Run flutter build
& flutter build apk --release

# Check if build succeeded
if ($LASTEXITCODE -ne 0) {
    Write-Host "Flutter build failed" -ForegroundColor Red
    exit 1
}

# Manually verify APK exists
if (Test-Path $apkSource) {
    Write-Host "✅ APK found at: $apkSource" -ForegroundColor Green
    Write-Host "APK Size: $((Get-Item $apkSource).Length / 1MB) MB" -ForegroundColor Green
    
    # Create build directory if it doesn't exist
    if (-not (Test-Path $buildDir)) {
        New-Item -ItemType Directory -Path $buildDir -Force | Out-Null
    }
    
    # Copy to expected Flutter location
    $flutterExpectedPath = "$buildDir\app\outputs\apk\release\app-release.apk"
    Copy-Item -Path $apkSource -Destination $flutterExpectedPath -Force
    Write-Host "✅ APK copied to Flutter expected location" -ForegroundColor Green
    Write-Host "Build completed successfully!" -ForegroundColor Green
} else {
    Write-Host "❌ APK not found at: $apkSource" -ForegroundColor Red
    exit 1
}
