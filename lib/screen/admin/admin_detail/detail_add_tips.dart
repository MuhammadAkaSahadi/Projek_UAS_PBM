import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:projek_uas/providers/tips_provider.dart';
<<<<<<< HEAD
import 'package:projek_uas/providers/auth_provider.dart';
=======
import 'package:shared_preferences/shared_preferences.dart';
>>>>>>> 977283b5c55f44df8412999885a169e37a43c1c1

class DetailAddTipsPage extends StatefulWidget {
  final bool isEdit;
  final Map<String, dynamic>? tipData;

  const DetailAddTipsPage({
    super.key,
    this.isEdit = false,
    this.tipData,
  });

  @override
  State<DetailAddTipsPage> createState() => _DetailAddTipsPageState();
}

class _DetailAddTipsPageState extends State<DetailAddTipsPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();
  
  File? _selectedImage;
  String? _existingImageUrl;
  bool _isLoading = false;
  bool _isUploadingImage = false;
  bool _hasAdminAccess = false;
  bool _isCheckingAccess = true;
  final ImagePicker _picker = ImagePicker();

  // Cloudinary configuration
  static const String _cloudName = 'dxwzt2mhr';
  static const String _uploadPreset = 'PocketFarm_Tips';

  // === CONSISTENT TOKEN KEYS - SAMA DENGAN TipsProvider ===
  static const String _tokenKey = 'token'; // Main token untuk AuthProvider
  static const String _accessTokenKey = 'access_token'; // Untuk access token API
  static const String _refreshTokenKey = 'refresh_token'; // Untuk refresh token API

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.tipData != null) {
      _initializeEditData();
    }
    _initializeProviders();
  }

  void _initializeProviders() async {
    // Set up the TipsProvider with AuthProvider reference
    final tipsProvider = Provider.of<TipsProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    tipsProvider.setAuthProvider(authProvider);
    
    // Check admin access once during initialization
    await _checkAndSetAdminAccess();
  }

  Future<void> _checkAndSetAdminAccess() async {
    try {
      setState(() {
        _isCheckingAccess = true;
      });

      final tipsProvider = Provider.of<TipsProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Ensure user is authenticated first
      if (!authProvider.isAuthenticated) {
        print('❌ User not authenticated');
        setState(() {
          _hasAdminAccess = false;
          _isCheckingAccess = false;
        });
        _showAccessDeniedDialog('Anda harus login terlebih dahulu');
        return;
      }

      // Check admin access
      final hasAccess = await tipsProvider.isUserAdmin();
      print('✅ Admin access check result: $hasAccess');
      
      setState(() {
        _hasAdminAccess = hasAccess;
        _isCheckingAccess = false;
      });

      // Show dialog if no access
      if (!hasAccess) {
        _showAccessDeniedDialog('Hanya admin yang dapat menambah atau mengedit tips.');
      }

    } catch (e) {
      print('❌ Error checking admin access: $e');
      setState(() {
        _hasAdminAccess = false;
        _isCheckingAccess = false;
      });
      _showAccessDeniedDialog('Terjadi kesalahan saat memeriksa akses admin.');
    }
  }

  void _initializeEditData() {
    final tipData = widget.tipData!;
    _judulController.text = tipData['judul']?.toString() ?? '';
    _deskripsiController.text = tipData['deskripsi']?.toString() ?? '';
    _existingImageUrl = tipData['gambar']?.toString();
  }

  @override
  void dispose() {
    _judulController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

<<<<<<< HEAD
  /// Show access denied dialog
  void _showAccessDeniedDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Akses Ditolak'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Exit the page
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
=======
  // === TOKEN MANAGEMENT METHODS - KONSISTEN DENGAN TipsProvider ===
  
  /// Check if user is logged in using TipsProvider method
  Future<bool> _isUserLoggedIn() async {
    final tipsProvider = Provider.of<TipsProvider>(context, listen: false);
    return await tipsProvider.isLoggedIn();
  }

  /// Get valid token using TipsProvider method
  Future<String?> _getValidToken() async {
    final tipsProvider = Provider.of<TipsProvider>(context, listen: false);
    return await tipsProvider.getValidToken();
  }

  /// Get current user ID using TipsProvider method
  Future<int?> _getCurrentUserId() async {
    final tipsProvider = Provider.of<TipsProvider>(context, listen: false);
    return await tipsProvider.getCurrentUserId();
  }

  /// Ensure sync with AuthProvider using TipsProvider method
  Future<void> _ensureSyncWithAuthProvider() async {
    final tipsProvider = Provider.of<TipsProvider>(context, listen: false);
    await tipsProvider.ensureSyncWithAuthProvider();
  }

  /// Clear tokens using consistent keys
  Future<void> _clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    
    // Clear additional auth data jika ada
    await prefs.remove('user_info');
    await prefs.remove('user_data');
    await prefs.remove('user_profile');
>>>>>>> 977283b5c55f44df8412999885a169e37a43c1c1
  }

  /// Upload image to Cloudinary
  Future<String?> _uploadToCloudinary(File imageFile) async {
    try {
      setState(() {
        _isUploadingImage = true;
      });

      Uint8List imageBytes = await imageFile.readAsBytes();
      
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
      );
      
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = _uploadPreset
        ..fields['folder'] = 'tips'
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            imageBytes,
            filename: 'tip_${DateTime.now().millisecondsSinceEpoch}.jpg',
            contentType: MediaType('image', 'jpeg'),
          ),
        );

      final response = await request.send();
      
      if (response.statusCode == 200) {
        final res = await http.Response.fromStream(response);
        final data = json.decode(res.body);
        return data['secure_url'];
      } else {
        return null;
      }
    } catch (e) {
      return null;
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _existingImageUrl = null;
        });
      }
    } catch (e) {
      _showSnackBar('Gagal mengambil gambar: $e', isError: true);
    }
  }

  Future<void> _showImageSourceDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pilih Sumber Gambar'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeri'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Kamera'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImageFromCamera();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _existingImageUrl = null;
        });
      }
    } catch (e) {
      _showSnackBar('Gagal mengambil gambar dari kamera: $e', isError: true);
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _existingImageUrl = null;
    });
  }

  bool _hasImage() {
    return _selectedImage != null || (_existingImageUrl != null && _existingImageUrl!.isNotEmpty);
  }

  Widget _buildImageSection() {
    return GestureDetector(
      onTap: (_isUploadingImage || !_hasAdminAccess) ? null : _showImageSourceDialog,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: const Color(0xFFE0E0E0),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey),
        ),
        child: _hasImage()
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _selectedImage != null
                        ? Image.file(
                            _selectedImage!,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Image.network(
                            _existingImageUrl!,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                width: double.infinity,
                                height: double.infinity,
                                color: Colors.grey[300],
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: double.infinity,
                                height: double.infinity,
                                color: Colors.grey[300],
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                    Text('Gambar tidak dapat dimuat'),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  // Upload progress overlay
                  if (_isUploadingImage)
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: Colors.white),
                            SizedBox(height: 8),
                            Text(
                              'Mengunggah gambar...',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Remove button
                  if (!_isUploadingImage && _hasAdminAccess)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 20),
                          onPressed: _removeImage,
                          tooltip: 'Hapus Gambar',
                        ),
                      ),
                    ),
                  // Edit button
                  if (!_isUploadingImage && _hasAdminAccess)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                          onPressed: _showImageSourceDialog,
                          tooltip: 'Ganti Gambar',
                        ),
                      ),
                    ),
                ],
              )
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo, 
                      size: 40, 
                      color: (_isUploadingImage || !_hasAdminAccess) ? Colors.grey : Colors.black54,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isUploadingImage 
                          ? 'Mengunggah...' 
                          : !_hasAdminAccess 
                              ? 'Akses Terbatas'
                              : 'Tambah Foto',
                      style: TextStyle(
                        fontSize: 16,
                        color: (_isUploadingImage || !_hasAdminAccess) ? Colors.grey : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isUploadingImage 
                          ? 'Mohon tunggu' 
                          : !_hasAdminAccess 
                              ? 'Hanya admin yang dapat menambah gambar'
                              : 'Ketuk untuk menambah gambar',
                      style: TextStyle(
                        fontSize: 12,
                        color: (_isUploadingImage || !_hasAdminAccess) ? Colors.grey : Colors.black38,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  String? _validateJudul(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Judul tips tidak boleh kosong';
    }
    if (value.length > 84) {
      return 'Judul tips tidak boleh lebih dari 84 karakter';
    }
    return null;
  }

  String? _validateDeskripsi(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Deskripsi tips tidak boleh kosong';
    }
    if (value.length < 50) {
      return 'Deskripsi tips minimal 50 karakter';
    }
    return null;
  }

  /// Get the tip owner's user ID for edit mode - KONSISTEN DENGAN TipsProvider
  int? _getTipOwnerUserId() {
    if (widget.isEdit && widget.tipData != null) {
      final tipData = widget.tipData!;
      
      // Konsisten dengan field yang digunakan di TipsProvider
      if (tipData['id_users'] != null) {
        return int.tryParse(tipData['id_users'].toString());
      } else if (tipData['Id_Users'] != null) {
        return int.tryParse(tipData['Id_Users'].toString());
      } else if (tipData['user_id'] != null) {
        return int.tryParse(tipData['user_id'].toString());
      }
    }
    return null;
  }

  /// Enhanced ownership validation using TipsProvider method
  Future<bool> _validateOwnership(int tipId) async {
    final tipsProvider = Provider.of<TipsProvider>(context, listen: false);
    return await tipsProvider.canUserUpdateTip(tipId);
  }

  Future<void> _submitForm() async {
<<<<<<< HEAD
    // Check admin access first
    if (!_hasAdminAccess) {
      _showSnackBar('Akses ditolak. Hanya admin yang dapat melakukan operasi ini.', isError: true);
      return;
    }

=======
    print('=== SUBMIT FORM START ===');
    
>>>>>>> 977283b5c55f44df8412999885a169e37a43c1c1
    if (!_formKey.currentState!.validate()) {
      print('❌ Form validation failed');
      return;
    }

    if (_isUploadingImage) {
      _showSnackBar('Mohon tunggu hingga gambar selesai diunggah', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final tipsProvider = Provider.of<TipsProvider>(context, listen: false);
<<<<<<< HEAD
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Double-check authentication
      if (!authProvider.isAuthenticated) {
        _showSnackBar('Anda harus login terlebih dahulu', isError: true);
=======
      
      // === ENHANCED TOKEN VALIDATION ===
      print('=== TOKEN VALIDATION START ===');
      
      // Ensure sync with AuthProvider first
      await _ensureSyncWithAuthProvider();
      
      // Check if user is logged in using TipsProvider method
      final isLoggedInCheck = await _isUserLoggedIn();
      if (!isLoggedInCheck) {
        _showSnackBar('Sesi Anda telah berakhir. Silakan login ulang.', isError: true);
>>>>>>> 977283b5c55f44df8412999885a169e37a43c1c1
        setState(() {
          _isLoading = false;
        });
        return;
      }
<<<<<<< HEAD

      // Double-check admin access
      final hasAdminAccess = await tipsProvider.isUserAdmin();
      if (!hasAdminAccess) {
        _showSnackBar('Akses ditolak. Hanya admin yang dapat melakukan operasi ini.', isError: true);
=======
      print('✅ User is logged in');
      
      // Get valid token using TipsProvider method
      final validToken = await _getValidToken();
      if (validToken == null) {
        _showSnackBar('Token tidak tersedia, silakan login ulang', isError: true);
>>>>>>> 977283b5c55f44df8412999885a169e37a43c1c1
        setState(() {
          _isLoading = false;
        });
        return;
      }
<<<<<<< HEAD
=======
      print('✅ Valid token obtained');
      
      // Get current user ID using TipsProvider method
      final currentUserId = await _getCurrentUserId();
      if (currentUserId == null) {
        _showSnackBar('Gagal mendapatkan informasi user. Silakan login ulang.', isError: true);
        setState(() {
          _isLoading = false;
        });
        return;
      }
      print('✅ Current user ID: $currentUserId');
      
      // === OWNERSHIP VALIDATION FOR EDIT MODE ===
      if (widget.isEdit) {
        print('=== OWNERSHIP VALIDATION ===');
        
        final tipOwnerId = _getTipOwnerUserId();
        if (tipOwnerId == null) {
          _showSnackBar('Gagal mendapatkan informasi pemilik tips', isError: true);
          setState(() {
            _isLoading = false;
          });
          return;
        }
        print('Tip owner ID: $tipOwnerId');
>>>>>>> 977283b5c55f44df8412999885a169e37a43c1c1

        // Double validation: local check + TipsProvider check
        if (currentUserId != tipOwnerId) {
          _showSnackBar('Anda hanya bisa mengupdate tips yang Anda buat sendiri', isError: true);
          setState(() {
            _isLoading = false;
          });
          return;
        }

        // Additional validation using TipsProvider method
        final tipId = widget.tipData!['id_tips'] ?? widget.tipData!['Id_Tips'] ?? 0;
        if (tipId > 0) {
          final canUpdate = await _validateOwnership(tipId);
          if (!canUpdate) {
            _showSnackBar('Validasi kepemilikan gagal. Anda hanya bisa mengupdate tips milik Anda sendiri.', isError: true);
            setState(() {
              _isLoading = false;
            });
            return;
          }
          print('✅ Ownership validation passed');
        }
      }
      
      // === PREPARE FORM DATA ===
      final String judul = _judulController.text.trim();
      final String deskripsi = _deskripsiController.text.trim();
      final DateTime tanggalTips = DateTime.now();

<<<<<<< HEAD
      // Validate tip data using TipsProvider
=======
      print('=== FORM DATA ===');
      print('Judul: $judul');
      print('Deskripsi length: ${deskripsi.length}');
      print('Current User ID: $currentUserId');
      print('Tanggal: $tanggalTips');

      // Validate form data using TipsProvider method
>>>>>>> 977283b5c55f44df8412999885a169e37a43c1c1
      final validationErrors = tipsProvider.validateTipData(
        judul: judul,
        deskripsi: deskripsi,
        tanggalTips: tanggalTips,
<<<<<<< HEAD
      );

      if (validationErrors.isNotEmpty) {
        final errorMessage = validationErrors.values.where((e) => e != null).join('\n');
        _showSnackBar(errorMessage, isError: true);
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Handle image upload to Cloudinary
=======
        idUsers: currentUserId,
      );
      
      if (validationErrors.isNotEmpty) {
        final firstError = validationErrors.values.first;
        if (firstError != null) {
          _showSnackBar(firstError, isError: true);
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }
      print('✅ Form data validation passed');
      
      // === HANDLE IMAGE UPLOAD ===
>>>>>>> 977283b5c55f44df8412999885a169e37a43c1c1
      String? imageUrl;
      if (_selectedImage != null) {
        print('=== UPLOADING IMAGE ===');
        _showSnackBar('Mengunggah gambar ke Cloudinary...', isError: false);
        imageUrl = await _uploadToCloudinary(_selectedImage!);
        
        if (imageUrl == null) {
          _showSnackBar('Gagal mengunggah gambar ke Cloudinary', isError: true);
          setState(() {
            _isLoading = false;
          });
          return;
        }
        
        _showSnackBar('Gambar berhasil diunggah', isError: false);
        print('✅ Image uploaded: $imageUrl');
      } else if (_existingImageUrl != null) {
        imageUrl = _existingImageUrl;
        print('Using existing image URL: $imageUrl');
      }
<<<<<<< HEAD

      print('=== SUBMIT FORM DEBUG ===');
      print('Is Edit: ${widget.isEdit}');
      print('Has Admin Access: $_hasAdminAccess');
      print('Auth Token: ${authProvider.token != null ? "Present" : "Missing"}');
      print('User Role: ${authProvider.userRole}');
      print('Is Admin: ${authProvider.isAdmin}');

=======
      
      // === SUBMIT FORM USING TipsProvider ===
>>>>>>> 977283b5c55f44df8412999885a169e37a43c1c1
      bool success;
      if (widget.isEdit && widget.tipData != null) {
        print('=== UPDATING TIP ===');
        final int tipId = widget.tipData!['id_tips'] ?? widget.tipData!['Id_Tips'] ?? 0;
        
        if (tipId == 0) {
          _showSnackBar('ID Tips tidak valid', isError: true);
          setState(() {
            _isLoading = false;
          });
          return;
        }

        success = await tipsProvider.updateTip(
          idTips: tipId,
          judul: judul,
          deskripsi: deskripsi,
          gambar: imageUrl,
          tanggalTips: tanggalTips,
          idUsers: currentUserId,
        );
      } else {
        print('=== ADDING NEW TIP ===');
        success = await tipsProvider.addTip(
          judul: judul,
          deskripsi: deskripsi,
          gambar: imageUrl,
          tanggalTips: tanggalTips,
<<<<<<< HEAD
=======
          idUsers: currentUserId,
>>>>>>> 977283b5c55f44df8412999885a169e37a43c1c1
        );
      }

      // === HANDLE RESULT ===
      if (success) {
        print('✅ Operation successful');
        _showSnackBar(
          widget.isEdit ? 'Tips berhasil diperbarui!' : 'Tips berhasil dipublikasikan!',
          isError: false,
        );
        
        await Future.delayed(const Duration(seconds: 1));
        
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        print('❌ Operation failed');
        final errorMessage = tipsProvider.error ?? (widget.isEdit ? 'Gagal memperbarui tips' : 'Gagal mempublikasikan tips');
        _showSnackBar(errorMessage, isError: true);
      }
    } catch (e) {
<<<<<<< HEAD
      print('❌ Submit form error: $e');
=======
      print('❌ Exception during submit: $e');
>>>>>>> 977283b5c55f44df8412999885a169e37a43c1c1
      _showSnackBar('Terjadi kesalahan: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: isError ? 4 : 2),
        ),
      );
    }
  }

  Future<bool> _onWillPop() async {
    if (_isUploadingImage) {
      _showSnackBar('Mohon tunggu hingga gambar selesai diunggah', isError: true);
      return false;
    }

    if (_judulController.text.trim().isNotEmpty || 
        _deskripsiController.text.trim().isNotEmpty || 
        _hasImage()) {
      return await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Keluar Tanpa Menyimpan?'),
          content: const Text(
            'Perubahan yang Anda buat akan hilang jika keluar sekarang.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Lanjut Edit'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Keluar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ) ?? false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color.fromRGBO(247, 247, 247, 1),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () async {
              if (await _onWillPop()) {
                Navigator.pop(context);
              }
            },
          ),
          title: Text(
            widget.isEdit ? 'Edit Tips' : 'Tambah Tips',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
<<<<<<< HEAD
        body: Consumer2<TipsProvider, AuthProvider>(
          builder: (context, tipsProvider, authProvider, child) {
            // Show loading if checking access or authentication
            if (_isCheckingAccess || !authProvider.isAuthenticated) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Memeriksa akses...'),
                  ],
                ),
              );
            }

            return Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView(
                  children: [
                    // Admin access info
                    if (!_hasAdminAccess)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.block, color: Colors.red),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Akses ditolak. Hanya admin yang dapat menambah atau mengedit tips.',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Image Section
                    _buildImageSection(),
                    const SizedBox(height: 24),

=======
        body: Consumer<TipsProvider>(
          builder: (context, tipsProvider, child) {
            return Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView(
                  children: [
                    // Show error message if exists
                    if (tipsProvider.error != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          border: Border.all(color: Colors.red.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade600),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                tipsProvider.error!,
                                style: TextStyle(color: Colors.red.shade600),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              onPressed: () => tipsProvider.clearError(),
                            ),
                          ],
                        ),
                      ),

                    // Image Section
                    _buildImageSection(),
                    const SizedBox(height: 24),

>>>>>>> 977283b5c55f44df8412999885a169e37a43c1c1
                    // Input Judul Tips
                    const Text(
                      'Judul Tips',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _judulController,
                      validator: _validateJudul,
                      maxLength: 84,
<<<<<<< HEAD
                      enabled: !_isUploadingImage && _hasAdminAccess,
=======
                      enabled: !_isUploadingImage && !_isLoading,
>>>>>>> 977283b5c55f44df8412999885a169e37a43c1c1
                      decoration: InputDecoration(
                        hintText: 'Masukkan judul tips',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        errorMaxLines: 2,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Input Deskripsi Tips
                    const Text(
                      'Deskripsi Tips',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _deskripsiController,
                      validator: _validateDeskripsi,
                      maxLines: 8,
<<<<<<< HEAD
                      enabled: !_isUploadingImage && _hasAdminAccess,
=======
                      enabled: !_isUploadingImage && !_isLoading,
>>>>>>> 977283b5c55f44df8412999885a169e37a43c1c1
                      decoration: InputDecoration(
                        hintText: 'Masukkan deskripsi tips (minimal 50 karakter)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        errorMaxLines: 2,
                        helperText: '${_deskripsiController.text.length} karakter',
                      ),
                      onChanged: (value) {
                        setState(() {}); // Rebuild to update character count
                      },
                    ),
                    const SizedBox(height: 100), // Space for bottom button
                  ],
                ),
              ),
            );
          },
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _hasAdminAccess ? Colors.green : Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: Colors.grey,
              ),
              onPressed: (_isLoading || _isUploadingImage || !_hasAdminAccess) 
                  ? null 
                  : _submitForm,
              child: (_isLoading || _isUploadingImage)
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _isUploadingImage ? 'Mengunggah Gambar...' : 'Memproses...',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      !_hasAdminAccess 
                          ? 'Akses Terbatas' 
                          : (widget.isEdit ? 'Perbarui' : 'Publikasi'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}