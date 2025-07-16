import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import '../routes/feedback_route.dart';
import '../routes/driverInfo_route.dart';

void main() {
  runApp(BusSyncApp());
}

class BusSyncApp extends StatelessWidget {
  const BusSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BusSync Mobile Application',
      theme: ThemeData(
        primarySwatch: Colors.lightBlue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const MapScreen(),
    const RoutesScreen(),
    const ScheduleScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Colors.lightBlue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_bus),
            label: 'Routes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

// Driver information model
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

// Bus information model (updated)
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

// Distance info model
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

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  static const LatLng _initialPosition = LatLng(13.7900, 121.0620);
  static const double _initialZoom = 15.0;

  // Controllers and state
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  bool _isDarkTiles = false;
  LatLng? _userLocation;
  bool _isSearching = false;
  bool _showBusInfo = false;
  bool _isLoadingLocation = false;
  BusInfo? _selectedBusInfo;
  DistanceInfo? _selectedBusDistance;

  // Distance calculator
  final Distance _distance = Distance();

  // Sample bus data with driver info
  final List<BusInfo> _buses = [
    BusInfo(
      busNumber: 'Bus 001',
      route: 'Lucena -> Batangas',
      eta: '5 mins',
      location: const LatLng(13.7967, 121.0650),
      driverInfo: DriverInfo(
        driverName: 'Juan Dela Cruz',
        driverId: 'DRV-001',
        busNumber: 'Bus 001',
        plateNumber: 'ABC-1234',
        busType: 'Air-Conditioned',
        busRoute: 'Lucena -> Batangas',
      ),
    ),
    BusInfo(
      busNumber: 'Bus 002',
      route: 'Batangas -> Lucena',
      eta: '3 hrs',
      location: const LatLng(13.8150, 121.1367),
      driverInfo: DriverInfo(
        driverName: 'Maria Santos',
        driverId: 'DRV-002',
        busNumber: 'Bus 002',
        plateNumber: 'XYZ-5678',
        busType: 'Non Air-Conditioned',
        busRoute: 'Batangas -> Lucena',
      ),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildMap(),
          _buildSearchBar(),
          if (_showBusInfo && _selectedBusInfo != null)
            _buildBusInfoContainer(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButtons(),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _initialPosition,
        initialZoom: _initialZoom,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        _buildTileLayer(),
        if (_selectedBusDistance != null) _buildPolylineLayer(),
        _busLocationIcons(),
        if (_userLocation != null) _buildUserLocationMarker(),
      ],
    );
  }

  Widget _buildTileLayer() {
    return TileLayer(
      urlTemplate: _isDarkTiles
          ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
          : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      subdomains: _isDarkTiles ? const ['a', 'b', 'c'] : const [''],
      userAgentPackageName: 'com.example.osm_map_demo',
    );
  }

  Widget _buildPolylineLayer() {
    return PolylineLayer(
      polylines: [
        Polyline(
          points: _selectedBusDistance!.polylinePoints,
          strokeWidth: 4.5,
          color: Colors.blue.withOpacity(0.8),
          borderStrokeWidth: 2.0,
          borderColor: Colors.white.withOpacity(0.8),
        ),
      ],
    );
  }

