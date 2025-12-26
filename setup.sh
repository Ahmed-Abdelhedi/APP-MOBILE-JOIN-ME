#!/bin/bash

# Script Bash pour configuration automatique du projet JoinMe
# À exécuter APRÈS avoir cloné le projet
# Usage: bash setup.sh

echo "🚀 Configuration automatique du projet JoinMe..."
echo ""

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 1. Vérifier Flutter
echo -e "${YELLOW}1️⃣ Vérification de Flutter...${NC}"
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter n'est pas installé ou pas dans le PATH!${NC}"
    echo -e "${RED}   Installer Flutter depuis: https://docs.flutter.dev/get-started/install${NC}"
    exit 1
fi

FLUTTER_VERSION=$(flutter --version | head -n 1)
echo -e "${GREEN}✅ Flutter détecté: $FLUTTER_VERSION${NC}"

# 2. Vérifier Java
echo ""
echo -e "${YELLOW}2️⃣ Vérification de Java...${NC}"
if ! command -v java &> /dev/null; then
    echo -e "${RED}⚠️  Java n'est pas installé!${NC}"
    echo -e "${RED}   Installer Java 17 depuis: https://adoptium.net/${NC}"
    read -p "Continuer quand même? (o/N): " continue
    if [ "$continue" != "o" ]; then
        exit 1
    fi
else
    JAVA_VERSION=$(java -version 2>&1 | head -n 1)
    echo -e "${GREEN}✅ Java détecté: $JAVA_VERSION${NC}"
fi

# 3. Créer local.properties
echo ""
echo -e "${YELLOW}3️⃣ Création de android/local.properties...${NC}"

if [ ! -d "android" ]; then
    echo -e "${RED}❌ Le dossier 'android' n'existe pas. Êtes-vous à la racine du projet?${NC}"
    exit 1
fi

# Trouver le chemin Flutter SDK
FLUTTER_PATH=$(dirname $(dirname $(which flutter)))

if [ -f "android/local.properties" ]; then
    echo -e "${YELLOW}⚠️  Le fichier local.properties existe déjà${NC}"
    read -p "Écraser? (o/N): " overwrite
    if [ "$overwrite" = "o" ]; then
        echo "flutter.sdk=$FLUTTER_PATH" > android/local.properties
        echo -e "${GREEN}✅ Fichier local.properties mis à jour${NC}"
    else
        echo -e "${YELLOW}   Fichier conservé${NC}"
    fi
else
    echo "flutter.sdk=$FLUTTER_PATH" > android/local.properties
    echo -e "${GREEN}✅ Fichier local.properties créé avec: flutter.sdk=$FLUTTER_PATH${NC}"
fi

# 4. Vérifier google-services.json
echo ""
echo -e "${YELLOW}4️⃣ Vérification des fichiers Firebase...${NC}"

if [ ! -f "android/app/google-services.json" ]; then
    echo -e "${RED}❌ MANQUANT: android/app/google-services.json${NC}"
    echo -e "${RED}   Ce fichier est OBLIGATOIRE pour Firebase!${NC}"
    echo -e "${YELLOW}   Demandez-le au chef de projet et placez-le dans android/app/${NC}"
else
    echo -e "${GREEN}✅ google-services.json trouvé${NC}"
fi

if [ ! -f "ios/Runner/GoogleService-Info.plist" ]; then
    echo -e "${YELLOW}⚠️  MANQUANT: ios/Runner/GoogleService-Info.plist (pour iOS)${NC}"
else
    echo -e "${GREEN}✅ GoogleService-Info.plist trouvé${NC}"
fi

# 5. Flutter pub get
echo ""
echo -e "${YELLOW}5️⃣ Installation des dépendances Flutter...${NC}"
flutter pub get

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Dépendances installées avec succès${NC}"
else
    echo -e "${RED}❌ Erreur lors de l'installation des dépendances${NC}"
fi

# 6. Flutter clean
echo ""
echo -e "${YELLOW}6️⃣ Nettoyage du projet...${NC}"
flutter clean
echo -e "${GREEN}✅ Projet nettoyé${NC}"

# 7. Gradle clean (optionnel)
echo ""
read -p "7️⃣ Nettoyer aussi le cache Gradle? (recommandé) (O/n): " clean_gradle
if [ "$clean_gradle" != "n" ]; then
    echo -e "${YELLOW}   Nettoyage de Gradle...${NC}"
    
    if [ -d "android/.gradle" ]; then
        rm -rf android/.gradle
        echo -e "${GREEN}   ✅ android/.gradle supprimé${NC}"
    fi
    
    if [ -d "android/build" ]; then
        rm -rf android/build
        echo -e "${GREEN}   ✅ android/build supprimé${NC}"
    fi
    
    if [ -d "build" ]; then
        rm -rf build
        echo -e "${GREEN}   ✅ build/ supprimé${NC}"
    fi
    
    echo -e "${GREEN}✅ Caches Gradle nettoyés${NC}"
fi

# 8. Rendre gradlew exécutable
echo ""
echo -e "${YELLOW}8️⃣ Configuration des permissions Gradle...${NC}"
chmod +x android/gradlew
echo -e "${GREEN}✅ Permissions configurées${NC}"

# 9. Flutter doctor
echo ""
echo -e "${YELLOW}9️⃣ Vérification finale de Flutter...${NC}"
flutter doctor

# Résumé
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ CONFIGURATION TERMINÉE!${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${CYAN}📋 Prochaines étapes:${NC}"
echo ""

if [ ! -f "android/app/google-services.json" ]; then
    echo -e "${YELLOW}⚠️  1. OBLIGATOIRE: Obtenir le fichier google-services.json${NC}"
    echo -e "${YELLOW}      et le placer dans android/app/${NC}"
    echo ""
fi

echo -e "🔌 2. Connecter un appareil ou lancer un émulateur:"
echo -e "      ${CYAN}flutter emulators${NC}"
echo ""
echo -e "🚀 3. Lancer l'application:"
echo -e "      ${CYAN}flutter run${NC}"
echo ""
echo -e "📱 4. Ou build l'APK:"
echo -e "      ${CYAN}flutter build apk --debug${NC}"
echo ""
echo -e "📚 5. Consulter la documentation:"
echo -e "      - README.md"
echo -e "      - SETUP_POUR_NOUVEAUX_DEVELOPPEURS.md"
echo -e "      - FIREBASE_SETUP.md"
echo ""
echo -e "${GREEN}Bon développement! 🎉${NC}"
