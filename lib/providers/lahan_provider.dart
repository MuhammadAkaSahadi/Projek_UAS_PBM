// lib/providers/lahan_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:projek_uas/providers/auth_provider.dart';
import 'package:projek_uas/helper/auth_helper.dart';

class LahanProvider with ChangeNotifier {
  List<Map<String, dynamic>> _lahanList = [];
  bool _isLoading = false;
  String? _error;
  
  static const String baseUrl = 'http://192.168.43.143:5042/api/Laporan';

  // Getter untuk mengakses AuthProvider
  AuthProvider? _authProvider;
  
  // Method untuk set AuthProvider reference
  void setAuthProvider(AuthProvider authProvider) {
    _authProvider = authProvider;
  }

  // Getters
  List<Map<String, dynamic>> get lahanList => _lahanList;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isEmpty => _lahanList.isEmpty;

  // Helper method untuk mendapatkan token dengan konsisten
  Future<String?> _getAuthToken() async {
    try {
      // Prioritas 1: Gunakan AuthProvider jika tersedia
      if (_authProvider != null) {
        return _authProvider!.token;
      }
      
      // Prioritas 2: Gunakan AuthHelper sebagai fallback
      return await AuthHelper.getToken();
    } catch (e) {
      print('Error getting auth token: $e');
      return null;
    }
  }

  // Helper method untuk mendapatkan user ID
  Future<int?> _getCurrentUserId() async {
    try {
      // Prioritas 1: Gunakan AuthProvider jika tersedia
      if (_authProvider != null) {
        return _authProvider!.userId;
      }
      
      // Prioritas 2: Gunakan AuthHelper sebagai fallback
      return await AuthHelper.getCurrentUserId();
    } catch (e) {
      print('Error getting current user ID: $e');
      return null;
    }
  }

