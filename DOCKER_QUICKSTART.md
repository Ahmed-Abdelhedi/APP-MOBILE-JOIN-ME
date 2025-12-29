# 🚀 Docker Quick Reference

## TL;DR - Get Started in 3 Commands

```powershell
# 1. Build the image (first time only, ~10-15 min)
.\docker-build.bat

# 2. Connect your Android device or start emulator
adb devices

# 3. Run the container and develop
.\docker-run.bat
# Inside container: flutter run
```

---

## 📦 What You Get

- ✅ Flutter SDK (stable)
- ✅ Android SDK & Tools
- ✅ Java 17 (JDK)
- ✅ Gradle (via wrapper)
- ✅ All project dependencies pre-cached
- ✅ No host installation needed (except Docker)

---

## 🎯 Common Workflows

### First Time Setup
```powershell
git clone <repo-url> mobile
cd mobile
.\docker-build.bat
```

### Daily Development
```powershell
.\docker-run.bat
# Inside container:
flutter run
```

### Build APK
```bash
# Inside container:
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Update Dependencies
```bash
# Inside container:
flutter pub get
cd android && ./gradlew --refresh-dependencies
```

### Troubleshooting
```bash
# Inside container:
flutter doctor -v
flutter clean
flutter pub get
flutter devices
```

---

## 🔧 Docker Commands

| Action | Command |
|--------|---------|
| Build image | `docker build -t mobile-flutter-app:latest .` |
| Run container | `.\docker-run.bat` or `docker-compose up` |
| Enter running container | `docker exec -it flutter-mobile-dev bash` |
| Stop container | `docker stop flutter-mobile-dev` |
| Remove container | `docker rm flutter-mobile-dev` |
| List containers | `docker ps -a` |
| Clean volumes | `docker volume rm flutter-pub-cache gradle-cache` |

---

## 📱 Device Connection

### Physical Device
1. Enable USB debugging on phone
2. Connect USB cable
3. Run `adb devices` on host
4. Device should show inside container

### Emulator
1. Start emulator from Android Studio
2. Or: `emulator -avd <name>`
3. Verify with `adb devices`
4. Should be visible in container

---

## 💡 Pro Tips

1. **Keep container running**: Use `docker-compose up -d` instead of recreating each time
2. **Named volumes**: Caching persists across restarts (already configured)
3. **Hot reload**: Works normally - just press `r` in terminal
4. **Multiple devices**: `flutter run -d <device-id>` to choose specific device

---

## 🐛 Quick Fixes

| Problem | Solution |
|---------|----------|
| No devices detected | `adb kill-server && adb start-server` on host |
| Build errors | `flutter clean && flutter pub get` in container |
| Slow build | First build is slow, subsequent builds are cached |
| Container won't start | Check Docker Desktop is running |

---

## 📂 Important Files

- `Dockerfile` - Main Docker configuration
- `docker-compose.yml` - Simplified container management
- `docker-build.bat/ps1` - Build helper scripts
- `docker-run.bat/ps1` - Run helper scripts
- `.dockerignore` - Excludes unnecessary files from build
- `DOCKER_SETUP.md` - Full documentation

---

## ✅ Success Checklist

- [ ] Docker Desktop installed
- [ ] Repository cloned
- [ ] Image built: `.\docker-build.bat`
- [ ] Device/emulator running and visible: `adb devices`
- [ ] Container started: `.\docker-run.bat`
- [ ] App runs: `flutter run` inside container

---

**Need detailed help?** See [DOCKER_SETUP.md](DOCKER_SETUP.md)
