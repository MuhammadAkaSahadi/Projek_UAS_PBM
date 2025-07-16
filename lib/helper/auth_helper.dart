// lib/helpers/auth_helper.dart
import 'package:projek_uas/services/token_storage_manager.dart';


/// Helper class untuk mempermudah akses token dan operasi autentikasi
/// di seluruh aplikasi tanpa perlu import TokenStorage setiap saat
class AuthHelper {
  static final TokenStorage _tokenStorage = TokenStorage.instance;
  
  // === QUICK ACCESS METHODS ===
  
  /// Get current token
  static Future<String?> getToken() async {
    return await _tokenStorage.getToken();
  }
  
  /// Check if user is authenticated
  static Future<bool> isAuthenticated() async {
    return await _tokenStorage.hasValidToken();
  }
  
  /// Check if user is admin
  static Future<bool> isAdmin() async {
    return await _tokenStorage.isAdmin();
  }
  
  /// Check if user is regular user
  static Future<bool> isUser() async {
    return await _tokenStorage.isUser();
  }
  
  /// Get current user ID
  static Future<int?> getCurrentUserId() async {
    return await _tokenStorage.getUserId();
  }
  
  /// Get current username
  static Future<String?> getCurrentUsername() async {
    return await _tokenStorage.getUsername();
  }
  
  /// Get current user role
  static Future<String?> getCurrentUserRole() async {
    return await _tokenStorage.getUserRole();
  }
  
  /// Get authorization headers for HTTP requests
  static Future<Map<String, String>> getAuthHeaders() async {
    return await _tokenStorage.getAuthHeaders();
  }
  
  /// Logout user (clear all stored data)
  static Future<bool> logout() async {
    return await _tokenStorage.clearAll();
  }
  
  /// Check if token will expire soon
  static Future<bool> needsRefresh({int minutes = 5}) async {
    return await _tokenStorage.willTokenExpireSoon(minutes: minutes);
  }
  
  /// Get token data (decoded JWT)
  static Future<Map<String, dynamic>?> getTokenData() async {
    return await _tokenStorage.getTokenData();
  }
  
  /// Get session duration in minutes
  static Future<int?> getSessionDuration() async {
    return await _tokenStorage.getSessionDuration();
  }
  
  // === ROLE-BASED ACCESS CONTROL ===
  
  /// Check if current user has admin privileges
  static Future<bool> canAccessAdmin() async {
    final isAuthenticated = await AuthHelper.isAuthenticated();
    if (!isAuthenticated) return false;
    
    return await AuthHelper.isAdmin();
  }
  
  /// Check if current user can access user features
  static Future<bool> canAccessUser() async {
    final isAuthenticated = await AuthHelper.isAuthenticated();
    if (!isAuthenticated) return false;
    
    // Admin can access user features too
    final userRole = await getCurrentUserRole();
    return userRole == 'admin' || userRole == 'user';
  }
  
  /// Check if current user has specific role
  static Future<bool> hasRole(String requiredRole) async {
    final isAuthenticated = await AuthHelper.isAuthenticated();
    if (!isAuthenticated) return false;
    
    final currentRole = await getCurrentUserRole();
    
    // Admin has access to everything
    if (currentRole == 'admin') return true;
    
    // Check specific role
    return currentRole?.toLowerCase() == requiredRole.toLowerCase();
  }
  
  // === UTILITY METHODS ===
  
  /// Format user display name
  static Future<String> getUserDisplayName() async {
    final username = await getCurrentUsername();
    final role = await getCurrentUserRole();
    
    if (username != null && role != null) {
      return '$username (${role.toUpperCase()})';
    } else if (username != null) {
      return username;
    } else {
      return 'Unknown User';
    }
  }
  
  /// Get user info summary
  static Future<Map<String, dynamic>> getUserInfo() async {
    return {
      'id': await getCurrentUserId(),
      'username': await getCurrentUsername(),
      'role': await getCurrentUserRole(),
      'isAdmin': await isAdmin(),
      'isAuthenticated': await isAuthenticated(),
      'sessionDuration': await getSessionDuration(),
      'needsRefresh': await needsRefresh(),
    };
  }
  
  /// Debug helper - print current auth state
  static Future<void> debugPrintAuthState() async {
    await _tokenStorage.debugPrintStoredData();
  }
}