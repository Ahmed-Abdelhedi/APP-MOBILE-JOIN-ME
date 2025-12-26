# 🗺️ Problèmes de Carte - Solutions

## Pourquoi la carte ne fonctionne pas ?

### 1. **Carte grise / Tuiles ne se chargent pas**

**Causes possibles :**
- ❌ Pas de connexion Internet
- ❌ L'émulateur/appareil bloque les requêtes HTTP
- ❌ OpenStreetMap temporairement indisponible

**Solutions :**
```bash
# 1. Vérifier la connexion Internet sur l'appareil
# 2. Redémarrer l'application
flutter run

# 3. Si sur émulateur, désactiver/réactiver WiFi
```

**Dans le code :**
- L'app vérifie automatiquement la connexion au démarrage
- Affiche un message rouge si pas de connexion
- Bouton "Réessayer" disponible

### 2. **Recherche ne fonctionne pas**

**Causes possibles :**
- ❌ Pas de connexion Internet
- ❌ Adresse trop vague ou inexistante
- ❌ Service de geocoding indisponible

**Solutions :**
- Essayez des noms de villes : "Paris", "Lyon", "Marseille"
- Utilisez des adresses complètes : "15 Avenue de la Porte de Sèvres, Paris"
- Vérifiez votre connexion Internet

**Messages d'erreur :**
- 🟠 "Adresse non trouvée" → Essayez une autre adresse
- 🔴 "Erreur de recherche" → Problème de connexion

### 3. **"Ma Position" ne fonctionne pas**

**Causes possibles :**
- ❌ Permissions de localisation refusées
- ❌ GPS désactivé
- ❌ Émulateur sans localisation configurée

**Solutions Android :**
```xml
<!-- Déjà dans AndroidManifest.xml -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

**Sur Émulateur :**
1. Ouvrir "Extended Controls" (... dans l'émulateur)
2. Aller dans "Location"
3. Définir une position GPS (ex: Paris: 48.8566, 2.3522)

**Sur Appareil Réel :**
1. Activer le GPS dans les paramètres
2. Autoriser l'app à accéder à la localisation

## 🧪 Test de connexion

L'app inclut maintenant `NetworkCheck` qui vérifie :
- ✅ État de la connexion (WiFi/Mobile)
- ✅ Accessibilité d'OpenStreetMap
- ✅ Affiche des messages d'erreur clairs

## 📱 Que faire maintenant ?

### Si la carte reste grise :
1. Vérifiez votre connexion Internet
2. Redémarrez l'app (`R` dans le terminal Flutter)
3. Essayez sur un appareil réel (pas émulateur)

### Si la recherche échoue :
1. Testez avec "Paris" ou "Lyon"
2. Vérifiez le message d'erreur affiché
3. Vérifiez votre connexion Internet

### Si tout échoue :
```bash
# Nettoyez et reconstruisez
flutter clean
flutter pub get
flutter run
```

## ✅ Vérifications automatiques

L'app vérifie maintenant automatiquement :
- ✅ Connexion Internet au démarrage
- ✅ Messages d'erreur explicites
- ✅ Bouton "Réessayer" si pas de connexion
- ✅ User agent correct pour OpenStreetMap

## 🔧 Configuration actuelle

```dart
// Tuiles OpenStreetMap
TileLayer(
  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  userAgentPackageName: 'com.joinme.mobile',
  additionalOptions: const {
    'attribution': 'OpenStreetMap contributors',
  },
)
```

**Note :** OpenStreetMap est gratuit mais peut être lent. Pour une meilleure performance en production, considérez Mapbox ou Google Maps.
