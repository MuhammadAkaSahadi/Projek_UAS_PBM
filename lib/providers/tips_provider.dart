// lib/providers/tips_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TipsProvider with ChangeNotifier {
  final List<Map<String, dynamic>> _tips = [];
  final List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  String? _error;
  
  static const String baseUrl = 'http://192.168.1.2:5042/api/Tips';

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Map<String, dynamic>> get tips => _tips;
  List<Map<String, dynamic>> get searchResults => _searchResults;

  // Fetch all tips
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

  // Add new tip
  Future<bool> addTip({
    required String token,
    required String judul,
    required String deskripsi,
    String? gambar,
    required DateTime tanggalTips,
    required int idUsers,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('=== ADD TIP DEBUG ===');
      print('Judul: $judul');
      print('Deskripsi: $deskripsi');
      print('Gambar: $gambar');
      print('Tanggal: $tanggalTips');
      print('ID Users: $idUsers');

      final requestBody = {
        'Judul': judul,
        'Deskripsi': deskripsi,
        'Gambar': gambar ?? '',
        'Tanggal_Tips': tanggalTips.toIso8601String(),
        'Id_Users': idUsers,
      };

      print('Request Body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
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

  // Update existing tip
  Future<bool> updateTip({
    required String token,
    required int idTips,
    required String judul,
    required String deskripsi,
    String? gambar,
    required DateTime tanggalTips,
  }) async {
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

      final response = await http.put(
        Uri.parse('$baseUrl/$idTips'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
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

  // Delete tip
  Future<bool> deleteTip({
    required String token,
    required int idTips,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('=== DELETE TIP DEBUG ===');
      print('ID Tips: $idTips');

      final response = await http.delete(
        Uri.parse('$baseUrl/$idTips'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
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

  // Search tips
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

  // Validate tip data before submit
  Map<String, String?> validateTipData({
    required String judul,
    required String deskripsi,
    required DateTime tanggalTips,
    required int idUsers,
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

    if (idUsers <= 0) {
      errors['id_users'] = 'ID User harus berupa angka positif';
    }

    if (tanggalTips.isAfter(DateTime.now().add(const Duration(days: 365)))) {
      errors['tanggal_tips'] = 'Tanggal tips tidak valid';
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