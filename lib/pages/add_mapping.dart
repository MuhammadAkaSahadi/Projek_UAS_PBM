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
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text(
          'Petakan Lahan Saya',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 1,
      ),
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
                    'https://services.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
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
                  markers: polygonPoints.map((point) {
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
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Aksi: Temukan posisi pengguna
        },
        label: const Text('Temukan saya'),
        icon: Image.asset(
          'assets/cursor.png', // Gunakan file PNG icon cursor
          width: 20,
          height: 20,
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 4,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Color(0xFF7ACE34), width: 0.2),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  // Aksi: mulai mode berjalan
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF7ACE34), width: 1.5),
                  foregroundColor: Color(0xFF7ACE34),
                ),
                child: const Text('Dengan berjalan'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  // Aksi: tambah titik secara manual
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xFF7ACE34),
                ),
                child: const Text('Tambahkan batas'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
