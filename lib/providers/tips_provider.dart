// lib/providers/tips_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:projek_uas/providers/auth_provider.dart';
import 'package:projek_uas/helper/auth_helper.dart';

class TipsProvider with ChangeNotifier {
  final List<Map<String, dynamic>> _tips = [];
  final List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  String? _error;
  
  static const String baseUrl = 'http://192.168.43.143:5042/api/Tips';

  // Getter untuk mengakses AuthProvider
  AuthProvider? _authProvider;
  
  // Method untuk set AuthProvider reference
  void setAuthProvider(AuthProvider authProvider) {
    _authProvider = authProvider;
  }

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Map<String, dynamic>> get tips => _tips;
  List<Map<String, dynamic>> get searchResults => _searchResults;

  // Helper method untuk validasi admin menggunakan AuthProvider
  Future<bool> _validateAdminAccess() async {
    try {
      // Prioritas 1: Gunakan AuthProvider jika tersedia
      if (_authProvider != null) {
        final isAuthenticated = _authProvider!.isAuthenticated;
        final isAdmin = _authProvider!.isAdmin;
        
        print('Admin validation via AuthProvider - Auth: $isAuthenticated, Admin: $isAdmin');
        return isAuthenticated && isAdmin;
      }
      
      // Prioritas 2: Gunakan AuthHelper sebagai fallback
      final hasValidToken = await AuthHelper.isAuthenticated();
      final isAdmin = await AuthHelper.isAdmin();
      
      print('Admin validation via AuthHelper - Auth: $hasValidToken, Admin: $isAdmin');
      return hasValidToken && isAdmin;
    } catch (e) {
      print('Error validating admin access: $e');
      return false;
    }
  }

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

