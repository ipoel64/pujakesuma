import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final Connectivity _connectivity = Connectivity();

  /// Checks if the device is currently connected to the internet and can reach the backend.
  static Future<bool> hasInternetConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      if (results.isEmpty || results.contains(ConnectivityResult.none)) {
        return false;
      }
      
      // Perform a quick DNS lookup to verify actual WAN internet access
      final lookup = await InternetAddress.lookup('mqudxbrcqzdwkicyrwwc.supabase.co')
          .timeout(const Duration(seconds: 4));
      return lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Exposes a stream of connectivity changes.
  static Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged;
}
