# 🐳 Docker Setup for Flutter Mobile App

## 📋 Overview

This Docker setup ensures your Flutter mobile application runs **identically** on any PC with Docker installed. No need to install Flutter, Java, Gradle, or Android SDK manually.

### ✅ What This Solves

- **Consistent Environment**: Same Flutter SDK, Java 17, Gradle, and Android SDK on every PC
- **Zero Manual Setup**: No Flutter installation required on host machine
- **Dependency Isolation**: All build tools are containerized
- **Reproducible Builds**: Guaranteed identical behavior across machines

---

## 🚀 Quick Start - New PC Setup

### Prerequisites

1. **Docker Desktop** installed ([Download here](https://www.docker.com/products/docker-desktop))
2. **Git** installed
3. **Android Studio** (optional, only needed if you want to use emulator or manage devices)

### Step-by-Step Instructions

#### 1. Clone the Repository

```powershell
# Navigate to your desired directory
cd C:\Users\YourUsername\Desktop

# Clone the repository
git clone <your-repo-url> mobile
cd mobile
```

#### 2. Build the Docker Image

**Option A: Using the helper script (Recommended)**

```powershell
# Run the build script
.\docker-build.bat

# Or with PowerShell
.\docker-build.ps1
```

**Option B: Manual Docker command**

```powershell
docker build -t mobile-flutter-app:latest .
```

⏱️ **First build takes 10-15 minutes** (downloads Flutter SDK, Android SDK, and dependencies)

#### 3. Connect Your Android Device/Emulator

**Physical Device:**
```powershell
# Enable USB debugging on your Android device
# Connect via USB
# Verify connection:
adb devices
```

**Android Studio Emulator:**
```powershell
# Start emulator from Android Studio
# Or from command line:
emulator -avd <your_avd_name>
```

#### 4. Run the Container

**Option A: Using the helper script (Recommended)**

```powershell
.\docker-run.bat

# Or with PowerShell
.\docker-run.ps1
```

**Option B: Using Docker Compose (Easiest)**

```powershell
docker-compose up -d
docker-compose exec flutter-app /bin/bash
```

**Option C: Manual Docker command**

```powershell
docker run -it --rm `
    --name flutter-mobile-dev `
    --privileged `
    --network host `
    -v "${PWD}:/app" `
    -v flutter-pub-cache:/root/.pub-cache `
    -v gradle-cache:/root/.gradle `
    mobile-flutter-app:latest `
    /bin/bash
```

#### 5. Inside the Container - Build and Run

```bash
# You're now inside the container at /app

# Check Flutter doctor
flutter doctor -v

# Get dependencies (if needed)
flutter pub get

# List connected devices
flutter devices

# Run the app
flutter run

# Or build APK
flutter build apk
```

---

## 🔧 Common Commands

### Inside Docker Container

```bash
# Run on specific device
flutter run -d <device-id>

# Hot reload (while app is running)
# Press 'r' in terminal

# Hot restart
# Press 'R' in terminal

# Build debug APK
flutter build apk --debug

# Build release APK
flutter build apk --release

# Clean build
flutter clean && flutter pub get

# Run tests
flutter test

# Check for issues
flutter doctor -v

# Exit container
exit
```

### On Host Machine

```powershell
# Rebuild Docker image (after Dockerfile changes)
docker build -t mobile-flutter-app:latest .

# Remove container
docker rm -f flutter-mobile-dev

# List running containers
docker ps

# View container logs
docker logs flutter-mobile-dev

# Stop Docker Compose
docker-compose down

# Clean up Docker volumes (cache)
docker volume rm flutter-pub-cache gradle-cache
```

---

## 📁 Project Structure

```
mobile/
├── Dockerfile                    # Main Docker configuration
├── docker-compose.yml           # Docker Compose setup
├── docker-build.bat             # Windows build script
├── docker-build.ps1             # PowerShell build script
├── docker-run.bat               # Windows run script
├── docker-run.ps1               # PowerShell run script
├── docker-compose-up.bat        # Quick start script
├── DOCKER_SETUP.md              # This file
├── .dockerignore                # Files excluded from Docker build
├── android/                     # Android-specific code
│   ├── app/
│   │   ├── build.gradle.kts
│   │   └── google-services.json # ✅ Already committed
│   └── build.gradle.kts
├── lib/                         # Flutter/Dart code
└── pubspec.yaml                # Flutter dependencies
```

---

## 🎯 How This Ensures Consistency

### 1. **Identical Base Image**
- Uses `ghcr.io/cirruslabs/flutter:stable` - official Flutter image
- Same Flutter SDK version on every PC
- Includes pre-configured Android SDK

### 2. **Locked Java Version**
- Java 17 (OpenJDK) installed and configured
- Matches `build.gradle.kts` requirement (`JavaVersion.VERSION_17`)

### 3. **Gradle Consistency**
- Uses project's Gradle wrapper (`./gradlew`)
- Gradle dependencies cached in Docker volume
- No host Gradle installation needed

### 4. **Dependency Caching**
- Named volumes for pub cache and Gradle cache
- Faster subsequent builds
- Persists across container restarts

### 5. **Complete Project in Container**
- Entire project mounted at `/app`
- All config files (`google-services.json`, `firebase_options.dart`) included
- No external secrets or configs needed

---

## 🛠️ Troubleshooting

### Device Not Detected

**Symptom:** `flutter devices` shows no devices inside container

**Solution:**
```bash
# Exit container and run on host:
adb kill-server
adb start-server
adb devices

# Then restart container
```

### Build Fails with "SDK Licenses Not Accepted"

**Solution:** Already handled in Dockerfile, but if needed:
```bash
flutter doctor --android-licenses
# Type 'y' to accept all
```

### Port 5037 Already in Use

**Symptom:** ADB connection errors

**Solution:**
```powershell
# On host machine:
adb kill-server
adb start-server
```

### Docker Build is Slow

**First build is expected to be slow.** Subsequent builds are cached.

To clean and rebuild:
```powershell
docker build --no-cache -t mobile-flutter-app:latest .
```

### Container Can't Access Host's Emulator

**Solution:** Use `--network host` (already configured in scripts)

On Windows, ensure Docker Desktop is using WSL2 backend:
- Docker Desktop → Settings → General → Use WSL2

---

## 🔐 Security Notes

### Files Already Committed (As Per Your Setup)

- ✅ `android/app/google-services.json` - Committed (private repo)
- ✅ `lib/firebase_options.dart` - Committed (private repo)
- ✅ All Firebase config - Committed (private repo)

**Since this is a private repository used only by you**, these files can remain committed without security concerns.

### .gitignore

The `.gitignore` is configured to exclude:
- Build artifacts (`/build/`, `android/app/debug`, etc.)
- IDE files (`.idea/`, `*.iml`)
- Docker build cache (added by this setup)

---

## 🔄 Workflow on New PC

1. **One-time setup:**
   ```powershell
   git clone <repo-url> mobile
   cd mobile
   .\docker-build.bat
   ```

2. **Daily development:**
   ```powershell
   # Connect device/start emulator
   adb devices
   
   # Run container
   .\docker-run.bat
   
   # Inside container
   flutter run
   ```

3. **Updates from Git:**
   ```powershell
   git pull
   # No need to rebuild Docker image unless dependencies change
   ```

---

## 📊 Performance Tips

### 1. Use Named Volumes (Already Configured)
- `flutter-pub-cache` - Persists Flutter packages
- `gradle-cache` - Persists Gradle dependencies

### 2. Don't Clean Unnecessarily
Avoid `flutter clean` unless needed - it forces complete rebuild

### 3. Keep Container Running
Use Docker Compose to keep container running in background:
```powershell
docker-compose up -d
docker-compose exec flutter-app /bin/bash
# Work, exit, but container stays running
docker-compose exec flutter-app /bin/bash  # Re-enter later
```

---

## 🎓 Advanced Usage

### Build Release APK

```bash
# Inside container
flutter build apk --release

# APK will be at:
# build/app/outputs/flutter-apk/app-release.apk
```

### Run Gradle Tasks Directly

```bash
cd android
./gradlew tasks                # List all tasks
./gradlew assembleDebug       # Build debug APK
./gradlew assembleRelease     # Build release APK
./gradlew clean               # Clean build
```

### Update Flutter Version

```dockerfile
# Edit Dockerfile, change base image:
FROM ghcr.io/cirruslabs/flutter:3.24.0  # Specific version

# Rebuild:
docker build --no-cache -t mobile-flutter-app:latest .
```

### Customize Dockerfile

Common modifications:

```dockerfile
# Add more tools
RUN apt-get update && apt-get install -y \
    vim \
    nano \
    htop

# Change working directory
WORKDIR /workspace

# Add environment variables
ENV FLUTTER_ENV=development
```

---

## ✅ Checklist for New PC

- [ ] Docker Desktop installed and running
- [ ] Git installed
- [ ] Repository cloned
- [ ] Docker image built (`.\docker-build.bat`)
- [ ] Android device connected OR emulator running
- [ ] `adb devices` shows device
- [ ] Container started (`.\docker-run.bat`)
- [ ] Inside container: `flutter devices` shows device
- [ ] App runs successfully: `flutter run`

---

## 📞 Need Help?

1. **Check Docker status:**
   ```powershell
   docker --version
   docker ps
   ```

2. **Check Flutter doctor inside container:**
   ```bash
   flutter doctor -v
   ```

3. **Verify device connection:**
   ```bash
   flutter devices
   adb devices  # Should show same device
   ```

4. **Clean and retry:**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

---

## 🎉 Success!

If you can run `flutter run` inside the Docker container and see your app on the device, you're all set! The setup is now portable to any PC with Docker installed.

**No more "works on my machine" problems!** 🚀
