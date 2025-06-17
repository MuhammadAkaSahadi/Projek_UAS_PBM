// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  Map<String, dynamic>? _userInfo;
  bool _isLoading = false;

  String? get token => _token;
  Map<String, dynamic>? get userInfo => _userInfo;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null && !JwtDecoder.isExpired(_token!);

  // Inisialisasi provider saat app startup
  Future<void> initializeAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token');
      
      if (_token != null && !JwtDecoder.isExpired(_token!)) {
        _userInfo = JwtDecoder.decode(_token!);
      } else {
        await logout(); // Clear invalid token
      }
    } catch (e) {
      await logout();
    }
    
    _isLoading = false;
    notifyListeners();
  }

  // Login method
  Future<bool> login(String token) async {
    try {
      if (JwtDecoder.isExpired(token)) {
        return false;
      }

      _token = token;
      _userInfo = JwtDecoder.decode(token);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);

      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Logout method
  Future<void> logout() async {
    _token = null;
    _userInfo = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    
    notifyListeners();
  }

  // Get user ID dari token
  int? getUserId() {
    if (_userInfo == null) return null;

    final possibleIdFields = [
      'Id_Users', 
      'sub', 
      'nameid',
      'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier',
      'userId',
    ];

    for (final field in possibleIdFields) {
      final value = _userInfo![field];
      if (value != null) {
        if (value is int) return value;
        if (value is String) return int.tryParse(value);
      }
    }

    return null;
  }

  // Check apakah token akan expire dalam 5 menit
  bool willExpireSoon() {
    if (_token == null) return true;
    
    final expiryDate = JwtDecoder.getExpirationDate(_token!);
    final now = DateTime.now();
    final difference = expiryDate.difference(now).inMinutes;
    
    return difference <= 5;
  }
}