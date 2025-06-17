import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ImageHandlerService {
  static const int maxImages = 5;
  static const String cloudName = 'dxwzt2mhr';
  static const String uploadPreset = 'PocketFarm_Laporan';
  
  final ImagePicker _picker = ImagePicker();
  
  // Callback untuk update UI
  final VoidCallback? onStateChanged;
  
  // State variables
  final List<File> _selectedImages = [];
  List<String> _existingImageUrls = [];
  List<String> _uploadedImageUrls = []; // TAMBAHAN: Simpan URL yang sudah diupload
  bool _isUploadingImages = false;
  
  ImageHandlerService({this.onStateChanged});
  
  // Getters
  List<File> get selectedImages => List.unmodifiable(_selectedImages);
  List<String> get existingImageUrls => List.unmodifiable(_existingImageUrls);
  List<String> get uploadedImageUrls => List.unmodifiable(_uploadedImageUrls); // TAMBAHAN
  bool get isUploadingImages => _isUploadingImages;
  int get totalImages => _selectedImages.length + _existingImageUrls.length;
  
  // Setters dengan callback
  void _notifyStateChanged() {
    onStateChanged?.call();
  }
  
  // Initialize dengan data yang sudah ada
  void initializeWithExistingImages(List<String> existingUrls) {
    _existingImageUrls = List<String>.from(existingUrls);
    _notifyStateChanged();
  }
  
  // TAMBAHAN: Method untuk mengeset uploaded URLs
  void setUploadedUrls(List<String> urls) {
    _uploadedImageUrls = List<String>.from(urls);
    _notifyStateChanged();
  }
  
  // Show image source dialog
  void showImageSourceDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text("Pilih dari Galeri"),
            onTap: () {
              Navigator.pop(context);
              pickMultipleImages(context, ImageSource.gallery);
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text("Ambil dengan Kamera"),
            onTap: () {
              Navigator.pop(context);
              pickImage(context, ImageSource.camera);
            },
          ),
          if (totalImages > 0)
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                "Hapus Semua Gambar",
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                removeAllImages();
              },
            ),
        ],
      ),
    );
  }
  
  // Pick multiple images from gallery
  Future<void> pickMultipleImages(BuildContext context, ImageSource source) async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (pickedFiles.isNotEmpty) {
        final totalAfterAdd = totalImages + pickedFiles.length;
        
        if (totalAfterAdd > maxImages) {
          _showSnackBar(context, 'Maksimal $maxImages gambar');
          return;
        }

        _selectedImages.addAll(pickedFiles.map((file) => File(file.path)));
        _notifyStateChanged();
      }
    } catch (e) {
      _showSnackBar(context, 'Error picking images: $e');
    }
  }
  
  // Pick single image
  Future<void> pickImage(BuildContext context, ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (pickedFile != null) {
        if (totalImages >= maxImages) {
          _showSnackBar(context, 'Maksimal $maxImages gambar');
          return;
        }

        _selectedImages.add(File(pickedFile.path));
        _notifyStateChanged();
      }
    } catch (e) {
      _showSnackBar(context, 'Error picking image: $e');
    }
  }
  
  // Remove all images
  void removeAllImages() {
    _selectedImages.clear();
    _existingImageUrls.clear();
    _uploadedImageUrls.clear(); // TAMBAHAN
    _notifyStateChanged();
  }
  
  // Remove specific image
  void removeImage(int index, {bool isExisting = false}) {
    if (isExisting) {
      if (index >= 0 && index < _existingImageUrls.length) {
        _existingImageUrls.removeAt(index);
      }
    } else {
      if (index >= 0 && index < _selectedImages.length) {
        _selectedImages.removeAt(index);
      }
    }
    _notifyStateChanged();
  }
  
  // Upload multiple images to Cloudinary
  Future<List<String>> uploadMultipleToCloudinary(BuildContext context) async {
    if (_selectedImages.isEmpty) return [];
    
    _isUploadingImages = true;
    _notifyStateChanged();
    
    List<String> uploadedUrls = [];
    
    try {
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );

      for (int i = 0; i < _selectedImages.length; i++) {
        final imageFile = _selectedImages[i];
        
        Uint8List imageBytes = await imageFile.readAsBytes();

        final request = http.MultipartRequest('POST', url)
          ..fields['upload_preset'] = uploadPreset
          ..files.add(
            http.MultipartFile.fromBytes(
              'file',
              imageBytes,
              filename: 'laporan_${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
              contentType: MediaType('image', 'jpeg'),
            ),
          );

        final response = await request.send();

        if (response.statusCode == 200) {
          final res = await http.Response.fromStream(response);
          final data = json.decode(res.body);
          uploadedUrls.add(data['secure_url']);
        } else {
          print('Cloudinary upload failed for image $i: ${response.statusCode}');
        }
      }

      // TAMBAHAN: Simpan uploaded URLs
      _uploadedImageUrls = uploadedUrls;
      
      return uploadedUrls;
    } catch (e) {
      print('Cloudinary upload error: $e');
      _showSnackBar(context, 'Error uploading images: $e');
      return [];
    } finally {
      _isUploadingImages = false;
      _notifyStateChanged();
    }
  }
  
  // TAMBAHAN: Method baru untuk upload gambar dan kirim ke backend
  Future<bool> uploadImagesAndSubmitToBackend({
    required BuildContext context,
    required String apiUrl,
    required String token,
    required Map<String, dynamic> laporanData,
  }) async {
    try {
      // 1. Upload gambar ke Cloudinary dulu
      List<String> imageUrls = await uploadMultipleToCloudinary(context);
      
      // 2. Tambahkan URL gambar ke data laporan
      laporanData['gambar'] = imageUrls; // PENTING: Field ini yang akan dikirim ke backend
      
      // 3. Kirim data laporan (termasuk URL gambar) ke backend
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(laporanData),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackBar(context, 'Laporan berhasil disimpan', Colors.green);
        // Clear selected images after successful upload
        clearSelectedImages();
        return true;
      } else {
        _showSnackBar(context, 'Gagal menyimpan laporan: ${response.statusCode}', Colors.red);
        return false;
      }
      
    } catch (e) {
      print('Error submitting laporan: $e');
      _showSnackBar(context, 'Error: $e', Colors.red);
      return false;
    }
  }
  
  // ALTERNATIF: Method untuk upload dengan multipart ke backend langsung
  Future<bool> uploadImagesDirectlyToBackend({
    required BuildContext context,
    required String apiUrl,
    required String token,
    required Map<String, String> textFields, // Data laporan lainnya
  }) async {
    if (_selectedImages.isEmpty) {
      // Jika tidak ada gambar, kirim data biasa
      return await _submitTextDataOnly(context, apiUrl, token, textFields);
    }
    
    _isUploadingImages = true;
    _notifyStateChanged();
    
    try {
      // 1. Upload ke Cloudinary dulu
      List<String> imageUrls = await uploadMultipleToCloudinary(context);
      
      // 2. Buat multipart request ke backend
      final request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      
      // Add headers
      request.headers['Authorization'] = 'Bearer $token';
      
      // Add text fields
      request.fields.addAll(textFields);
      
      // Add image URLs as JSON string
      request.fields['gambar'] = json.encode(imageUrls);
      
      final response = await request.send();
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackBar(context, 'Laporan berhasil disimpan', Colors.green);
        clearSelectedImages();
        return true;
      } else {
        final responseBody = await response.stream.bytesToString();
        print('Backend error: ${response.statusCode} - $responseBody');
        _showSnackBar(context, 'Gagal menyimpan laporan: ${response.statusCode}', Colors.red);
        return false;
      }
      
    } catch (e) {
      print('Error uploading to backend: $e');
      _showSnackBar(context, 'Error: $e', Colors.red);
      return false;
    } finally {
      _isUploadingImages = false;
      _notifyStateChanged();
    }
  }
  
  // Helper method untuk kirim data tanpa gambar
  Future<bool> _submitTextDataOnly(
    BuildContext context,
    String apiUrl,
    String token,
    Map<String, String> textFields,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          ...textFields,
          'gambar': [], // Array kosong jika tidak ada gambar
        }),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackBar(context, 'Laporan berhasil disimpan', Colors.green);
        return true;
      } else {
        _showSnackBar(context, 'Gagal menyimpan laporan: ${response.statusCode}', Colors.red);
        return false;
      }
    } catch (e) {
      _showSnackBar(context, 'Error: $e', Colors.red);
      return false;
    }
  }
  
  // Get all image URLs (existing + newly uploaded)
  List<String> getAllImageUrls([List<String>? newlyUploadedUrls]) {
    List<String> allUrls = List<String>.from(_existingImageUrls);
    if (newlyUploadedUrls != null) {
      allUrls.addAll(newlyUploadedUrls);
    } else {
      allUrls.addAll(_uploadedImageUrls);
    }
    return allUrls;
  }
  
  // Clear selected images after successful upload
  void clearSelectedImages() {
    _selectedImages.clear();
    _notifyStateChanged();
  }
  
  // Helper method to show snackbar
  void _showSnackBar(BuildContext context, String message, [Color? backgroundColor]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }
}