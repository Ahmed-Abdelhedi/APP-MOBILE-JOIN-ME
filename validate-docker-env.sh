#!/bin/bash
# Docker Environment Validation Script
# Run this inside the Docker container to verify everything is set up correctly

echo ""
echo "========================================"
echo " 🐳 Docker Environment Validation"
echo "========================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

check_command() {
    if command -v $1 &> /dev/null; then
        echo -e "${GREEN}✅ $1 found${NC}"
        $1 --version 2>&1 | head -n 1
        return 0
    else
        echo -e "${RED}❌ $1 not found${NC}"
        return 1
    fi
}

echo "1️⃣  Checking Flutter..."
check_command flutter
echo ""

echo "2️⃣  Checking Java..."
check_command java
echo ""

echo "3️⃣  Checking Gradle..."
if [ -f "./android/gradlew" ]; then
    echo -e "${GREEN}✅ Gradle wrapper found${NC}"
    cd android && ./gradlew --version | head -n 5
    cd ..
else
    echo -e "${RED}❌ Gradle wrapper not found${NC}"
fi
echo ""

echo "4️⃣  Checking Android SDK..."
if [ -d "$ANDROID_HOME" ]; then
    echo -e "${GREEN}✅ Android SDK found at $ANDROID_HOME${NC}"
else
    echo -e "${RED}❌ Android SDK not found${NC}"
fi
echo ""

echo "5️⃣  Checking Flutter doctor..."
flutter doctor -v
echo ""

echo "6️⃣  Checking connected devices..."
flutter devices
echo ""

echo "7️⃣  Checking project dependencies..."
if [ -f "pubspec.yaml" ]; then
    echo -e "${GREEN}✅ pubspec.yaml found${NC}"
    echo "Running flutter pub get..."
    flutter pub get
else
    echo -e "${RED}❌ pubspec.yaml not found${NC}"
fi
echo ""

echo "8️⃣  Checking Firebase configuration..."
if [ -f "android/app/google-services.json" ]; then
    echo -e "${GREEN}✅ google-services.json found${NC}"
else
    echo -e "${YELLOW}⚠️  google-services.json not found (may be needed for Firebase features)${NC}"
fi

if [ -f "lib/firebase_options.dart" ]; then
    echo -e "${GREEN}✅ firebase_options.dart found${NC}"
else
    echo -e "${YELLOW}⚠️  firebase_options.dart not found (may be needed for Firebase features)${NC}"
fi
echo ""

echo "========================================"
echo " Validation Complete!"
echo "========================================"
echo ""
echo "If all checks passed, you can run:"
echo "  flutter run"
echo ""
echo "To test on a specific device:"
echo "  flutter run -d <device-id>"
echo ""
