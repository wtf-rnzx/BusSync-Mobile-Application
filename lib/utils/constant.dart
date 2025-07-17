import 'package:latlong2/latlong.dart';

class AppConstants {
  static const LatLng initialPosition = LatLng(13.7900, 121.0620);
  static const double initialZoom = 15.0;
  static const String appName = 'BusSync';
  static const String appTagline = 'Real-time Bus Tracking';
  static const String appVersion = 'Version 1.0.0';
  static const String companyName = '© 2024 BusSync Technologies';

  // API URLs
  static const String osrmBaseUrl =
      'https://router.project-osrm.org/route/v1/driving/';
  static const String nominatimBaseUrl =
      'https://nominatim.openstreetmap.org/search';

  // Tile Layer URLs
  static const String lightTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String darkTileUrl =
      'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';
  static const List<String> darkTileSubdomains = ['a', 'b', 'c'];
  static const List<String> lightTileSubdomains = [''];

  // User Agent
  static const String userAgentPackageName = 'com.example.osm_map_demo';
}
