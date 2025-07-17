import 'package:latlong2/latlong.dart';

class DistanceInfo {
  final double distanceInMeters;
  final List<LatLng> polylinePoints;

  DistanceInfo({required this.distanceInMeters, required this.polylinePoints});

  String get formattedDistance {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.toInt()} m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)} km';
    }
  }
}
