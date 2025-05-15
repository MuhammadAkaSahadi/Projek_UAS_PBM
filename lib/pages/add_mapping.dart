import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:projek_uas/pages/add_mapping_berjalan.dart';

class AddMappingPage extends StatefulWidget {
  const AddMappingPage({super.key});

  @override
  State<AddMappingPage> createState() => _AddMappingPageState();
}

class _AddMappingPageState extends State<AddMappingPage> {
  List<LatLng> polygonPoints = [];
  LatLng? userLocation;
  final MapController _mapController = MapController();

  Future<void> _getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Cek apakah service lokasi aktif
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Layanan lokasi tidak aktif')),
      );
      return;
    }

    // Cek izin
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Izin lokasi ditolak')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Izin lokasi ditolak permanen')),
      );
      return;
    }

    // Dapatkan lokasi saat ini
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      userLocation = LatLng(position.latitude, position.longitude);
    });

    // Pindahkan map ke lokasi user
    _mapController.move(userLocation!, 18);
  }

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
            mapController: _mapController,
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
              MarkerLayer(
                markers: [
                  // Titik-titik polygon
                  ...polygonPoints.map((point) {
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
                  }),

                  // Titik user (ikon merah besar)
                  if (userLocation != null)
                    Marker(
                      point: userLocation!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.red,
                        size: 30,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _getUserLocation,
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
            top: BorderSide(color: Color(0xFF4CAF50), width: 0.2),
          ),
        ),
        child: Row(
          children: [
            Expanded(
  child: OutlinedButton(
    onPressed: () {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Konfirmasi'),
            content: const Text('Pastikan Anda sudah berada di lokasi lahan sebelum memulai pengukuran.'),
            actions: [
              TextButton(
                child: const Text('Tidak'),
                onPressed: () {
                  Navigator.of(context).pop(); // Tutup dialog
                },
              ),
              TextButton(
                child: const Text('Ya'),
                onPressed: () {
                  Navigator.of(context).pop(); // Tutup dialog
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddMappingBerjalan()),
                  );
                },
              ),
            ],
          );
        },
      );
    },
    style: OutlinedButton.styleFrom(
      side: const BorderSide(color: Color(0xFF4CAF50), width: 1.5),
      foregroundColor: const Color(0xFF4CAF50),
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
                  backgroundColor: const Color(0xFF4CAF50),
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