  // Fetch all tips (tetap public, tidak perlu admin)
  Future<void> fetchAllTips() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('=== FETCH ALL TIPS DEBUG ===');
      print('URL: $baseUrl');

      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
      );

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Parsed Data: $data');
        
        if (data is Map<String, dynamic> && data['success'] == true) {
          final List<dynamic> tipsData = data['data'] ?? [];
          _tips.clear();
          _tips.addAll(tipsData.cast<Map<String, dynamic>>());
          _error = null;
          print('✅ Tips loaded successfully: ${_tips.length} items');
        } else {
          _error = 'Format response tidak valid';
          print('❌ Invalid response format');
        }
      } else {
        _error = 'Gagal mengambil data tips: ${response.body}';
        print('❌ Error fetching tips: $_error');
      }
    } catch (e) {
      _error = 'Kesalahan saat mengambil tips: $e';
      print('❌ Exception fetching tips: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Add new tip - HANYA ADMIN (menggunakan AuthProvider)
  Future<bool> addTip({
    required String judul,
    required String deskripsi,
    String? gambar,
    required DateTime tanggalTips,
    int? customUserId, // Optional, jika tidak diisi akan menggunakan current user
  }) async {
    print('=== ADD TIP ADMIN CHECK ===');
    
    // Validasi admin access
    final hasAdminAccess = await _validateAdminAccess();
    if (!hasAdminAccess) {
      _error = 'Akses ditolak. Hanya admin yang dapat menambahkan tips.';
      print('❌ Admin access denied');
      notifyListeners();
      return false;
    }

    print('✅ Admin access granted');

    // Dapatkan user ID
    final userId = customUserId ?? await _getCurrentUserId();
    if (userId == null) {
      _error = 'Gagal mendapatkan informasi user';
      print('❌ Failed to get user ID');
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('=== ADD TIP DEBUG ===');
      print('Judul: $judul');
      print('Deskripsi: $deskripsi');
      print('Gambar: $gambar');
      print('Tanggal: $tanggalTips');
      print('ID Users: $userId');

      final requestBody = {
        'Judul': judul,
        'Deskripsi': deskripsi,
        'Gambar': gambar ?? '',
        'Tanggal_Tips': tanggalTips.toIso8601String(),
        'Id_Users': userId,
      };

      print('Request Body: ${jsonEncode(requestBody)}');

      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      print('Add Response status: ${response.statusCode}');
      print('Add Response body: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          print('✅ Tip added successfully with ID: ${result['id_tips']}');
          
          // Refresh data setelah berhasil menambah
          await fetchAllTips();
          
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          throw Exception(result['message'] ?? 'Gagal menambahkan tip');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Token tidak valid atau sudah kadaluarsa');
      } else if (response.statusCode == 403) {
        throw Exception('Akses ditolak. Hanya admin yang dapat menambahkan tips.');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Gagal menambahkan tip');
      }

    } catch (e) {
      _error = 'Gagal menambahkan tip: $e';
      _isLoading = false;
      notifyListeners();
      print('❌ Error adding tip: $e');
      return false;
    }
  }

  // Update existing tip - HANYA ADMIN (menggunakan AuthProvider)
  Future<bool> updateTip({
    required int idTips,
    required String judul,
    required String deskripsi,
    String? gambar,
    required DateTime tanggalTips,
  }) async {
    print('=== UPDATE TIP ADMIN CHECK ===');
    
    // Validasi admin access
    final hasAdminAccess = await _validateAdminAccess();
    if (!hasAdminAccess) {
      _error = 'Akses ditolak. Hanya admin yang dapat mengupdate tips.';
      print('❌ Admin access denied');
      notifyListeners();
      return false;
    }

    print('✅ Admin access granted');

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('=== UPDATE TIP DEBUG ===');
      print('ID Tips: $idTips');
      print('Judul: $judul');
      print('Deskripsi: $deskripsi');
      print('Gambar: $gambar');
      print('Tanggal: $tanggalTips');

      final requestBody = {
        'Judul': judul,
        'Deskripsi': deskripsi,
        'Gambar': gambar ?? '',
        'Tanggal_Tips': tanggalTips.toIso8601String(),
      };

      print('Update Request Body: ${jsonEncode(requestBody)}');

      final headers = await _getAuthHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/$idTips'),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      print('Update Response status: ${response.statusCode}');
      print('Update Response body: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          print('✅ Tip updated successfully');
          
          // Refresh data setelah berhasil mengupdate
          await fetchAllTips();
          
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          throw Exception(result['message'] ?? 'Gagal mengupdate tip');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Token tidak valid atau sudah kadaluarsa');
      } else if (response.statusCode == 403) {
        throw Exception('Akses ditolak. Hanya admin yang dapat mengupdate tips.');
      } else if (response.statusCode == 404) {
        throw Exception('Tip tidak ditemukan');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Gagal mengupdate tip');
      }

    } catch (e) {
      _error = 'Gagal mengupdate tip: $e';
      _isLoading = false;
      notifyListeners();
      print('❌ Error updating tip: $e');
      return false;
    }
  }

  // Delete tip - HANYA ADMIN (menggunakan AuthProvider)
  Future<bool> deleteTip({
    required int idTips,
  }) async {
    print('=== DELETE TIP ADMIN CHECK ===');
    
    // Validasi admin access
    final hasAdminAccess = await _validateAdminAccess();
    if (!hasAdminAccess) {
      _error = 'Akses ditolak. Hanya admin yang dapat menghapus tips.';
      print('❌ Admin access denied');
      notifyListeners();
      return false;
    }

    print('✅ Admin access granted');

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('=== DELETE TIP DEBUG ===');
      print('ID Tips: $idTips');

      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/$idTips'),
        headers: headers,
      );

      print('Delete Response status: ${response.statusCode}');
      print('Delete Response body: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          print('✅ Tip deleted successfully');
          
          // Refresh data setelah berhasil menghapus
          await fetchAllTips();
          
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          throw Exception(result['message'] ?? 'Gagal menghapus tip');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Token tidak valid atau sudah kadaluarsa');
      } else if (response.statusCode == 403) {
        throw Exception('Akses ditolak. Hanya admin yang dapat menghapus tips.');
      } else if (response.statusCode == 404) {
        throw Exception('Tip tidak ditemukan');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Gagal menghapus tip');
      }

    } catch (e) {
      _error = 'Gagal menghapus tip: $e';
      _isLoading = false;
      notifyListeners();
      print('❌ Error deleting tip: $e');
      return false;
    }
  }

  // Search tips (tetap public, tidak perlu admin)
  Future<void> searchTips(String keyword) async {
    if (keyword.trim().isEmpty) {
      _searchResults.clear();
      _error = 'Keyword pencarian tidak boleh kosong';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('=== SEARCH TIPS DEBUG ===');
      print('Keyword: $keyword');
      print('URL: $baseUrl/search/${Uri.encodeComponent(keyword)}');

      final response = await http.get(
        Uri.parse('$baseUrl/search/${Uri.encodeComponent(keyword)}'),
        headers: {'Content-Type': 'application/json'},
      );

      print('Search Response status: ${response.statusCode}');
      print('Search Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data is Map<String, dynamic> && data['success'] == true) {
          final List<dynamic> searchData = data['data'] ?? [];
          _searchResults.clear();
          _searchResults.addAll(searchData.cast<Map<String, dynamic>>());
          _error = null;
          print('✅ Search completed: ${_searchResults.length} results found');
        } else {
          _error = 'Format response pencarian tidak valid';
          print('❌ Invalid search response format');
        }
      } else {
        _error = 'Gagal mencari tips: ${response.body}';
        print('❌ Error searching tips: $_error');
      }
    } catch (e) {
      _error = 'Kesalahan saat mencari tips: $e';
      print('❌ Exception searching tips: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Method untuk cek apakah user adalah admin (improved)
  Future<bool> isUserAdmin() async {
    return await _validateAdminAccess();
  }

  // Method untuk mendapatkan role user (improved)
  Future<String?> getUserRole() async {
    try {
      // Prioritas 1: Gunakan AuthProvider jika tersedia
      if (_authProvider != null) {
        return _authProvider!.userRole;
      }
      
      // Prioritas 2: Gunakan AuthHelper sebagai fallback
      return await AuthHelper.getCurrentUserRole();
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    try {
      // Prioritas 1: Gunakan AuthProvider jika tersedia
      if (_authProvider != null) {
        return _authProvider!.isAuthenticated;
      }
      
      // Prioritas 2: Gunakan AuthHelper sebagai fallback
      return await AuthHelper.isAuthenticated();
    } catch (e) {
      print('Error checking authentication: $e');
      return false;
    }
  }

  // Get tip by ID (helper method)
  Map<String, dynamic>? getTipById(int idTips) {
    try {
      return _tips.firstWhere((tip) => tip['id_tips'] == idTips);
    } catch (e) {
      return null;
    }
  }

  // Check if tip exists
  bool hasTip(int idTips) {
    return _tips.any((tip) => tip['id_tips'] == idTips);
  }

  // Get tips by user
  List<Map<String, dynamic>> getTipsByUser(int idUsers) {
    return _tips.where((tip) => tip['id_users'] == idUsers).toList();
  }

  // Get recent tips (last N tips)
  List<Map<String, dynamic>> getRecentTips([int limit = 5]) {
    final sortedTips = List<Map<String, dynamic>>.from(_tips);
    sortedTips.sort((a, b) {
      final dateA = DateTime.tryParse(a['tanggal_tips']?.toString() ?? '') ?? DateTime(1970);
      final dateB = DateTime.tryParse(b['tanggal_tips']?.toString() ?? '') ?? DateTime(1970);
      return dateB.compareTo(dateA); // Terbaru dulu
    });
    
    return sortedTips.take(limit).toList();
  }

  // Clear search results
  void clearSearchResults() {
    _searchResults.clear();
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Refresh data (alias untuk fetchAllTips)
  Future<void> refresh() async {
    await fetchAllTips();
  }

  // Check if data is empty
  bool get isEmpty => _tips.isEmpty;

  // Get total count
  int get totalTips => _tips.length;

  // Debug method - untuk development saja
  void debugPrintTips() {
    print('=== TIPS DEBUG ===');
    print('Total tips: ${_tips.length}');
    for (int i = 0; i < _tips.length; i++) {
      final tip = _tips[i];
      print('Tip $i: ID=${tip['id_tips']}, Judul="${tip['judul']}", User="${tip['username']}"');
    }
    print('Search results: ${_searchResults.length}');
  }

  // Debug method untuk melihat auth state
  Future<void> debugAuthState() async {
    print('=== TIPS PROVIDER AUTH DEBUG ===');
    print('AuthProvider available: ${_authProvider != null}');
    if (_authProvider != null) {
      print('AuthProvider - Authenticated: ${_authProvider!.isAuthenticated}');
      print('AuthProvider - Is Admin: ${_authProvider!.isAdmin}');
      print('AuthProvider - User Role: ${_authProvider!.userRole}');
      print('AuthProvider - User ID: ${_authProvider!.userId}');
    }
    
    print('AuthHelper - Authenticated: ${await AuthHelper.isAuthenticated()}');
    print('AuthHelper - Is Admin: ${await AuthHelper.isAdmin()}');
    print('AuthHelper - User Role: ${await AuthHelper.getCurrentUserRole()}');
    print('AuthHelper - User ID: ${await AuthHelper.getCurrentUserId()}');
    print('================================');
  }

  // Validate tip data before submit
  Map<String, String?> validateTipData({
    required String judul,
    required String deskripsi,
    required DateTime tanggalTips,
  }) {
    final errors = <String, String?>{};

    if (judul.trim().isEmpty) {
      errors['judul'] = 'Judul tips tidak boleh kosong';
    } else if (judul.length > 84) {
      errors['judul'] = 'Judul tips tidak boleh lebih dari 84 karakter';
    }

    if (deskripsi.trim().isEmpty) {
      errors['deskripsi'] = 'Deskripsi tips tidak boleh kosong';
    }

    if (tanggalTips.isAfter(DateTime.now().add(const Duration(days: 365)))) {
      errors['tanggal_tips'] = 'Tanggal tips tidak valid';
    }

    return errors;
  }

  // Validate admin access before performing admin operations (improved)
  Future<Map<String, String?>> validateAdminAccess() async {
    final errors = <String, String?>{};

    final isAuth = await isAuthenticated();
    if (!isAuth) {
      errors['authentication'] = 'Anda harus login terlebih dahulu';
      return errors;
    }

    final hasAdminAccess = await _validateAdminAccess();
    if (!hasAdminAccess) {
      errors['authorization'] = 'Akses ditolak. Hanya admin yang dapat melakukan operasi ini.';
      return errors;
    }

    return errors;
  }

  // Format tanggal untuk display
  String formatTanggal(String? tanggalString) {
    if (tanggalString == null) return '-';
    
    try {
      final date = DateTime.parse(tanggalString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return tanggalString;
    }
  }

  // Format tanggal dengan waktu
  String formatTanggalWaktu(String? tanggalString) {
    if (tanggalString == null) return '-';
    
    try {
      final date = DateTime.parse(tanggalString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return tanggalString;
    }
  }
}