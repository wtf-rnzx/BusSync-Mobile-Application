import 'package:latlong2/latlong.dart';

class AppConstants {
  // Map configuration
  static const LatLng initialPosition = LatLng(13.7967, 121.0650);
  static const double initialZoom = 13.0;

  // Tile layer URLs
  static const String lightTileUrl =
      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String darkTileUrl =
      'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';

  static const List<String> lightTileSubdomains = ['a', 'b', 'c'];
  static const List<String> darkTileSubdomains = ['a', 'b', 'c', 'd'];

  static const String userAgentPackageName = 'com.example.bussync';

  // OpenRouteService configuration - Alternative endpoint
  static const String openRouteServiceBaseUrl =
      'https://api.openrouteservice.org/v2/directions/driving-car/geojson';
  static const String openRouteServiceApiKey =
      'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6IjE5NzU2ZmE3YTU4NjQwZmQ4YzJlNGEzMzMxYmYwNTQ1IiwiaCI6Im11cm11cjY0In0='; // Get from openrouteservice.org

  // Nominatim for geocoding
  static const String nominatimBaseUrl =
      'https://nominatim.openstreetmap.org/search';
}
