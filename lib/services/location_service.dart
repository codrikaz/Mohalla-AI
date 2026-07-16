import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class AreaInfo {
  final double lat;
  final double lng;
  final String? areaName;
  final String? cityName;
  final String? stateName;
  final String? countryName;

  const AreaInfo({
    required this.lat,
    required this.lng,
    this.areaName,
    this.cityName,
    this.stateName,
    this.countryName,
  });

  // UI mein dikhane ke liye: "Civil Lines, Rampur"
  String get displayArea {
    final parts = [areaName, cityName].where((s) => s != null && s.isNotEmpty).toList();
    return parts.isNotEmpty ? parts.join(', ') : 'Aas paas';
  }
}

class LocationService {
  Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  Future<Position?> getCurrentPosition() async {
    final hasPermission = await requestPermission();
    if (!hasPermission) return null;
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  // GPS se area naam automatically lao (Google reverse geocoding)
  Future<AreaInfo?> getAreaInfo() async {
    final position = await getCurrentPosition();
    if (position == null) return null;

    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isEmpty) {
        return AreaInfo(lat: position.latitude, lng: position.longitude);
      }

      final place = placemarks.first;

      // subLocality → mohalla/colony naam (e.g. "Civil Lines")
      // locality → shehar (e.g. "Rampur")
      final areaName = (place.subLocality?.isNotEmpty == true)
          ? place.subLocality
          : place.locality;

      return AreaInfo(
        lat: position.latitude,
        lng: position.longitude,
        areaName: areaName,
        cityName: place.locality,
        stateName: place.administrativeArea,
        countryName: place.country,
      );
    } catch (_) {
      // Geocoding fail hua — sirf coordinates return karo
      return AreaInfo(lat: position.latitude, lng: position.longitude);
    }
  }
}
