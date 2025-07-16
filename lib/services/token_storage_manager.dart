// lib/services/token_storage.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class TokenStorage {
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _usernameKey = 'username';
  static const String _userRoleKey = 'user_role';
  static const String _loginTimeKey = 'login_time';
  
  static TokenStorage? _instance;
  static SharedPreferences? _prefs;
  
  // Singleton pattern
  TokenStorage._internal();
  
  static TokenStorage get instance {
    _instance ??= TokenStorage._internal();
    return _instance!;
  }
  
  // Initialize SharedPreferences
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }
  
  // Ensure prefs is initialized
  Future<SharedPreferences> get _preferences async {
    if (_prefs == null) {
      await init();
    }
    return _prefs!;
  }
  
  // === TOKEN OPERATIONS ===
  
  /// Save authentication token
  Future<bool> saveToken(String token) async {
    try {
      final prefs = await _preferences;
      final success = await prefs.setString(_tokenKey, token);
      
      if (success) {
        // Save login timestamp
        await prefs.setString(_loginTimeKey, DateTime.now().toIso8601String());
        
        // Extract and save user info from token
        await _saveTokenData(token);
        
        print('Token saved successfully');
      }
      
      return success;
    } catch (e) {
      print('Error saving token: $e');
      return false;
    }
  }
  
  /// Get stored token
  Future<String?> getToken() async {
    try {
      final prefs = await _preferences;
      final token = prefs.getString(_tokenKey);
      
      // Check if token exists and is not expired
      if (token != null && !isTokenExpired(token)) {
        return token;
      }
      
      // If token is expired, clear it immediately
      if (token != null && isTokenExpired(token)) {
        print('Token expired, clearing all auth data');
        await clearToken();
      }
      
      return null;
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
  }
  
  /// Check if token exists and is valid
  Future<bool> hasValidToken() async {
    try {
      final prefs = await _preferences;
      final token = prefs.getString(_tokenKey);
      
      // If no token exists, return false
      if (token == null || token.isEmpty) {
        return false;
      }
      
      // Check if token is expired
      if (isTokenExpired(token)) {
        print('Token expired, clearing all auth data');
        await clearToken();
        return false;
      }
      
      return true;
    } catch (e) {
      print('Error checking token validity: $e');
      return false;
    }
  }
  
  /// Check if token is expired
  bool isTokenExpired(String token) {
    try {
      return JwtDecoder.isExpired(token);
    } catch (e) {
      print('Error checking token expiration: $e');
      return true; // Assume expired if we can't decode
    }
  }
  
  /// Get token expiration date
  DateTime? getTokenExpirationDate(String? token) {
    try {
      if (token == null) return null;
      return JwtDecoder.getExpirationDate(token);
    } catch (e) {
      print('Error getting token expiration date: $e');
      return null;
    }
  }
  
  /// Check if token will expire soon (within specified minutes)
  Future<bool> willTokenExpireSoon({int minutes = 5}) async {
    try {
      final token = await getToken();
      if (token == null) return true;
      
      final expiryDate = getTokenExpirationDate(token);
      if (expiryDate == null) return true;
      
      final now = DateTime.now();
      final difference = expiryDate.difference(now).inMinutes;
      
      return difference <= minutes;
    } catch (e) {
      print('Error checking token expiry: $e');
      return true;
    }
  }
  
  /// Clear authentication token - FIXED VERSION
  Future<bool> clearToken() async {
    try {
      final prefs = await _preferences;
      
      // Clear all auth-related keys one by one to ensure they're all removed
      bool tokenCleared = true;
      bool refreshTokenCleared = true;
      bool userIdCleared = true;
      bool usernameCleared = true;
      bool userRoleCleared = true;
      bool loginTimeCleared = true;
      
      // Remove each key individually and check success
      if (prefs.containsKey(_tokenKey)) {
        tokenCleared = await prefs.remove(_tokenKey);
      }
      
      if (prefs.containsKey(_refreshTokenKey)) {
        refreshTokenCleared = await prefs.remove(_refreshTokenKey);
      }
      
      if (prefs.containsKey(_userIdKey)) {
        userIdCleared = await prefs.remove(_userIdKey);
      }
      
      if (prefs.containsKey(_usernameKey)) {
        usernameCleared = await prefs.remove(_usernameKey);
      }
      
      if (prefs.containsKey(_userRoleKey)) {
        userRoleCleared = await prefs.remove(_userRoleKey);
      }
      
      if (prefs.containsKey(_loginTimeKey)) {
        loginTimeCleared = await prefs.remove(_loginTimeKey);
      }
      
      // Also clear any additional user data that might have been stored
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith('user_')) {
          await prefs.remove(key);
        }
      }
      
      final allCleared = tokenCleared && 
                        refreshTokenCleared && 
                        userIdCleared && 
                        usernameCleared && 
                        userRoleCleared && 
                        loginTimeCleared;
      
      if (allCleared) {
        print('All token data cleared successfully');
        // Verify clearance
        await _verifyDataCleared();
      } else {
        print('Warning: Some data might not have been cleared properly');
      }
      
      return allCleared;
    } catch (e) {
      print('Error clearing token: $e');
      return false;
    }
  }
  
  /// Verify that all auth data has been cleared
  Future<void> _verifyDataCleared() async {
    try {
      final prefs = await _preferences;
      
      final token = prefs.getString(_tokenKey);
      final refreshToken = prefs.getString(_refreshTokenKey);
      final userId = prefs.getInt(_userIdKey);
      final username = prefs.getString(_usernameKey);
      final userRole = prefs.getString(_userRoleKey);
      final loginTime = prefs.getString(_loginTimeKey);
      
      print('=== VERIFICATION AFTER CLEAR ===');
      print('Token: ${token ?? 'null'}');
      print('Refresh Token: ${refreshToken ?? 'null'}');
      print('User ID: ${userId ?? 'null'}');
      print('Username: ${username ?? 'null'}');
      print('User Role: ${userRole ?? 'null'}');
      print('Login Time: ${loginTime ?? 'null'}');
      print('================================');
      
      // If any data still exists, force clear again
      if (token != null || refreshToken != null || userId != null || 
          username != null || userRole != null || loginTime != null) {
        print('WARNING: Some data still exists after clear, forcing removal');
        await _forceFullClear();
      }
    } catch (e) {
      print('Error verifying clear: $e');
    }
  }
  
  /// Force full clear of all auth data
  Future<void> _forceFullClear() async {
    try {
      final prefs = await _preferences;
      
      // Get all keys and remove anything that might be auth-related
      final keys = prefs.getKeys().toList();
      
      for (final key in keys) {
        if (key == _tokenKey || 
            key == _refreshTokenKey || 
            key == _userIdKey || 
            key == _usernameKey || 
            key == _userRoleKey || 
            key == _loginTimeKey ||
            key.startsWith('user_') ||
            key.startsWith('auth_')) {
          await prefs.remove(key);
          print('Force removed: $key');
        }
      }
      
      print('Force clear completed');
    } catch (e) {
      print('Error in force clear: $e');
    }
  }
  
  // === REFRESH TOKEN OPERATIONS ===
  
  /// Save refresh token
  Future<bool> saveRefreshToken(String refreshToken) async {
    try {
      final prefs = await _preferences;
      return await prefs.setString(_refreshTokenKey, refreshToken);
    } catch (e) {
      print('Error saving refresh token: $e');
      return false;
    }
  }
  
  /// Get refresh token
  Future<String?> getRefreshToken() async {
    try {
      final prefs = await _preferences;
      return prefs.getString(_refreshTokenKey);
    } catch (e) {
      print('Error getting refresh token: $e');
      return null;
    }
  }
  
  // === USER DATA OPERATIONS ===
  
  /// Save user data from token
  Future<void> _saveTokenData(String token) async {
    try {
      final tokenData = JwtDecoder.decode(token);
      final prefs = await _preferences;
      
      // Extract user ID
      final userId = _extractUserId(tokenData);
      if (userId != null) {
        await prefs.setInt(_userIdKey, userId);
      }
      
      // Extract username
      final username = _extractUsername(tokenData);
      if (username != null) {
        await prefs.setString(_usernameKey, username);
      }
      
      // Extract user role
      final role = _extractUserRole(tokenData);
      if (role != null) {
        await prefs.setString(_userRoleKey, role);
      }
      
    } catch (e) {
      print('Error saving token data: $e');
    }
  }
  
  /// Extract user ID from token data
  int? _extractUserId(Map<String, dynamic> tokenData) {
    final possibleIdFields = [
      'Id_Users',
      'sub',
      'nameid',
      'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier',
      'userId',
      'id',
    ];
    
    for (final field in possibleIdFields) {
      final value = tokenData[field];
      if (value != null) {
        if (value is int) return value;
        if (value is String) {
          final parsed = int.tryParse(value);
          if (parsed != null) return parsed;
        }
      }
    }
    
    return null;
  }
  
  /// Extract username from token data
  String? _extractUsername(Map<String, dynamic> tokenData) {
    final possibleUsernameFields = [
      'unique_name',
      'username',
      'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name',
      'name',
    ];
    
    for (final field in possibleUsernameFields) {
      final value = tokenData[field];
      if (value != null && value is String && value.isNotEmpty) {
        return value;
      }
    }
    
    return null;
  }
  
  /// Extract user role from token data
  String? _extractUserRole(Map<String, dynamic> tokenData) {
    final possibleRoleFields = [
      'role',
      'http://schemas.microsoft.com/ws/2008/06/identity/claims/role',
      'roles',
    ];
    
    for (final field in possibleRoleFields) {
      final value = tokenData[field];
      if (value != null && value is String && value.isNotEmpty) {
        return value;
      }
    }
    
    return 'user'; // Default role
  }
  
  /// Get stored user ID
  Future<int?> getUserId() async {
    try {
      final prefs = await _preferences;
      return prefs.getInt(_userIdKey);
    } catch (e) {
      print('Error getting user ID: $e');
      return null;
    }
  }
  
  /// Get stored username
  Future<String?> getUsername() async {
    try {
      final prefs = await _preferences;
      return prefs.getString(_usernameKey);
    } catch (e) {
      print('Error getting username: $e');
      return null;
    }
  }
  
  /// Get stored user role
  Future<String?> getUserRole() async {
    try {
      final prefs = await _preferences;
      return prefs.getString(_userRoleKey);
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }
  
  /// Get login time
  Future<DateTime?> getLoginTime() async {
    try {
      final prefs = await _preferences;
      final loginTimeString = prefs.getString(_loginTimeKey);
      
      if (loginTimeString != null) {
        return DateTime.tryParse(loginTimeString);
      }
      
      return null;
    } catch (e) {
      print('Error getting login time: $e');
      return null;
    }
  }
  
  // === UTILITY METHODS ===
  
  /// Get authorization header with Bearer token
  Future<Map<String, String>> getAuthHeaders() async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    
    final token = await getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }
  
  /// Get token data (decoded JWT)
  Future<Map<String, dynamic>?> getTokenData() async {
    try {
      final token = await getToken();
      if (token != null) {
        return JwtDecoder.decode(token);
      }
      return null;
    } catch (e) {
      print('Error getting token data: $e');
      return null;
    }
  }
  
  /// Check if user is admin
  Future<bool> isAdmin() async {
    try {
      // First check if we have a valid token
      final hasValid = await hasValidToken();
      if (!hasValid) return false;
      
      final role = await getUserRole();
      return role?.toLowerCase() == 'admin';
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }
  
  /// Check if user is regular user
  Future<bool> isUser() async {
    try {
      // First check if we have a valid token
      final hasValid = await hasValidToken();
      if (!hasValid) return false;
      
      final role = await getUserRole();
      return role?.toLowerCase() == 'user';
    } catch (e) {
      print('Error checking user status: $e');
      return false;
    }
  }
  
  /// Get session duration in minutes
  Future<int?> getSessionDuration() async {
    try {
      final loginTime = await getLoginTime();
      if (loginTime != null) {
        final now = DateTime.now();
        return now.difference(loginTime).inMinutes;
      }
      return null;
    } catch (e) {
      print('Error getting session duration: $e');
      return null;
    }
  }
  
  /// Debug method to print all stored data
  Future<void> debugPrintStoredData() async {
    try {
      final token = await getToken();
      final userId = await getUserId();
      final username = await getUsername();
      final role = await getUserRole();
      final loginTime = await getLoginTime();
      final sessionDuration = await getSessionDuration();
      
      print('=== TOKEN STORAGE DEBUG ===');
      print('Has Valid Token: ${await hasValidToken()}');
      print('Token: ${token?.substring(0, 20) ?? 'null'}...');
      print('User ID: $userId');
      print('Username: $username');
      print('Role: $role');
      print('Login Time: $loginTime');
      print('Session Duration: $sessionDuration minutes');
      print('Will Expire Soon: ${await willTokenExpireSoon()}');
      print('Is Admin: ${await isAdmin()}');
      print('===========================');
    } catch (e) {
      print('Error in debug print: $e');
    }
  }
  
  /// Clear all stored data (for logout or app reset) - FIXED VERSION
  Future<bool> clearAll() async {
    print('Clearing all auth data...');
    final cleared = await clearToken();
    
    // Double-check and force clear if needed
    if (cleared) {
      final stillHasToken = await hasValidToken();
      if (stillHasToken) {
        print('WARNING: Token still exists after clear, forcing full clear');
        await _forceFullClear();
      }
    }
    
    return cleared;
  }
  
  /// Save complete login session data
  Future<bool> saveLoginSession({
    required String token,
    String? refreshToken,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // First clear any existing data to prevent conflicts
      await clearAll();
      
      // Save the new token
      final tokenSaved = await saveToken(token);
      
      if (refreshToken != null) {
        await saveRefreshToken(refreshToken);
      }
      
      // Save additional user data if provided
      if (additionalData != null) {
        final prefs = await _preferences;
        
        for (final entry in additionalData.entries) {
          final key = entry.key;
          final value = entry.value;
          
          if (value is String) {
            await prefs.setString('user_$key', value);
          } else if (value is int) {
            await prefs.setInt('user_$key', value);
          } else if (value is bool) {
            await prefs.setBool('user_$key', value);
          }
        }
      }
      
      return tokenSaved;
    } catch (e) {
      print('Error saving login session: $e');
      return false;
    }
  }
}