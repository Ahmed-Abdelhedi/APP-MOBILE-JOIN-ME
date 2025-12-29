# Quick Docker build script for Flutter Mobile App
# Run this to build the Docker image with all Flutter/Android dependencies

Write-Host ""
Write-Host "========================================"
Write-Host " Building Flutter Mobile Docker Image"
Write-Host "========================================"
Write-Host ""

docker build -t mobile-flutter-app:latest .

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "========================================"
    Write-Host " Build successful!"
    Write-Host "========================================"
    Write-Host ""
    Write-Host "Next step: Run .\docker-run.ps1 to start the container"
} else {
    Write-Host ""
    Write-Host "========================================"
    Write-Host " Build failed! Check the error above."
    Write-Host "========================================"
    exit 1
}
