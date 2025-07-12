import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
      home: const MapScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const LatLng _initialPosition = LatLng(13.7564, 121.0583);
  static const double _initialZoom = 13.0;

  // Controllers and state
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  bool _isDarkTiles = false;
  LatLng _currentMarkerPosition = _initialPosition;
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [_buildMap(), _buildSearchBar()]),
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
      children: [_buildTileLayer(), _buildMarkerLayer()],
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

  Widget _buildMarkerLayer() {
    return MarkerLayer(
      markers: [
        Marker(
          point: _currentMarkerPosition,
          width: 60,
          height: 60,
          child: const Icon(Icons.location_pin, size: 50, color: Colors.red),
        ),
      ],
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

  Widget _buildFloatingActionButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.small(
          heroTag: 'toggle',
          tooltip: 'Toggle tile style',
          onPressed: _toggleTileStyle,
          child: const Icon(Icons.layers),
        ),
        const SizedBox(height: 8),
        FloatingActionButton.small(
          heroTag: 'center',
          tooltip: 'Re‑center on Manila',
          onPressed: _recenterMap,
          child: const Icon(Icons.my_location),
        ),
      ],
    );
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

          setState(() {
            _currentMarkerPosition = newPosition;
          });

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

  void _toggleTileStyle() {
    setState(() => _isDarkTiles = !_isDarkTiles);
  }

  void _recenterMap() {
    _mapController.move(_initialPosition, _initialZoom);
    setState(() => _currentMarkerPosition = _initialPosition);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
