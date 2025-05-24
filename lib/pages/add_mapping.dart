import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:projek_uas/screen/kebunSaya.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

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
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Layanan lokasi tidak aktif')),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Izin lokasi ditolak')));
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Izin lokasi ditolak permanen')),
      );
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
      userLocation = LatLng(position.latitude, position.longitude);
    });

    _mapController.move(userLocation!, 18);
  }

  LatLng _hitungCentroid(List<LatLng> points) {
    double lat = 0.0;
    double lng = 0.0;
    for (var p in points) {
      lat += p.latitude;
      lng += p.longitude;
    }
    return LatLng(lat / points.length, lng / points.length);
  }

  Future<void> _submitPolygon() async {
    if (polygonPoints.length < 3) {
      _showMessage(
        context,
        "Minimal 3 titik diperlukan untuk membuat polygon.",
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null || JwtDecoder.isExpired(token)) {
      _showMessage(context, "Token tidak tersedia atau telah kadaluarsa.");
      return;
    }

    final decoded = JwtDecoder.decode(token);
    final userId = _extractUserIdFromToken(decoded);
    if (userId == null) {
      _showMessage(context, "ID pengguna tidak ditemukan dalam token.");
      return;
    }

    final nama = prefs.getString('draft_nama_lahan');
    final satuan = prefs.getString('draft_satuan_luas');
    final luas = prefs.getDouble('draft_luas_lahan');

    // Konversi koordinat ke JSON string
    final lokasiList = prefs.getString('draft_lokasi_lahan');

    final centroid = _hitungCentroid(polygonPoints);

    if ([nama, satuan, luas].contains(null)) {
      _showMessage(context, "Data lahan belum lengkap.");
      return;
    }

    final lahanData = {
      'Nama_Lahan': nama,
      'Luas_Lahan': luas,
      'Satuan_Luas': satuan,
      'Koordinat': lokasiList,
      'Centroid_Lat': centroid.latitude,
      'Centroid_Lng': centroid.longitude,
      'Id_Users': userId,
    };

    print("Data yang dikirim ke server:");
    print(jsonEncode(lahanData));

    final lahanRes = await http.post(
      Uri.parse('http://192.168.43.143:5042/api/Laporan/lahan'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(lahanData),
    );

    if (lahanRes.statusCode != 200) {
      String errorMsg = "Gagal menambahkan lahan.";
      try {
        if (lahanRes.body.isNotEmpty) {
          final msgJson = jsonDecode(lahanRes.body);
          errorMsg = msgJson['message'] ?? errorMsg;
        }
      } catch (e) {
        errorMsg = "$errorMsg (Invalid JSON: $e)";
      }
      _showMessage(context, errorMsg);
      return;
    }

    final lahanJson = jsonDecode(lahanRes.body);
    final idLahan = lahanJson['id_lahan'];
    if (idLahan == null) {
      _showMessage(context, "ID lahan tidak ditemukan di respons server.");
      return;
    }

    // Tampilkan snackbar
    _showMessage(context, "Berhasil menyimpan lahan dengan ID: $idLahan");

    // Navigasi ke halaman MappingPage (ganti dengan nama yang sesuai)
    Future.delayed(const Duration(milliseconds: 500), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  MappingPage(idLahan: idLahan), // ganti sesuai widget kamu
        ),
      );
    });
  }

  void _showMessage(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  int? _extractUserIdFromToken(Map<String, dynamic> token) {
    // Coba semua kemungkinan field ID
    final possibleIdFields = [
      'Id_Users', // Custom claim
      'sub', // Standard JWT
      'nameid',
      'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier',
      'userId', // Alternatif lain
    ];

    for (final field in possibleIdFields) {
      final value = token[field];
      if (value != null) {
        if (value is int) return value;
        if (value is String) return int.tryParse(value);
      }
    }

    debugPrint('Token Structure: $token'); // Untuk debugging
    return null;
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
        actions: [
          TextButton(
            onPressed: _submitPolygon,
            child: const Text(
              'SIMPAN',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: LatLng(-6.2, 106.816666),
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
                userAgentPackageName: 'com.example.app',
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
                  ...polygonPoints.map(
                    (point) => Marker(
                      point: point,
                      width: 20,
                      height: 20,
                      child: const Icon(Icons.location_on, color: Colors.red),
                    ),
                  ),
                  if (userLocation != null)
                    Marker(
                      point: userLocation!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.blue,
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
        icon: const Icon(Icons.gps_fixed, color: Colors.black),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
    );
  }
}
