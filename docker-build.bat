@echo off
REM Quick Docker build script for Flutter Mobile App
REM Run this to build the Docker image with all Flutter/Android dependencies

echo.
echo ========================================
echo  Building Flutter Mobile Docker Image
echo ========================================
echo.

docker build -t mobile-flutter-app:latest .

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo  Build successful!
    echo ========================================
    echo.
    echo Next step: Run docker-run.bat to start the container
) else (
    echo.
    echo ========================================
    echo  Build failed! Check the error above.
    echo ========================================
    exit /b 1
)
