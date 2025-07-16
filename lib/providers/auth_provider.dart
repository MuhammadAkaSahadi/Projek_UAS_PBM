// lib/providers/auth_provider.dart - Updated with API Integration and Fixed Clear Session
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:projek_uas/helper/auth_helper.dart';
import 'package:projek_uas/services/token_storage_manager.dart';

class AuthProvider extends ChangeNotifier {
  final TokenStorage _tokenStorage = TokenStorage.instance;
  
  // API Configuration - Update this with your actual API base URL
  static const String _baseUrl = 'http://192.168.43.143:5042/api'; // TODO: Replace with your actual API URL
  
  // Auth state
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _token;
  int? _userId;
  String? _username;
  String? _userRole;
  String? _errorMessage;
  
  // Getters
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get token => _token;
  int? get userId => _userId;
  String? get username => _username;
  String? get userRole => _userRole;
  String? get errorMessage => _errorMessage;
  bool get isAdmin => _userRole?.toLowerCase() == 'admin';
  bool get isUser => _userRole?.toLowerCase() == 'user';
  
  /// Initialize authentication state from stored token
  Future<void> initializeAuth() async {
    _setLoading(true);
    
    try {
      final isAuthenticated = await AuthHelper.isAuthenticated();
      
      if (isAuthenticated) {
        _token = await AuthHelper.getToken();
        _userId = await AuthHelper.getCurrentUserId();
        _username = await AuthHelper.getCurrentUsername();
        _userRole = await AuthHelper.getCurrentUserRole();
        _isAuthenticated = true;
        _errorMessage = null;
        
        print('Auth initialized - User: $_username, Role: $_userRole');
      } else {
        await _clearAuthState();
      }
    } catch (e) {
      print('Error initializing auth: $e');
      await _clearAuthState();
      _errorMessage = 'Gagal menginisialisasi autentikasi';
    }
    
    _setLoading(false);
  }
  