  // Helper method untuk mendapatkan auth headers
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _getAuthToken();
    
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }

  // Helper method untuk validasi autentikasi
  Future<bool> _validateAuthentication() async {
    try {
      // Prioritas 1: Gunakan AuthProvider jika tersedia
      if (_authProvider != null) {
        return _authProvider!.isAuthenticated;
      }
      
      // Prioritas 2: Gunakan AuthHelper sebagai fallback
      return await AuthHelper.isAuthenticated();
    } catch (e) {
      print('Error validating authentication: $e');
      return false;
    }
  }

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

  // Fetch semua lahan (revised)
  Future<void> fetchLahan() async {
    print('=== FETCH LAHAN AUTH CHECK ===');
    
    // Validasi authentication
    final isAuthenticated = await _validateAuthentication();
    if (!isAuthenticated) {
      _error = 'Anda harus login terlebih dahulu untuk mengakses data lahan.';
      print('❌ Authentication required');
      notifyListeners();
      return;
    }

    print('✅ Authentication validated');

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/lahan'),
        headers: headers,
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
        
      } else if (response.statusCode == 401) {
        _error = 'Token tidak valid atau sudah kadaluarsa. Silakan login kembali.';
        print('❌ Unauthorized access');
      } else if (response.statusCode == 403) {
        _error = 'Akses ditolak. Anda tidak memiliki izin untuk mengakses data lahan.';
        print('❌ Forbidden access');
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

  // Tambah lahan baru (revised)
  Future<bool> addLahan({
    required String namaLahan,
    required double luasLahan,
    required String satuanLuas,
    required String koordinat,
    required double centroidLat,
    required double centroidLng,
    required String polygonImg,
    int? customUserId, // Optional, jika tidak diisi akan menggunakan current user
  }) async {
    print('=== ADD LAHAN AUTH CHECK ===');
    
    // Validasi authentication
    final isAuthenticated = await _validateAuthentication();
    if (!isAuthenticated) {
      _error = 'Anda harus login terlebih dahulu untuk menambah lahan.';
      print('❌ Authentication required');
      notifyListeners();
      return false;
    }

    // Dapatkan user ID
    final userId = customUserId ?? await _getCurrentUserId();
    if (userId == null) {
      _error = 'Gagal mendapatkan informasi user';
      print('❌ Failed to get user ID');
      notifyListeners();
      return false;
    }

    print('✅ Authentication validated, User ID: $userId');

    _isLoading = true;
    _error = null;
    notifyListeners();

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

      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse("$baseUrl/polygon-image"),
        headers: headers,
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
        _error = null;
        _isLoading = false;
        notifyListeners();
        return true;
      } else if (response.statusCode == 401) {
        _error = 'Token tidak valid atau sudah kadaluarsa. Silakan login kembali.';
      } else if (response.statusCode == 403) {
        _error = 'Akses ditolak. Anda tidak memiliki izin untuk menambah lahan.';
      } else {
        _error = 'Gagal menambah lahan: ${response.statusCode} - ${response.body}';
      }
      
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Gagal menambah lahan: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Hapus lahan (revised)
  Future<bool> deleteLahan(int idLahan) async {
    print('=== DELETE LAHAN AUTH CHECK ===');
    
    // Validasi authentication
    final isAuthenticated = await _validateAuthentication();
    if (!isAuthenticated) {
      _error = 'Anda harus login terlebih dahulu untuk menghapus lahan.';
      print('❌ Authentication required');
      notifyListeners();
      return false;
    }

    print('✅ Authentication validated');

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/lahan/$idLahan'),
        headers: headers,
      );

      print('Delete Lahan Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        _lahanList.removeWhere((lahan) => lahan['id_lahan'] == idLahan);
        _error = null;
        _isLoading = false;
        notifyListeners();
        return true;
      } else if (response.statusCode == 401) {
        _error = 'Token tidak valid atau sudah kadaluarsa. Silakan login kembali.';
      } else if (response.statusCode == 403) {
        _error = 'Akses ditolak. Anda tidak memiliki izin untuk menghapus lahan.';
      } else if (response.statusCode == 404) {
        _error = 'Lahan tidak ditemukan.';
      } else {
        _error = 'Gagal menghapus lahan: ${response.statusCode} - ${response.body}';
      }
      
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Gagal menghapus lahan: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update lahan (revised)
  Future<bool> updateLahan({
    required int idLahan,
    required String namaLahan,
    required double luasLahan,
    required String satuanLuas,
    required String koordinat,
    double? centroidLat,
    double? centroidLng,
  }) async {
    print('=== UPDATE LAHAN AUTH CHECK ===');
    
    // Validasi authentication
    final isAuthenticated = await _validateAuthentication();
    if (!isAuthenticated) {
      _error = 'Anda harus login terlebih dahulu untuk mengupdate lahan.';
      print('❌ Authentication required');
      notifyListeners();
      return false;
    }

    print('✅ Authentication validated');

    _isLoading = true;
    _error = null;
    notifyListeners();

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

      print('=== UPDATE LAHAN REQUEST ===');
      print('ID Lahan: $idLahan');
      print('Body: ${jsonEncode(body)}');

      final headers = await _getAuthHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/lahan/$idLahan'),
        headers: headers,
        body: jsonEncode(body),
      );

      print('Update Lahan Response: ${response.statusCode} - ${response.body}');

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
        }
        _error = null;
        _isLoading = false;
        notifyListeners();
        return true;
      } else if (response.statusCode == 401) {
        _error = 'Token tidak valid atau sudah kadaluarsa. Silakan login kembali.';
      } else if (response.statusCode == 403) {
        _error = 'Akses ditolak. Anda tidak memiliki izin untuk mengupdate lahan.';
      } else if (response.statusCode == 404) {
        _error = 'Lahan tidak ditemukan.';
      } else {
        _error = 'Gagal mengupdate lahan: ${response.statusCode} - ${response.body}';
      }
      
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Gagal mengupdate lahan: $e';
      _isLoading = false;
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

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    return await _validateAuthentication();
  }

  // Get current user ID
  Future<int?> getCurrentUserId() async {
    return await _getCurrentUserId();
  }

  // Get lahan by current user
  Future<List<Map<String, dynamic>>> getLahanByCurrentUser() async {
    final userId = await _getCurrentUserId();
    if (userId == null) return [];
    
    return _lahanList.where((lahan) => lahan['id_users'] == userId).toList();
  }

  // Get lahan by user ID
  List<Map<String, dynamic>> getLahanByUser(int userId) {
    return _lahanList.where((lahan) => lahan['id_users'] == userId).toList();
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

  // Debug method untuk melihat auth state
  Future<void> debugAuthState() async {
    print('=== LAHAN PROVIDER AUTH DEBUG ===');
    print('AuthProvider available: ${_authProvider != null}');
    if (_authProvider != null) {
      print('AuthProvider - Authenticated: ${_authProvider!.isAuthenticated}');
      print('AuthProvider - User ID: ${_authProvider!.userId}');
      print('AuthProvider - Username: ${_authProvider!.username}');
      print('AuthProvider - User Role: ${_authProvider!.userRole}');
    }
    
    print('AuthHelper - Authenticated: ${await AuthHelper.isAuthenticated()}');
    print('AuthHelper - User ID: ${await AuthHelper.getCurrentUserId()}');
    print('AuthHelper - Username: ${await AuthHelper.getCurrentUsername()}');
    print('AuthHelper - User Role: ${await AuthHelper.getCurrentUserRole()}');
    print('==================================');
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Refresh data (revised)
  Future<void> refresh() async {
    await fetchLahan();
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

  // Validate lahan data before submit
  Map<String, String?> validateLahanData({
    required String namaLahan,
    required double luasLahan,
    required String satuanLuas,
    required String koordinat,
    required double centroidLat,
    required double centroidLng,
  }) {
    final errors = <String, String?>{};

    if (namaLahan.trim().isEmpty) {
      errors['nama_lahan'] = 'Nama lahan tidak boleh kosong';
    } else if (namaLahan.length > 100) {
      errors['nama_lahan'] = 'Nama lahan tidak boleh lebih dari 100 karakter';
    }

    if (luasLahan <= 0) {
      errors['luas_lahan'] = 'Luas lahan harus lebih besar dari 0';
    }

    if (satuanLuas.trim().isEmpty) {
      errors['satuan_luas'] = 'Satuan luas tidak boleh kosong';
    }

    if (koordinat.trim().isEmpty) {
      errors['koordinat'] = 'Koordinat tidak boleh kosong';
    }

    // Validasi koordinat latitude (-90 to 90)
    if (centroidLat < -90 || centroidLat > 90) {
      errors['centroid_lat'] = 'Latitude harus antara -90 hingga 90';
    }

    // Validasi koordinat longitude (-180 to 180)
    if (centroidLng < -180 || centroidLng > 180) {
      errors['centroid_lng'] = 'Longitude harus antara -180 hingga 180';
    }

    return errors;
  }

  // Validate authentication before performing operations
  Future<Map<String, String?>> validateAuthAccess() async {
    final errors = <String, String?>{};

    final isAuth = await isAuthenticated();
    if (!isAuth) {
      errors['authentication'] = 'Anda harus login terlebih dahulu';
      return errors;
    }

    return errors;
  }
}