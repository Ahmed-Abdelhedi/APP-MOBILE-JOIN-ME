# Run Flutter development container with device access
# Make sure your Android device/emulator is connected before running this

Write-Host ""
Write-Host "========================================"
Write-Host " Starting Flutter Mobile Dev Container"
Write-Host "========================================"
Write-Host ""

# Check if container already exists and remove it
$containerExists = docker ps -a --filter "name=flutter-mobile-dev" --format "{{.Names}}"
if ($containerExists -eq "flutter-mobile-dev") {
    Write-Host "Removing existing container..."
    docker rm -f flutter-mobile-dev
}

Write-Host "Starting new container..."
docker run -it --rm `
    --name flutter-mobile-dev `
    --privileged `
    --network host `
    -v "${PWD}:/app" `
    -v flutter-pub-cache:/root/.pub-cache `
    -v gradle-cache:/root/.gradle `
    mobile-flutter-app:latest `
    /bin/bash

Write-Host ""
Write-Host "Container stopped."
