import 'package:latlong2/latlong.dart';
import './driverInfo.dart';

class BusInfo {
  final String busNumber;
  final String route;
  final String eta;
  final LatLng location;
  final DriverInfo driverInfo;

  BusInfo({
    required this.busNumber,
    required this.route,
    required this.eta,
    required this.location,
    required this.driverInfo,
  });
}
