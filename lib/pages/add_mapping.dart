import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class AddMappingPage extends StatefulWidget {
  const AddMappingPage({super.key});

  @override
  State<AddMappingPage> createState() => _AddMappingPageState();
}

class _AddMappingPageState extends State<AddMappingPage> {
  List<LatLng> polygonPoints = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              center: LatLng(-6.200000, 106.816666),
              zoom: 16.0,
              onTap: (tapPosition, point) {
                setState(() {
                  polygonPoints.add(point);
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.example.yourapp',
              ),
              if (polygonPoints.isNotEmpty)
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: polygonPoints,
                      color: Colors.green.withOpacity(0.4),
                      borderStrokeWidth: 2,
                      borderColor: Colors.green,
                    ),
                  ],
                ),
              if (polygonPoints.isNotEmpty)
                MarkerLayer(
                  markers:
                      polygonPoints.map((point) {
                        return Marker(
                          width: 20,
                          height: 20,
                          point: point,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 20,
                          ),
                        );
                      }).toList(),
                ),
            ],
          ),
          // Top navbar
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(Icons.arrow_back),
                  ),
                ),
                const Text(
                  'Tambahkan Lahan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 32),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: FloatingActionButton.extended(
          onPressed: () {
            // Aksi tambahan, misal simpan titik
          },
          label: const Text('Tambah Lokasi'),
          icon: const Icon(Icons.add),
          backgroundColor: const Color(0xFFB1E27F),
          foregroundColor: Colors.black,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
