// lib/providers/lahan_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class LahanProvider with ChangeNotifier {
  List<Map<String, dynamic>> _lahanList = [];
  bool _isLoading = false;
  String? _error;
  
  static const String baseUrl = 'http://192.168.43.143:5042/api/Laporan';

  List<Map<String, dynamic>> get lahanList => _lahanList;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isEmpty => _lahanList.isEmpty;

  // Method untuk normalisasi data dari API
  Map<String, dynamic> _normalizeLahanData(Map<String, dynamic> rawData) {
    return {
      // Selalu gunakan snake_case sebagai standard
      'id_lahan': rawData['id_lahan'] ?? rawData['Id_Lahan'],
      'nama_lahan': rawData['nama_lahan'] ?? rawData['Nama_Lahan'],
      'luas_lahan': rawData['luas_lahan'] ?? rawData['Luas_Lahan'],
      'satuan_luas': rawData['satuan_luas'] ?? rawData['Satuan_Luas'] ?? 'Ha',
      'koordinat': rawData['koordinat'] ?? rawData['Koordinat'] ?? '',
      'centroid_lat': rawData['centroid_lat'] ?? rawData['Centroid_Lat'],
      'centroid_lng': rawData['centroid_lng'] ?? rawData['Centroid_Lng'],
      'polygon_img': rawData['polygon_img'] ?? rawData['Polygon_Img'],
      'id_users': rawData['id_users'] ?? rawData['Id_Users'],
    };
  }

  // Fetch semua lahan
  Future<void> fetchLahan(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/lahan'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('=== FETCH LAHAN DEBUG ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Pastikan data adalah List
        if (data is List) {
          _lahanList = data.map<Map<String, dynamic>>((lahan) {
            final normalized = _normalizeLahanData(Map<String, dynamic>.from(lahan));
            print('Normalized Data: $normalized');
            return normalized;
          }).toList();
        } else {
          print('Data bukan List: $data');
          _lahanList = [];
        }
        
        _error = null;
        print('Total Lahan Loaded: ${_lahanList.length}');
        
        // Debug setiap lahan
        for (int i = 0; i < _lahanList.length; i++) {
          print('Lahan $i: ${_lahanList[i]}');
        }
        
      } else {
        _error = 'Gagal mengambil data: ${response.statusCode} - ${response.body}';
        print('Error: $_error');
      }
    } catch (e) {
      _error = 'Kesalahan saat mengambil data: $e';
      print('Exception: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Tambah lahan baru
  Future<bool> addLahan({
    required String token,
    required String namaLahan,
    required double luasLahan,
    required String satuanLuas,
    required String koordinat,
    required double centroidLat,
    required double centroidLng,
    required int userId,
    required String polygonImg,
  }) async {
    try {
      final body = {
        "Nama_Lahan": namaLahan,
        "Luas_Lahan": luasLahan,
        "Satuan_Luas": satuanLuas,
        "Koordinat": koordinat,
        "Centroid_Lat": centroidLat,
        "Centroid_Lng": centroidLng,
        "Id_Users": userId,
        "Polygon_Img": polygonImg,
      };

      print('=== ADD LAHAN REQUEST ===');
      print('Body: ${jsonEncode(body)}');

      final response = await http.post(
        Uri.parse("$baseUrl/polygon-image"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      print('Add Lahan Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        
        // Buat data lahan baru dengan struktur yang konsisten
        final newLahan = _normalizeLahanData({
          'id_lahan': result['id_lahan'] ?? result['Id_Lahan'],
          'nama_lahan': namaLahan,
          'luas_lahan': luasLahan,
          'satuan_luas': satuanLuas,
          'koordinat': koordinat,
          'centroid_lat': centroidLat,
          'centroid_lng': centroidLng,
          'polygon_img': polygonImg,
          'id_users': userId,
        });
        
        _lahanList.add(newLahan);
        notifyListeners();
        return true;
      } else {
        _error = 'Gagal menambah lahan: ${response.statusCode} - ${response.body}';
        notifyListeners();
      }
      
      return false;
    } catch (e) {
      _error = 'Gagal menambah lahan: $e';
      notifyListeners();
      return false;
    }
  }

  // Hapus lahan
  Future<bool> deleteLahan(String token, int idLahan) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/lahan/$idLahan'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        _lahanList.removeWhere((lahan) => lahan['id_lahan'] == idLahan);
        notifyListeners();
        return true;
      } else {
        _error = 'Gagal menghapus lahan: ${response.statusCode} - ${response.body}';
        notifyListeners();
      }
      
      return false;
    } catch (e) {
      _error = 'Gagal menghapus lahan: $e';
      notifyListeners();
      return false;
    }
  }

  // Get lahan by ID
  Map<String, dynamic>? getLahanById(int idLahan) {
    try {
      final lahan = _lahanList.firstWhere((lahan) => lahan['id_lahan'] == idLahan);
      print('=== GET LAHAN BY ID DEBUG ===');
      print('Requested ID: $idLahan');
      print('Found Lahan: $lahan');
      print('==============================');
      return lahan;
    } catch (e) {
      print('LahanProvider: Lahan dengan ID $idLahan tidak ditemukan');
      print('LahanProvider: Available IDs: ${_lahanList.map((l) => l['id_lahan']).toList()}');
      print('LahanProvider: Available Lahan: $_lahanList');
      return null;
    }
  }

  // Update lahan
  Future<bool> updateLahan({
    required String token,
    required int idLahan,
    required String namaLahan,
    required double luasLahan,
    required String satuanLuas,
    required String koordinat,
    double? centroidLat,
    double? centroidLng,
  }) async {
    try {
      final body = {
        "nama_lahan": namaLahan,
        "luas_lahan": luasLahan,
        "satuan_luas": satuanLuas,
        "koordinat": koordinat,
      };

      // Tambahkan centroid jika ada
      if (centroidLat != null) body["centroid_lat"] = centroidLat;
      if (centroidLng != null) body["centroid_lng"] = centroidLng;

      final response = await http.put(
        Uri.parse('$baseUrl/lahan/$idLahan'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        // Update local data dengan struktur yang konsisten
        final index = _lahanList.indexWhere((lahan) => lahan['id_lahan'] == idLahan);
        if (index != -1) {
          _lahanList[index] = _normalizeLahanData({
            ..._lahanList[index], // Preserve existing data
            'nama_lahan': namaLahan,
            'luas_lahan': luasLahan,
            'satuan_luas': satuanLuas,
            'koordinat': koordinat,
            if (centroidLat != null) 'centroid_lat': centroidLat,
            if (centroidLng != null) 'centroid_lng': centroidLng,
          });
          notifyListeners();
        }
        return true;
      } else {
        _error = 'Gagal mengupdate lahan: ${response.statusCode} - ${response.body}';
        notifyListeners();
      }
      
      return false;
    } catch (e) {
      _error = 'Gagal mengupdate lahan: $e';
      notifyListeners();
      return false;
    }
  }

  // Helper methods untuk format data
  String formatLuasLahan(int idLahan) {
    final lahan = getLahanById(idLahan);
    if (lahan == null) return '-';
    
    final luasLahan = lahan['luas_lahan'];
    final satuanLuas = lahan['satuan_luas'] ?? 'Ha';
    
    if (luasLahan == null) return '-';
    
    return '$luasLahan $satuanLuas';
  }

  String formatKoordinat(int idLahan) {
    final lahan = getLahanById(idLahan);
    if (lahan == null) return '-';
    
    final koordinat = lahan['koordinat'];
    if (koordinat == null || koordinat.toString().isEmpty) return '-';
    
    final koordinatStr = koordinat.toString();
    // Jika koordinat berupa string panjang, ambil beberapa karakter pertama
    if (koordinatStr.length > 50) {
      return '${koordinatStr.substring(0, 47)}...';
    }
    
    return koordinatStr;
  }

  String formatCentroid(int idLahan, String type) {
    final lahan = getLahanById(idLahan);
    if (lahan == null) return '-';
    
    dynamic value;
    if (type == 'lat') {
      value = lahan['centroid_lat'];
    } else {
      value = lahan['centroid_lng'];
    }
    
    if (value == null) return '-';
    
    // Format dengan 6 desimal untuk koordinat
    if (value is double) {
      return value.toStringAsFixed(6);
    } else if (value is String) {
      try {
        final doubleValue = double.parse(value);
        return doubleValue.toStringAsFixed(6);
      } catch (e) {
        return value;
      }
    }
    
    return value.toString();
  }

  String getNamaLahan(int idLahan, {String? fallback}) {
    final lahan = getLahanById(idLahan);
    if (lahan == null) return fallback ?? 'Lahan Tidak Ditemukan';
    
    return lahan['nama_lahan'] ?? fallback ?? 'Nama Lahan Tidak Tersedia';
  }

  // Debug method untuk membantu troubleshooting
  void debugPrintLahan(int idLahan) {
    final lahan = getLahanById(idLahan);
    print('=== DEBUG LAHAN PROVIDER ===');
    print('ID Lahan: $idLahan');
    print('Data Lahan: $lahan');
    if (lahan != null) {
      print('Keys: ${lahan.keys.toList()}');
      lahan.forEach((key, value) {
        print('$key: $value (${value.runtimeType})');
      });
    }
    print('Total Lahan: ${_lahanList.length}');
    print('All IDs: ${_lahanList.map((l) => l['id_lahan']).toList()}');
    print('============================');
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Refresh data
  Future<void> refresh(String token) async {
    await fetchLahan(token);
  }

  // Clear all data (for logout)
  void clearData() {
    _lahanList.clear();
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  // Check if lahan exists
  bool lahanExists(int idLahan) {
    return _lahanList.any((lahan) => lahan['id_lahan'] == idLahan);
  }

  // Get lahan count
  int get lahanCount => _lahanList.length;

  // Method untuk mendapatkan lahan dengan pagination (jika diperlukan)
  List<Map<String, dynamic>> getLahanPaginated({int page = 0, int limit = 10}) {
    final startIndex = page * limit;
    final endIndex = (startIndex + limit).clamp(0, _lahanList.length);
    
    if (startIndex >= _lahanList.length) return [];
    
    return _lahanList.sublist(startIndex, endIndex);
  }

  // Search lahan by name
  List<Map<String, dynamic>> searchLahan(String query) {
    if (query.isEmpty) return _lahanList;
    
    return _lahanList.where((lahan) {
      final namaLahan = (lahan['nama_lahan'] ?? '').toString().toLowerCase();
      return namaLahan.contains(query.toLowerCase());
    }).toList();
  }
}