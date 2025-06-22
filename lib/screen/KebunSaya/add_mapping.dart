import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:projek_uas/logic/add_mapping_logic.dart';
import 'package:screenshot/screenshot.dart';
import 'package:projek_uas/screen/KebunSaya/kebunSaya.dart';

// Mixin untuk safe state management
mixin SafeState<T extends StatefulWidget> on State<T> {
  void safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }
}

class AddMappingPage extends StatefulWidget {
  const AddMappingPage({super.key});

  @override
  State<AddMappingPage> createState() => _AddMappingPageState();
}

class _AddMappingPageState extends State<AddMappingPage> with SafeState {
  late AddMappingLogic _logic;

  @override
  void initState() {
    super.initState();
    _initializeLogic();
  }

  void _initializeLogic() {
    _logic = AddMappingLogic(
      onStateChanged: (fn) => safeSetState(fn),
      onShowMessage: (message) => _showMessage(message),
      onNavigateToMapping: () => _navigateToMapping(),
    );
  }

  @override
  void dispose() {
    _logic.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  void _navigateToMapping() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const MappingPage(idLahan: null), // Sesuaikan dengan kebutuhan
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      title: const Text(
        'Petakan Lahan Saya',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      elevation: 1,
      actions: [
        TextButton(
          onPressed: _logic.isSubmitting ? null : _logic.submitPolygon,
          child: _logic.isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text(
                  'SIMPAN',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Stack(
      children: [
        _buildMap(),
        if (_logic.isSubmitting) _buildLoadingOverlay(),
      ],
    );
  }

  Widget _buildMap() {
    return Screenshot(
      controller: _logic.screenshotController,
      child: FlutterMap(
        mapController: _logic.mapController,
        options: MapOptions(
          center: LatLng(-6.2, 106.816666),
          zoom: 16.0,
          onTap: _logic.onMapTap,
        ),
        children: [
          _buildTileLayer(),
          if (_logic.polygonPoints.isNotEmpty) _buildPolygonLayer(),
          _buildMarkerLayer(),
        ],
      ),
    );
  }

  Widget _buildTileLayer() {
    return TileLayer(
      urlTemplate:
          'https://services.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
      userAgentPackageName: 'com.example.app',
    );
  }

  Widget _buildPolygonLayer() {
    return PolygonLayer(
      polygons: [
        Polygon(
          points: _logic.polygonPoints,
          color: Colors.green.withOpacity(0.4),
          borderStrokeWidth: 2,
          borderColor: Colors.green,
        ),
      ],
    );
  }

  Widget _buildMarkerLayer() {
    return MarkerLayer(
      markers: [
        ..._buildPolygonMarkers(),
        if (_logic.userLocation != null) _buildUserLocationMarker(),
      ],
    );
  }

  List<Marker> _buildPolygonMarkers() {
    return _logic.polygonPoints
        .map(
          (point) => Marker(
            point: point,
            width: 20,
            height: 20,
            child: const Icon(Icons.location_on, color: Colors.red),
          ),
        )
        .toList();
  }

  Marker _buildUserLocationMarker() {
    return Marker(
      point: _logic.userLocation!,
      width: 40,
      height: 40,
      child: const Icon(
        Icons.my_location,
        color: Colors.blue,
        size: 30,
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black26,
      child: const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Menyimpan data lahan...',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _logic.isSubmitting ? null : _logic.getUserLocation,
      label: const Text('Temukan saya'),
      icon: const Icon(Icons.gps_fixed, color: Colors.black),
      backgroundColor: _logic.isSubmitting ? Colors.grey : Colors.white,
      foregroundColor: Colors.black,
    );
  }
}