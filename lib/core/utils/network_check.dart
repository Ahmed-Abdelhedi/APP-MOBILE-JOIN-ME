import 'package:connectivity_plus/connectivity_plus.dart';

/// Utilitaire pour vérifier la connexion réseau
class NetworkCheck {
  /// Vérifie si l'appareil a une connexion Internet
  static Future<bool> hasInternetConnection() async {
    try {
      // Vérifier la connectivité uniquement
      final List<ConnectivityResult> connectivityResult = await Connectivity().checkConnectivity();
      
      // Si aucune connexion, retourner false
      if (connectivityResult.contains(ConnectivityResult.none)) {
        return false;
      }

      // Si WiFi ou mobile, on considère qu'il y a une connexion
      return connectivityResult.contains(ConnectivityResult.wifi) ||
             connectivityResult.contains(ConnectivityResult.mobile);
    } catch (e) {
      print('Erreur de vérification connexion: $e');
      // En cas d'erreur, on suppose qu'il y a une connexion
      return true;
    }
  }

  /// Message d'erreur convivial
  static String getNoInternetMessage() {
    return '📡 Pas de connexion Internet\n\nVérifiez votre WiFi ou données mobiles';
  }
}
