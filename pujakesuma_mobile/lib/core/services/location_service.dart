import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  /// Fetches the current GPS coordinates of the device.
  /// Handles requesting permissions if they are not already granted.
  static Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied.');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied, we cannot request permissions.');
    } 

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      // Fallback to last known position if timeout or error
      return await Geolocator.getLastKnownPosition();
    }
  }

  /// Reverse geocodes the given coordinates to get the address details (kelurahan, kecamatan).
  static Future<Map<String, String>?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        return {
          'kelurahan': place.subLocality ?? '',
          'kecamatan': place.locality ?? place.subAdministrativeArea ?? '',
          'alamat': '${place.street ?? ''} ${place.thoroughfare ?? ''}'.trim(),
        };
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
