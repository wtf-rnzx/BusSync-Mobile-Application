import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import '../models/busInfo.dart';
import '../models/driverInfo.dart';
import '../models/distanceInfo.dart';
import '../utils/constant.dart';
import '../routes/feedback_route.dart';
import '../routes/driverInfo_route.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  // Controllers and state
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  LatLng? _userLocation;
  bool _isSearching = false;
  bool _showBusInfo = false;
  bool _isLoadingLocation = false;
  BusInfo? _selectedBusInfo;
  DistanceInfo? _selectedBusDistance;
  bool _isBusDropdownExpanded = false; // Add this for dropdown state

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
          _buildBusDropdown(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButtons(),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: AppConstants.initialPosition,
        initialZoom: AppConstants.initialZoom,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        if (_selectedBusDistance != null) _buildPolylineLayer(),
        _busLocationIcons(),
        if (_userLocation != null) _buildUserLocationMarker(),
      ],
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
                                size: 19,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _selectedBusInfo!.busNumber,
                              style: const TextStyle(
                                fontSize: 17,
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
                    const SizedBox(height: 3),
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
                      const SizedBox(height: 8),
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
                                vertical: 2,
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
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _navigateToFeedback(),
                            icon: const Icon(Icons.feedback, size: 17),
                            label: const Text('Feedback'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade500,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
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
                            icon: const Icon(Icons.person, size: 17),
                            label: const Text('Driver Info'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.lightBlue.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
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
        SizedBox(
          height: 55,
          width: 55,
          child: FloatingActionButton(
            heroTag: 'center',
            tooltip: 'Current Location',
            onPressed: _isLoadingLocation ? null : _returnPosition,

            backgroundColor: Colors.lightBlue.shade600,

            child: _isLoadingLocation
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.my_location, color: Colors.white),
          ),
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

  // OSRM Routing method to get road-following route
  Future<List<LatLng>> _getOSRMRoute(LatLng start, LatLng end) async {
    try {
      final String url =
          '${AppConstants.osrmBaseUrl}'
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

  // Bus tap handler with road-following routing
  void _onBusTapped(BusInfo busInfo) async {
    setState(() {
      _isBusDropdownExpanded = false;
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
          polylinePoints: routePoints,
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
        _isBusDropdownExpanded = true;
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
          '${AppConstants.nominatimBaseUrl}?format=json&q=$query&limit=1',
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

  // Return to actual user location
  void _returnPosition() async {
    try {
      setState(() => _isLoadingLocation = true);

      LatLng userLocation = await _getCurrentUserLocation();

      _mapController.move(userLocation, AppConstants.initialZoom);

      setState(() {
        _userLocation = userLocation;
        _isLoadingLocation = false;
      });

      _showSnackBar('Centered on your current location');
    } catch (e) {
      setState(() => _isLoadingLocation = false);
      _showSnackBar('Failed to get current location: $e');

      _mapController.move(
        AppConstants.initialPosition,
        AppConstants.initialZoom,
      );
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // Simple bus list widget positioned at the bottom
  // New dropdown widget for Active Buses
  Widget _buildBusDropdown() {
    return Positioned(
      left: 16,
      right: 86,
      bottom: 16,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Dropdown Header - always visible
            InkWell(
              onTap: () {
                setState(() {
                  _isBusDropdownExpanded = !_isBusDropdownExpanded;
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(5),
                    bottomRight: Radius.circular(5),
                  ),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2), // Shadow color
                      spreadRadius: 2, // How much the shadow spreads
                      blurRadius: 6, // How soft the shadow is
                      offset: Offset(0, 4), // X and Y offset
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.directions_bus, color: Colors.blue),
                    const SizedBox(width: 8),
                    const Text(
                      'Active Buses',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      margin: EdgeInsets.only(left: 10.0),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_buses.length} Active',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    AnimatedRotation(
                      turns: _isBusDropdownExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.blue,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Expandable Bus List with animation
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              height: _isBusDropdownExpanded ? 200 : 0,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: _buses.length,
                    itemBuilder: (context, index) {
                      final bus = _buses[index];
                      return _buildDropdownBusItem(bus);
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Bus list item for dropdown
  Widget _buildDropdownBusItem(BusInfo bus) {
    final bool isSelected = _selectedBusInfo?.busNumber == bus.busNumber;

    return InkWell(
      onTap: () => _onBusTapped(
        bus,
      ), // This will close dropdown and open animation container
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
          color: isSelected ? Colors.blue[50] : Colors.transparent,
        ),
        child: Row(
          children: [
            // Bus icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue[100] : Colors.blue[50],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.directions,
                color: isSelected ? Colors.blue[700] : Colors.blue,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // Bus info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    bus.busNumber,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.blue[700] : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    bus.route,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(width: 6),
                  // ETA info
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'ETA: ${bus.eta}',
                        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Status and action indicators
            Column(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