  /// Login with email/username and password
  Future<bool> login({
    required String identifier, // email or username
    required String password,
    Map<String, dynamic>? additionalData,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    
    try {
      final loginResponse = await _performLoginRequest(identifier, password);
      
      if (loginResponse['success'] == true) {
        final token = loginResponse['token'] as String;
        
        // Save login session using TokenStorage
        final saved = await _tokenStorage.saveLoginSession(
          token: token,
          refreshToken: null, // Your API doesn't provide refresh token
          additionalData: additionalData,
        );
        
        if (saved) {
          // Update provider state
          await _updateAuthStateFromToken(token);
          _setLoading(false);
          return true;
        } else {
          throw Exception('Gagal menyimpan data login');
        }
      } else {
        _errorMessage = loginResponse['message'] ?? 'Login gagal';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      print('Login error: $e');
      _errorMessage = e.toString().contains('Exception: ') 
          ? e.toString().replaceFirst('Exception: ', '')
          : 'Terjadi kesalahan saat login';
      _setLoading(false);
      return false;
    }
  }
<<<<<<< HEAD
  
  /// Register new user
  Future<bool> register({
    required String username,
    required String email,
    required String password,
    Map<String, dynamic>? additionalData,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    
    try {
      final registerResponse = await _performRegisterRequest(
        username, 
        email, 
        password, 
        additionalData,
      );
      
      if (registerResponse['success'] == true) {
        _errorMessage = null;
        _setLoading(false);
        return true;
      } else {
        _errorMessage = registerResponse['message'] ?? 'Registrasi gagal';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      print('Register error: $e');
      _errorMessage = e.toString().contains('Exception: ') 
          ? e.toString().replaceFirst('Exception: ', '')
          : 'Terjadi kesalahan saat registrasi';
      _setLoading(false);
      return false;
    }
  }
  
  /// Logout user - FIXED VERSION
  Future<void> logout() async {
    _setLoading(true);
    
    try {
      // Clear stored data using AuthHelper (which uses TokenStorage)
      final cleared = await AuthHelper.logout();
      
      if (cleared) {
        print('Logout successful - all data cleared');
      } else {
        print('Warning: Logout might not have cleared all data');
      }
      
      // Clear provider state
      await _clearAuthState();
      
      // Verify clearance
      final stillAuthenticated = await AuthHelper.isAuthenticated();
      if (stillAuthenticated) {
        print('WARNING: Still authenticated after logout, forcing clear');
        await _tokenStorage.clearAll();
        await _clearAuthState();
      }
      
    } catch (e) {
      print('Logout error: $e');
      // Even if there's an error, clear local data
      await _clearAuthState();
      await _tokenStorage.clearAll();
    }
    
    _setLoading(false);
  }
  
  /// Refresh token if needed (Not applicable since your API doesn't provide refresh tokens)
  Future<bool> refreshTokenIfNeeded() async {
    // Since your API doesn't provide refresh tokens, just check if token exists
    try {
      final token = await _tokenStorage.getToken();
      return token != null;
    } catch (e) {
      print('Error checking token: $e');
      return false;
    }
  }
  
  /// Check user permissions
  Future<bool> canAccessAdmin() async {
    return await AuthHelper.canAccessAdmin();
  }
  
  Future<bool> canAccessUser() async {
    return await AuthHelper.canAccessUser();
  }
  
  Future<bool> hasRole(String role) async {
    return await AuthHelper.hasRole(role);
  }
  
  /// Get user display name
  Future<String> getUserDisplayName() async {
    return await AuthHelper.getUserDisplayName();
  }
  
  /// Get comprehensive user info
  Future<Map<String, dynamic>> getUserInfo() async {
    return await AuthHelper.getUserInfo();
  }
  
  /// Set authentication data manually (for testing or special cases)
  void setAuthData({
    required String token,
    int? userId,
    String? username,
    String? userRole,
  }) {
    _token = token;
    _userId = userId;
    _username = username;
    _userRole = userRole;
    _isAuthenticated = true;
    _errorMessage = null;
    notifyListeners();
  }
  
  /// Clear authentication state - FIXED VERSION
  void clearAuth() {
    _clearAuthStateSync();
=======

  // Enhanced logout method with expired token cleanup
  Future<void> logout({bool clearExpiredTokens = true}) async {
    _token = null;
    _userInfo = null;
    
    final prefs = await SharedPreferences.getInstance();
    
    // Hapus token utama
    await prefs.remove('token');
    
    // Opsional: bersihkan semua token yang sudah expired jika ada
    if (clearExpiredTokens) {
      await _clearExpiredTokens(prefs);
    }
    
    // Bersihkan data auth lainnya jika ada
    await _clearAdditionalAuthData(prefs);
    
    notifyListeners();
  }

  // Method untuk membersihkan token yang sudah expired
  Future<void> _clearExpiredTokens(SharedPreferences prefs) async {
    try {
      // Daftar key yang mungkin menyimpan token
      final tokenKeys = [
        'token',
        'access_token',
        'refresh_token',
        'auth_token',
        'jwt_token',
        'bearer_token',
      ];

      for (final key in tokenKeys) {
        final storedToken = prefs.getString(key);
        if (storedToken != null) {
          try {
            // Cek apakah token expired
            if (JwtDecoder.isExpired(storedToken)) {
              await prefs.remove(key);
              debugPrint('Removed expired token: $key');
            }
          } catch (e) {
            // Jika token tidak valid, hapus juga
            await prefs.remove(key);
            debugPrint('Removed invalid token: $key');
          }
        }
      }
    } catch (e) {
      debugPrint('Error clearing expired tokens: $e');
    }
  }

  // Method untuk membersihkan data auth tambahan
  Future<void> _clearAdditionalAuthData(SharedPreferences prefs) async {
    try {
      // Daftar key data auth lainnya yang perlu dibersihkan
      final authDataKeys = [
        'user_info',
        'user_data',
        'user_profile',
        'login_time',
        'last_activity',
        'session_id',
        'device_id',
      ];

      for (final key in authDataKeys) {
        if (prefs.containsKey(key)) {
          await prefs.remove(key);
          debugPrint('Removed auth data: $key');
        }
      }
    } catch (e) {
      debugPrint('Error clearing additional auth data: $e');
    }
  }

  // Method untuk forced logout dengan pembersihan menyeluruh
  Future<void> forceLogout() async {
    debugPrint('Performing force logout with complete cleanup');
    
    _token = null;
    _userInfo = null;
    
    final prefs = await SharedPreferences.getInstance();
    
    // Hapus semua data yang terkait dengan authentication
    await prefs.clear(); // Hati-hati: ini akan menghapus SEMUA data SharedPreferences
    
    // Atau gunakan pembersihan selektif:
    // await _clearExpiredTokens(prefs);
    // await _clearAdditionalAuthData(prefs);
    
    notifyListeners();
  }

  // Method untuk cek dan bersihkan token expired secara berkala
  Future<void> cleanupExpiredTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _clearExpiredTokens(prefs);
      
      // Jika token saat ini juga expired, lakukan logout
      if (_token != null && JwtDecoder.isExpired(_token!)) {
        await logout();
      }
    } catch (e) {
      debugPrint('Error during token cleanup: $e');
    }
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
>>>>>>> 977283b5c55f44df8412999885a169e37a43c1c1
  }
  
  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  // === PRIVATE METHODS ===
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  /// Clear authentication state (async version) - FIXED
  Future<void> _clearAuthState() async {
    try {
      // Clear stored token data first
      await _tokenStorage.clearAll();
      
      // Then clear provider state
      _isAuthenticated = false;
      _token = null;
      _userId = null;
      _username = null;
      _userRole = null;
      _errorMessage = null;
      
      print('Auth state cleared completely');
      notifyListeners();
    } catch (e) {
      print('Error clearing auth state: $e');
      // Even if there's an error, clear the provider state
      _isAuthenticated = false;
      _token = null;
      _userId = null;
      _username = null;
      _userRole = null;
      _errorMessage = null;
      notifyListeners();
    }
  }
  
  /// Clear authentication state (sync version) - FIXED
  void _clearAuthStateSync() {
    // Clear provider state immediately
    _isAuthenticated = false;
    _token = null;
    _userId = null;
    _username = null;
    _userRole = null;
    _errorMessage = null;
    notifyListeners();
    
    // Clear stored data asynchronously
    _tokenStorage.clearAll().then((cleared) {
      if (cleared) {
        print('Auth state cleared completely (sync)');
      } else {
        print('Warning: Auth state might not be completely cleared');
      }
    }).catchError((e) {
      print('Error clearing stored auth data: $e');
    });
  }
  
  Future<void> _updateAuthStateFromToken(String token) async {
    _token = token;
    _userId = await AuthHelper.getCurrentUserId();
    _username = await AuthHelper.getCurrentUsername();
    _userRole = await AuthHelper.getCurrentUserRole();
    _isAuthenticated = true;
    _errorMessage = null;
    notifyListeners();
  }
  
  // === API METHODS ===
  
  Future<Map<String, dynamic>> _performLoginRequest(
    String identifier,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/Login/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'Username': identifier, // Your API expects 'Username'
          'Password': password,   // Your API expects 'Password'
        }),
      );
      
      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'token': responseData['token'], // Your API returns 'token' (lowercase t)
        };
      } else if (response.statusCode == 401) {
        final responseData = jsonDecode(response.body);
        return {
          'success': false,
          'message': responseData['message'] ?? 'Username atau password salah',
        };
      } else if (response.statusCode == 400) {
        final responseData = jsonDecode(response.body);
        return {
          'success': false,
          'message': responseData['message'] ?? 'Data yang dikirim tidak valid',
        };
      } else {
        return {
          'success': false,
          'message': 'Terjadi kesalahan pada server (${response.statusCode})',
        };
      }
    } catch (e) {
      print('Network error during login: $e');
      return {
        'success': false,
        'message': 'Gagal terhubung ke server. Periksa koneksi internet Anda.',
      };
    }
  }
  
  Future<Map<String, dynamic>> _performRegisterRequest(
    String username,
    String email,
    String password,
    Map<String, dynamic>? additionalData,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/Login/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'Username': username, // Your API expects 'Username'
          'Email': email,       // Your API expects 'Email'
          'Password': password, // Your API expects 'Password'
        }),
      );
      
      print('Register response status: ${response.statusCode}');
      print('Register response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Registrasi berhasil',
        };
      } else if (response.statusCode == 409) {
        final responseData = jsonDecode(response.body);
        return {
          'success': false,
          'message': responseData['message'] ?? 'Email atau username sudah terdaftar',
        };
      } else if (response.statusCode == 400) {
        final responseData = jsonDecode(response.body);
        return {
          'success': false,
          'message': responseData['message'] ?? 'Data yang dikirim tidak lengkap',
        };
      } else if (response.statusCode == 500) {
        final responseData = jsonDecode(response.body);
        return {
          'success': false,
          'message': responseData['message'] ?? 'Terjadi kesalahan pada server',
        };
      } else {
        return {
          'success': false,
          'message': 'Terjadi kesalahan tidak dikenal (${response.statusCode})',
        };
      }
    } catch (e) {
      print('Network error during registration: $e');
      return {
        'success': false,
        'message': 'Gagal terhubung ke server. Periksa koneksi internet Anda.',
      };
    }
  }

  // Method untuk auto-cleanup yang bisa dipanggil secara berkala
  Future<void> performMaintenanceCleanup() async {
    try {
      // Cek token saat ini
      if (_token != null && JwtDecoder.isExpired(_token!)) {
        debugPrint('Current token expired, performing logout');
        await logout();
        return;
      }

      // Bersihkan token expired lainnya
      await cleanupExpiredTokens();
      
      debugPrint('Maintenance cleanup completed');
    } catch (e) {
      debugPrint('Error during maintenance cleanup: $e');
    }
  }
}