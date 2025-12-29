@echo off
REM Docker Environment Validation Script (Windows Host)
REM Run this on Windows before starting Docker container

echo.
echo ========================================
echo  Pre-Docker Environment Check
echo ========================================
echo.

echo 1. Checking Docker...
docker --version >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [OK] Docker is installed
    docker --version
) else (
    echo [FAIL] Docker not found. Install Docker Desktop.
    goto :error
)
echo.

echo 2. Checking Docker is running...
docker ps >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [OK] Docker daemon is running
) else (
    echo [FAIL] Docker is not running. Start Docker Desktop.
    goto :error
)
echo.

echo 3. Checking Git...
git --version >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [OK] Git is installed
    git --version
) else (
    echo [FAIL] Git not found. Install Git.
    goto :error
)
echo.

echo 4. Checking ADB (for device connection)...
adb version >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [OK] ADB is available
    adb version | findstr "Android Debug Bridge"
) else (
    echo [WARNING] ADB not found. Install Android SDK Platform Tools or Android Studio.
    echo You'll need this to connect devices/emulators.
)
echo.

echo 5. Checking for connected devices...
adb devices 2>nul | findstr /R "device$" >nul
if %ERRORLEVEL% EQU 0 (
    echo [OK] Android device(s) detected:
    adb devices
) else (
    echo [WARNING] No Android devices connected.
    echo Connect a device or start an emulator before running the container.
)
echo.

echo 6. Checking Docker image...
docker images | findstr mobile-flutter-app >nul
if %ERRORLEVEL% EQU 0 (
    echo [OK] Docker image 'mobile-flutter-app' found
) else (
    echo [INFO] Docker image not built yet.
    echo Run: docker-build.bat
)
echo.

echo ========================================
echo  Validation Complete!
echo ========================================
echo.

if exist Dockerfile (
    echo [OK] Dockerfile found in current directory
) else (
    echo [FAIL] Dockerfile not found. Are you in the project root?
    goto :error
)

echo.
echo Next steps:
echo   1. If image not built: docker-build.bat
echo   2. Connect device/emulator: adb devices
echo   3. Run container: docker-run.bat
echo.

pause
exit /b 0

:error
echo.
echo ========================================
echo  Validation Failed!
echo ========================================
echo Please fix the errors above.
echo.
pause
exit /b 1
