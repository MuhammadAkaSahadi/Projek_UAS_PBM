import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http_parser/http_parser.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:projek_uas/screen/KebunSaya/kebunSaya.dart';
import 'package:screenshot/screenshot.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

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
  List<LatLng> polygonPoints = [];
  LatLng? userLocation;
  final ScreenshotController screenshotController = ScreenshotController();
  final MapController _mapController = MapController();
  bool _isSubmitting = false; // Flag untuk mencegah multiple submissions
  bool _isDisposed = false; // Flag untuk tracking disposal

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<void> _getUserLocation() async {
    if (_isDisposed) return;
    
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Layanan lokasi tidak aktif')),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Izin lokasi ditolak')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Izin lokasi ditolak permanen')),
          );
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      // Cek mounted sebelum setState
      if (mounted) {
        safeSetState(() {
          userLocation = LatLng(position.latitude, position.longitude);
        });

        // Cek mounted sebelum menggunakan _mapController
        if (mounted) {
          _mapController.move(userLocation!, 18);
        }
      }
    } catch (e) {
      if (mounted) {
        _showMessage(context, 'Error mendapatkan lokasi: $e');
      }
    }
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

  Future<String?> uploadToCloudinary(Uint8List imageBytes) async {
    if (_isDisposed) return null;
    
    try {
      final cloudName = 'dxwzt2mhr';
      final uploadPreset = 'PocketFarm';

      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            imageBytes,
            filename: 'polygon.png',
            contentType: MediaType('image', 'png'),
          ),
        );

      final response = await request.send();
      
      // Cek mounted setelah async operation
      if (!mounted) return null;
      
      if (response.statusCode == 200) {
        final res = await http.Response.fromStream(response);
        if (!mounted) return null;
        
        final data = json.decode(res.body);
        return data['secure_url'];
      } else {
        final res = await http.Response.fromStream(response);
        if (mounted) {
          print('Cloudinary upload failed: ${response.statusCode}');
          print('Response body: ${res.body}');
        }
        return null;
      }
    } catch (e) {
      if (mounted) {
        print('Cloudinary upload error: $e');
      }
      return null;
    }
  }

  Future<void> _submitPolygon() async {
    // Prevent multiple submissions
    if (_isSubmitting || _isDisposed) return;
    
    if (polygonPoints.length < 3) {
      if (mounted) {
        _showMessage(
          context,
          "Minimal 3 titik diperlukan untuk membuat polygon.",
        );
      }
      return;
    }

    _isSubmitting = true;

    try {
      // Show loading indicator
      if (mounted) {
        _showMessage(context, "Menyimpan data lahan...");
      }

      Uint8List? image = await screenshotController.capture();
      if (!mounted || image == null) {
        _isSubmitting = false;
        return;
      }

      // Upload ke Cloudinary
      String? imageUrl = await uploadToCloudinary(image);
      if (!mounted) {
        _isSubmitting = false;
        return;
      }
      
      if (imageUrl == null) {
        if (mounted) {
          _showMessage(context, "Gagal mengunggah gambar ke Cloudinary.");
        }
        _isSubmitting = false;
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      if (!mounted) {
        _isSubmitting = false;
        return;
      }
      
      final token = prefs.getString('token');
      if (token == null || JwtDecoder.isExpired(token)) {
        if (mounted) {
          _showMessage(context, "Token tidak tersedia atau telah kadaluarsa.");
        }
        _isSubmitting = false;
        return;
      }

      final decoded = JwtDecoder.decode(token);
      final userId = _extractUserIdFromToken(decoded);
      if (userId == null) {
        if (mounted) {
          _showMessage(context, "ID pengguna tidak ditemukan dalam token.");
        }
        _isSubmitting = false;
        return;
      }

      final nama = prefs.getString('draft_nama_lahan');
      final satuan = prefs.getString('draft_satuan_luas');
      final luas = prefs.getDouble('draft_luas_lahan');
      final lokasi = prefs.getString('draft_lokasi_lahan');
      final centroid = _hitungCentroid(polygonPoints);

      if ([nama, satuan, luas].contains(null)) {
        if (mounted) {
          _showMessage(context, "Data lahan belum lengkap.");
        }
        _isSubmitting = false;
        return;
      }

      final uri = Uri.parse("http://192.168.43.143:5042/api/Laporan/polygon-image");

      final body = {
        "Nama_Lahan": nama,
        "Luas_Lahan": luas,
        "Satuan_Luas": satuan,
        "Koordinat": lokasi,
        "Centroid_Lat": centroid.latitude,
        "Centroid_Lng": centroid.longitude,
        "Id_Users": userId,
        "Polygon_Img": imageUrl,
      };

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      // Cek mounted setelah HTTP request
      if (!mounted) {
        _isSubmitting = false;
        return;
      }

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final idLahan = result['id_lahan'];

        _showMessage(context, "Berhasil menyimpan lahan dengan ID: $idLahan");
        
        // Delay untuk memberikan waktu snackbar ditampilkan
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MappingPage(idLahan: idLahan),
            ),
          );
        }
      } else {
        _showMessage(context, "Gagal menyimpan lahan: ${response.body}");
      }
    } catch (e) {
      if (mounted) {
        _showMessage(context, "Terjadi kesalahan: $e");
      }
    } finally {
      _isSubmitting = false;
    }
  }

  void _showMessage(BuildContext context, String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
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

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    if (mounted && !_isSubmitting) {
      safeSetState(() {
        polygonPoints.add(point);
      });
    }
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
            onPressed: _isSubmitting ? null : _submitPolygon,
            child: _isSubmitting
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
      ),
      body: Stack(
        children: [
          Screenshot(
            controller: screenshotController,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                center: LatLng(-6.2, 106.816666),
                zoom: 16.0,
                onTap: _onMapTap,
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
          ),
          // Loading overlay
          if (_isSubmitting)
            Container(
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
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSubmitting ? null : _getUserLocation,
        label: const Text('Temukan saya'),
        icon: const Icon(Icons.gps_fixed, color: Colors.black),
        backgroundColor: _isSubmitting ? Colors.grey : Colors.white,
        foregroundColor: Colors.black,
      ),
    );
  }
}