import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:projek_uas/providers/tips_provider.dart';

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
  final ImagePicker _picker = ImagePicker();

  // Cloudinary configuration
  static const String _cloudName = 'dxwzt2mhr';
  static const String _uploadPreset = 'PocketFarm_Tips';

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.tipData != null) {
      _initializeEditData();
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

  /// Upload image to Cloudinary
  Future<String?> _uploadToCloudinary(File imageFile) async {
    try {
      setState(() {
        _isUploadingImage = true;
      });

      // Read image as bytes
      Uint8List imageBytes = await imageFile.readAsBytes();
      
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
      );
      
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = _uploadPreset
        ..fields['folder'] = 'tips' // Optional: organize images in folders
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
        final res = await http.Response.fromStream(response);
        print('Cloudinary upload failed: ${response.statusCode}');
        print('Response body: ${res.body}');
        return null;
      }
    } catch (e) {
      print('Cloudinary upload error: $e');
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
          _existingImageUrl = null; // Clear existing image when new image is selected
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
      onTap: _isUploadingImage ? null : _showImageSourceDialog,
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
                  if (!_isUploadingImage)
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
                  if (!_isUploadingImage)
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
                      color: _isUploadingImage ? Colors.grey : Colors.black54,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isUploadingImage ? 'Mengunggah...' : 'Tambah Foto',
                      style: TextStyle(
                        fontSize: 16,
                        color: _isUploadingImage ? Colors.grey : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isUploadingImage ? 'Mohon tunggu' : 'Ketuk untuk menambah gambar',
                      style: TextStyle(
                        fontSize: 12,
                        color: _isUploadingImage ? Colors.grey : Colors.black38,
                      ),
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

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Prevent submission if image is still uploading
    if (_isUploadingImage) {
      _showSnackBar('Mohon tunggu hingga gambar selesai diunggah', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final tipsProvider = Provider.of<TipsProvider>(context, listen: false);
      
      // TODO: Get actual token from your auth provider
      const String token = 'your_auth_token_here';
      
      // TODO: Get actual user ID from your auth provider
      const int userId = 1;

      final String judul = _judulController.text.trim();
      final String deskripsi = _deskripsiController.text.trim();
      final DateTime tanggalTips = DateTime.now();

      // Handle image upload to Cloudinary
      String? imageUrl;
      if (_selectedImage != null) {
        _showSnackBar('Mengunggah gambar ke Cloudinary...', isError: false);
        imageUrl = await _uploadToCloudinary(_selectedImage!);
        
        if (imageUrl == null) {
          _showSnackBar('Gagal mengunggah gambar ke Cloudinary', isError: true);
          setState(() {
            _isLoading = false;
          });
          return;
        }
      } else if (_existingImageUrl != null) {
        imageUrl = _existingImageUrl;
      }

      bool success;
      if (widget.isEdit && widget.tipData != null) {
        // Update existing tip
        final int tipId = widget.tipData!['id_tips'] ?? 0;
        success = await tipsProvider.updateTip(
          token: token,
          idTips: tipId,
          judul: judul,
          deskripsi: deskripsi,
          gambar: imageUrl,
          tanggalTips: tanggalTips,
        );
      } else {
        // Add new tip
        success = await tipsProvider.addTip(
          token: token,
          judul: judul,
          deskripsi: deskripsi,
          gambar: imageUrl,
          tanggalTips: tanggalTips,
          idUsers: userId,
        );
      }

      if (success) {
        _showSnackBar(
          widget.isEdit ? 'Tips berhasil diperbarui!' : 'Tips berhasil dipublikasikan!',
          isError: false,
        );
        
        // Wait a bit to show the success message
        await Future.delayed(const Duration(seconds: 1));
        
        // Return to previous page with success result
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        _showSnackBar(
          tipsProvider.error ?? (widget.isEdit ? 'Gagal memperbarui tips' : 'Gagal mempublikasikan tips'),
          isError: true,
        );
      }
    } catch (e) {
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
    // Prevent exit if image is uploading
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
        body: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                // Image Section
                _buildImageSection(),
                const SizedBox(height: 24),

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
                  enabled: !_isUploadingImage, // Disable during upload
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
                  enabled: !_isUploadingImage, // Disable during upload
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
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: Colors.grey,
              ),
              onPressed: (_isLoading || _isUploadingImage) ? null : _submitForm,
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
                      widget.isEdit ? 'Perbarui' : 'Publikasi',
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