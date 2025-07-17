class DriverInfo {
  final String driverName;
  final String driverId;
  final String busNumber;
  final String plateNumber;
  final String busType;
  final String busRoute;
  final String profileImage;

  DriverInfo({
    required this.driverName,
    required this.driverId,
    required this.busNumber,
    required this.plateNumber,
    required this.busType,
    required this.busRoute,
    this.profileImage = '',
  });
}
