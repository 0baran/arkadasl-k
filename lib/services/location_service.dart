import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  Future<bool> checkPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  Future<bool> isLocationEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  Future<Position> getCurrentPosition() async {
    try {
      final hasPermission = await checkPermission();
      if (!hasPermission) {
        throw Exception('Konum izni verilmedi');
      }

      final isEnabled = await isLocationEnabled();
      if (!isEnabled) {
        throw Exception('Konum servisi kapalı');
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (e) {
      throw Exception('Konum alınamadı: $e');
    }
  }

  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100, // Update every 100 meters
      ),
    );
  }

  double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  double calculateDistanceInKm(double distanceInMeters) {
    return distanceInMeters / 1000;
  }

  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  Future<String> getAddressFromCoordinates(double lat, double lon) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String district = place.subAdministrativeArea ?? place.locality ?? '';
        String city = place.administrativeArea ?? '';
        
        if (district.isNotEmpty && city.isNotEmpty) {
          if (district == city) return city;
          return '$district, $city';
        } else if (city.isNotEmpty) {
          return city;
        } else if (district.isNotEmpty) {
          return district;
        } else {
          return place.country ?? 'Konum Bulunamadı';
        }
      }
      return 'Konum Bulunamadı';
    } catch (e) {
      return 'Konum Hatası';
    }
  }
}
