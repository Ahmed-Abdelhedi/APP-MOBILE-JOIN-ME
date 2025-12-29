# 🐳 Docker Development Environment

> **Run this Flutter app on any PC without installing Flutter, Java, or Android SDK manually.**

## Quick Start

### Prerequisites
- Docker Desktop ([Download](https://www.docker.com/products/docker-desktop))
- Git
- Android device or emulator (for testing)

### Setup on New PC

```powershell
# 1. Clone repository
git clone <your-repo-url> mobile
cd mobile

# 2. Build Docker image (first time: ~10-15 min)
.\docker-build.bat

# 3. Connect device/emulator
adb devices

# 4. Run container and develop
.\docker-run.bat

# 5. Inside container: Run app
flutter run
```

### That's it! 🎉

The container includes:
- ✅ Flutter SDK (stable)
- ✅ Android SDK
- ✅ Java 17
- ✅ Gradle
- ✅ All dependencies pre-cached

## Documentation

- **[Quick Start Guide](DOCKER_QUICKSTART.md)** - Fast reference for daily use
- **[Complete Setup Guide](DOCKER_SETUP.md)** - Detailed instructions & troubleshooting
- **[Consistency Explained](DOCKER_CONSISTENCY.md)** - How Docker ensures identical behavior

## Daily Development

```powershell
# Start container
.\docker-run.bat

# Inside container
flutter run           # Run app
flutter test          # Run tests
flutter build apk     # Build APK
flutter doctor -v     # Check environment
```

## Why Docker?

| Without Docker | With Docker |
|----------------|-------------|
| Install Flutter SDK manually | ✅ Pre-installed in image |
| Install Java manually | ✅ Pre-installed in image |
| Configure Android SDK | ✅ Pre-configured in image |
| Version conflicts between PCs | ✅ Same environment everywhere |
| Hours of setup | ✅ 2 commands to start |

## Alternative: Docker Compose

```powershell
# Start everything with one command
.\docker-compose-up.bat

# Inside container
flutter run
```

## Troubleshooting

See [DOCKER_SETUP.md](DOCKER_SETUP.md#troubleshooting) for common issues and solutions.

### Quick Fixes

```bash
# Device not detected?
exit
# On host: adb kill-server && adb start-server
.\docker-run.bat

# Build errors?
flutter clean && flutter pub get

# Environment check
flutter doctor -v
```

## What's Included in This Repo

All necessary files for Docker development are committed:
- `Dockerfile` - Container definition
- `docker-compose.yml` - Compose configuration
- `docker-build.bat/ps1` - Build scripts
- `docker-run.bat/ps1` - Run scripts
- `.dockerignore` - Build optimization
- `android/app/google-services.json` - Firebase config ✅
- `lib/firebase_options.dart` - Firebase options ✅

**No external secrets or configurations needed!** Everything is in the repo.

## Performance

| Operation | Time |
|-----------|------|
| First build | 10-15 min |
| Subsequent builds | 2-3 min |
| Container start | 2-5 sec |
| Hot reload | 2-5 sec (same as native) |

## Platform Support

- ✅ **Windows** (PowerShell & Batch scripts provided)
- ✅ **macOS** (use `docker build` and `docker run` commands)
- ✅ **Linux** (use `docker build` and `docker run` commands)

## Need Help?

Check the [Complete Setup Guide](DOCKER_SETUP.md) or run:

```bash
# Inside container
flutter doctor -v
```

---

**Enjoy consistent, portable Flutter development!** 🚀
