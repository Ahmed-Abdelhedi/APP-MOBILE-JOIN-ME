@echo off
REM Run Flutter development container with device access
REM Make sure your Android device/emulator is connected before running this

echo.
echo ========================================
echo  Starting Flutter Mobile Dev Container
echo ========================================
echo.

REM Check if container already exists and remove it
docker ps -a | findstr flutter-mobile-dev >nul
if %ERRORLEVEL% EQU 0 (
    echo Removing existing container...
    docker rm -f flutter-mobile-dev
)

echo Starting new container...
docker run -it --rm ^
    --name flutter-mobile-dev ^
    --privileged ^
    --network host ^
    -v "%cd%":/app ^
    -v flutter-pub-cache:/root/.pub-cache ^
    -v gradle-cache:/root/.gradle ^
    mobile-flutter-app:latest ^
    /bin/bash

echo.
echo Container stopped.
