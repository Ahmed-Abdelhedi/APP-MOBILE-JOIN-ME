# Script PowerShell pour configuration automatique du projet JoinMe
# À exécuter APRÈS avoir cloné le projet

Write-Host "🚀 Configuration automatique du projet JoinMe..." -ForegroundColor Cyan
Write-Host ""

# 1. Vérifier Flutter
Write-Host "1️⃣ Vérification de Flutter..." -ForegroundColor Yellow
if (!(Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Flutter n'est pas installé ou pas dans le PATH!" -ForegroundColor Red
    Write-Host "   Installer Flutter depuis: https://docs.flutter.dev/get-started/install" -ForegroundColor Red
    exit 1
}

$flutterVersion = flutter --version | Select-String "Flutter" | Out-String
Write-Host "✅ Flutter détecté: $($flutterVersion.Trim())" -ForegroundColor Green

# 2. Vérifier Java
Write-Host ""
Write-Host "2️⃣ Vérification de Java..." -ForegroundColor Yellow
if (!(Get-Command java -ErrorAction SilentlyContinue)) {
    Write-Host "⚠️  Java n'est pas installé!" -ForegroundColor Red
    Write-Host "   Installer Java 17 depuis: https://adoptium.net/" -ForegroundColor Red
    $continue = Read-Host "Continuer quand même? (o/N)"
    if ($continue -ne "o") { exit 1 }
} else {
    $javaVersion = java -version 2>&1 | Select-String "version" | Out-String
    Write-Host "✅ Java détecté: $($javaVersion.Trim())" -ForegroundColor Green
}

# 3. Créer local.properties
Write-Host ""
Write-Host "3️⃣ Création de android/local.properties..." -ForegroundColor Yellow

if (!(Test-Path "android")) {
    Write-Host "❌ Le dossier 'android' n'existe pas. Êtes-vous à la racine du projet?" -ForegroundColor Red
    exit 1
}

# Trouver le chemin Flutter SDK
$flutterPath = (Get-Command flutter).Source | Split-Path | Split-Path

if (Test-Path "android\local.properties") {
    Write-Host "⚠️  Le fichier local.properties existe déjà" -ForegroundColor Yellow
    $overwrite = Read-Host "Écraser? (o/N)"
    if ($overwrite -ne "o") {
        Write-Host "   Fichier conservé" -ForegroundColor Yellow
    } else {
        "flutter.sdk=$flutterPath" | Out-File -FilePath "android\local.properties" -Encoding ASCII
        Write-Host "✅ Fichier local.properties mis à jour" -ForegroundColor Green
    }
} else {
    "flutter.sdk=$flutterPath" | Out-File -FilePath "android\local.properties" -Encoding ASCII
    Write-Host "✅ Fichier local.properties créé avec: flutter.sdk=$flutterPath" -ForegroundColor Green
}

# 4. Vérifier google-services.json
Write-Host ""
Write-Host "4️⃣ Vérification des fichiers Firebase..." -ForegroundColor Yellow

if (!(Test-Path "android\app\google-services.json")) {
    Write-Host "❌ MANQUANT: android/app/google-services.json" -ForegroundColor Red
    Write-Host "   Ce fichier est OBLIGATOIRE pour Firebase!" -ForegroundColor Red
    Write-Host "   Demandez-le au chef de projet et placez-le dans android/app/" -ForegroundColor Yellow
} else {
    Write-Host "✅ google-services.json trouvé" -ForegroundColor Green
}

if (!(Test-Path "ios\Runner\GoogleService-Info.plist")) {
    Write-Host "⚠️  MANQUANT: ios/Runner/GoogleService-Info.plist (pour iOS)" -ForegroundColor Yellow
} else {
    Write-Host "✅ GoogleService-Info.plist trouvé" -ForegroundColor Green
}

# 5. Flutter pub get
Write-Host ""
Write-Host "5️⃣ Installation des dépendances Flutter..." -ForegroundColor Yellow
flutter pub get

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Dépendances installées avec succès" -ForegroundColor Green
} else {
    Write-Host "❌ Erreur lors de l'installation des dépendances" -ForegroundColor Red
}

# 6. Flutter clean
Write-Host ""
Write-Host "6️⃣ Nettoyage du projet..." -ForegroundColor Yellow
flutter clean
Write-Host "✅ Projet nettoyé" -ForegroundColor Green

# 7. Gradle clean (optionnel)
Write-Host ""
$cleanGradle = Read-Host "7️⃣ Nettoyer aussi le cache Gradle? (recommandé) (O/n)"
if ($cleanGradle -ne "n") {
    Write-Host "   Nettoyage de Gradle..." -ForegroundColor Yellow
    
    if (Test-Path "android\.gradle") {
        Remove-Item -Path "android\.gradle" -Recurse -Force
        Write-Host "   ✅ android/.gradle supprimé" -ForegroundColor Green
    }
    
    if (Test-Path "android\build") {
        Remove-Item -Path "android\build" -Recurse -Force
        Write-Host "   ✅ android/build supprimé" -ForegroundColor Green
    }
    
    if (Test-Path "build") {
        Remove-Item -Path "build" -Recurse -Force
        Write-Host "   ✅ build/ supprimé" -ForegroundColor Green
    }
    
    Write-Host "✅ Caches Gradle nettoyés" -ForegroundColor Green
}

# 8. Flutter doctor
Write-Host ""
Write-Host "8️⃣ Vérification finale de Flutter..." -ForegroundColor Yellow
flutter doctor

# Résumé
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "✅ CONFIGURATION TERMINÉE!" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""
Write-Host "📋 Prochaines étapes:" -ForegroundColor Cyan
Write-Host ""

if (!(Test-Path "android\app\google-services.json")) {
    Write-Host "⚠️  1. OBLIGATOIRE: Obtenir le fichier google-services.json" -ForegroundColor Yellow
    Write-Host "      et le placer dans android/app/" -ForegroundColor Yellow
    Write-Host ""
}

Write-Host "🔌 2. Connecter un appareil ou lancer un émulateur:" -ForegroundColor White
Write-Host "      flutter emulators" -ForegroundColor Gray
Write-Host ""
Write-Host "🚀 3. Lancer l'application:" -ForegroundColor White
Write-Host "      flutter run" -ForegroundColor Gray
Write-Host ""
Write-Host "📱 4. Ou build l'APK:" -ForegroundColor White
Write-Host "      flutter build apk --debug" -ForegroundColor Gray
Write-Host ""
Write-Host "📚 5. Consulter la documentation:" -ForegroundColor White
Write-Host "      - README.md" -ForegroundColor Gray
Write-Host "      - SETUP_POUR_NOUVEAUX_DEVELOPPEURS.md" -ForegroundColor Gray
Write-Host "      - FIREBASE_SETUP.md" -ForegroundColor Gray
Write-Host ""
Write-Host "Bon développement! 🎉" -ForegroundColor Green
