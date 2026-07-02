import 'package:geolocator/geolocator.dart';
import 'package:injectable/injectable.dart';

/// Obtiene la ubicación actual del dispositivo. Encapsula Geolocator para que la
/// lógica que necesita GPS (por ejemplo el gate de proximidad de votos) sea
/// testeable inyectando un mock. Fail-open: retorna null si no hay permiso o falla.
@lazySingleton
class LocationService {
  Future<({double lat, double lng})?> currentLatLng() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return (lat: pos.latitude, lng: pos.longitude);
    } catch (_) {
      return null;
    }
  }
}