  Widget _buildUserLocationMarker() {
    return MarkerLayer(
      markers: [
        Marker(
          point: _userLocation!,
          width: 30,
          height: 30,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: const Icon(Icons.my_location, size: 20, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _busLocationIcons() {
    return MarkerLayer(
      markers: _buses.map((bus) {
        return Marker(
          point: bus.location,
          width: 30,
          height: 30,
          child: GestureDetector(
            onTap: () => _onBusTapped(bus),
            child: Container(
              decoration: BoxDecoration(
                color: _selectedBusInfo?.busNumber == bus.busNumber
                    ? Colors.orange
                    : const Color.fromARGB(255, 54, 165, 244),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.directions_bus,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSearchBar() {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Material(
            color: Colors.white,
            elevation: 4,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.search, size: 24, color: Colors.grey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search location...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      onSubmitted: _searchLocation,
                    ),
                  ),
                  if (_isSearching)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBusInfoContainer() {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 72, left: 16, right: 16),
          child: SlideTransition(
            position: _slideAnimation,
            child: Material(
              color: Colors.white,
              elevation: 8,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.lightBlue.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.directions_bus,
                                color: Colors.lightBlue,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _selectedBusInfo!.busNumber,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: _closeBusInfo,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            child: const Icon(
                              Icons.close,
                              size: 20,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Route',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _selectedBusInfo!.route,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 16,
                                color: Colors.green.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'ETA: ${_selectedBusInfo!.eta}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // Distance Information Section
                    if (_selectedBusDistance != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blue.shade200,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.route,
                              color: Colors.blue.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Route distance to bus:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade700,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _selectedBusDistance!.formattedDistance,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Action Buttons Section
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _navigateToFeedback(),
                            icon: const Icon(Icons.feedback, size: 18),
                            label: const Text('Feedback'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade500,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _navigateToDriverInfo(),
                            icon: const Icon(Icons.person, size: 18),
                            label: const Text('Driver Info'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.lightBlue.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Loading state for distance calculation
                    if (_isLoadingLocation) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Calculating route...',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.small(
          heroTag: 'toggle',
          tooltip: 'Toggle tile style',
          onPressed: _changeTileStyle,
          child: const Icon(Icons.layers),
        ),
        const SizedBox(height: 8),
        FloatingActionButton.small(
          heroTag: 'center',
          tooltip: 'Current Location',
          onPressed: _isLoadingLocation ? null : _returnPosition,
          child: _isLoadingLocation
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.my_location),
        ),
      ],
    );
  }

  // Navigation methods
  void _navigateToFeedback() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FeedbackScreen(busInfo: _selectedBusInfo!),
      ),
    );
  }

  void _navigateToDriverInfo() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            DriverInfoScreen(driverInfo: _selectedBusInfo!.driverInfo),
      ),
    );
  }

  // NEW: OSRM Routing method to get road-following route
  Future<List<LatLng>> _getOSRMRoute(LatLng start, LatLng end) async {
    try {
      final String url =
          'https://router.project-osrm.org/route/v1/driving/'
          '${start.longitude},${start.latitude};${end.longitude},${end.latitude}'
          '?overview=full&geometries=geojson';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final coordinates = data['routes'][0]['geometry']['coordinates'];

          return coordinates
              .map<LatLng>(
                (coord) => LatLng(coord[1].toDouble(), coord[0].toDouble()),
              )
              .toList();
        }
      } else {
        print('OSRM API error: ${response.statusCode}');
      }
    } catch (e) {
      print('OSRM routing error: $e');
    }

    // Fallback to straight line if routing fails
    return [start, end];
  }

  // UPDATED: Bus tap handler with road-following routing
  void _onBusTapped(BusInfo busInfo) async {
    setState(() {
      _selectedBusInfo = busInfo;
      _showBusInfo = true;
      _isLoadingLocation = true;
      _selectedBusDistance = null;
    });

    _animationController.forward();

    try {
      LatLng userLoc = await _getCurrentUserLocation();

      // Get the actual route points following roads using OSRM
      List<LatLng> routePoints = await _getOSRMRoute(userLoc, busInfo.location);

      // Calculate total distance along the route
      double totalDistance = 0;
      for (int i = 0; i < routePoints.length - 1; i++) {
        totalDistance += _distance.as(
          LengthUnit.Meter,
          routePoints[i],
          routePoints[i + 1],
        );
      }

      setState(() {
        _userLocation = userLoc;
        _selectedBusDistance = DistanceInfo(
          distanceInMeters: totalDistance,
          polylinePoints: routePoints, // Now uses actual road path
        );
        _isLoadingLocation = false;
      });

      // Fit map to show the entire route
      _fitMapToBounds(routePoints);
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
      });
      _showSnackBar('Failed to get location: $e');
    }
  }

  void _closeBusInfo() {
    _animationController.reverse().then((_) {
      setState(() {
        _showBusInfo = false;
        _selectedBusInfo = null;
        _selectedBusDistance = null;
      });
    });
  }

  Future<LatLng> _getCurrentUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    return LatLng(position.latitude, position.longitude);
  }

  void _fitMapToBounds(List<LatLng> points) {
    if (points.isEmpty) return;

    double minLat = points
        .map((p) => p.latitude)
        .reduce((a, b) => a < b ? a : b);
    double maxLat = points
        .map((p) => p.latitude)
        .reduce((a, b) => a > b ? a : b);
    double minLng = points
        .map((p) => p.longitude)
        .reduce((a, b) => a < b ? a : b);
    double maxLng = points
        .map((p) => p.longitude)
        .reduce((a, b) => a > b ? a : b);

    LatLng center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);

    double latDiff = maxLat - minLat;
    double lngDiff = maxLng - minLng;
    double maxDiff = latDiff > lngDiff ? latDiff : lngDiff;

    double zoom = 15.0;
    if (maxDiff > 0.1) {
      zoom = 10.0;
    } else if (maxDiff > 0.05)
      zoom = 12.0;
    else if (maxDiff > 0.01)
      zoom = 14.0;

    _mapController.move(center, zoom);
  }

  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) return;

    setState(() => _isSearching = true);

    try {
      final response = await http.get(
        Uri.parse(
          'https://nominatim.openstreetmap.org/search?format=json&q=$query&limit=1',
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        if (data.isNotEmpty) {
          final location = data[0];
          final lat = double.parse(location['lat']);
          final lon = double.parse(location['lon']);
          final newPosition = LatLng(lat, lon);

          _mapController.move(newPosition, 15.0);

          _showSnackBar('Location found: ${location['display_name']}');
        } else {
          _showSnackBar('Location not found');
        }
      } else {
        _showSnackBar('Search failed. Please try again.');
      }
    } catch (e) {
      _showSnackBar('Network error. Please check your connection.');
    } finally {
      setState(() => _isSearching = false);
      _searchController.clear();
    }
  }

  void _changeTileStyle() {
    setState(() => _isDarkTiles = !_isDarkTiles);
  }

  // UPDATED: Return to actual user location
  void _returnPosition() async {
    try {
      setState(() => _isLoadingLocation = true);

      LatLng userLocation = await _getCurrentUserLocation();

      _mapController.move(userLocation, _initialZoom);

      setState(() {
        _userLocation = userLocation;
        _isLoadingLocation = false;
      });

      _showSnackBar('Centered on your current location');
    } catch (e) {
      setState(() => _isLoadingLocation = false);
      _showSnackBar('Failed to get current location: $e');

      _mapController.move(_initialPosition, _initialZoom);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

// Placeholder screens for the other tabs
class RoutesScreen extends StatelessWidget {
  const RoutesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bus Routes'),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_bus, size: 80, color: Colors.lightBlue),
            SizedBox(height: 16),
            Text(
              'Bus Routes',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'View available bus routes and stops',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule'),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.schedule, size: 80, color: Colors.lightBlue),
            SizedBox(height: 16),
            Text(
              'Bus Schedule',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Check bus timings and schedules',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person, size: 80, color: Colors.lightBlue),
            SizedBox(height: 16),
            Text(
              'User Profile',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Manage your account and preferences',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
