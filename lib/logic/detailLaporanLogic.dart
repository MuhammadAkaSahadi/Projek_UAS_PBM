import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:projek_uas/providers/laporan_provider.dart';
import 'package:projek_uas/screen/KebunSaya/DetailLaporan/image_handler.dart';

class DetailLaporanLogic {
  // Controllers
  final TextEditingController tanggalTanamController = TextEditingController();
  final TextEditingController jenisTanamanController = TextEditingController();
  final TextEditingController jumlahPupukController = TextEditingController();
  final TextEditingController jumlahPestisidaController =
      TextEditingController();
  final TextEditingController teknikPengolahanController =
      TextEditingController();
  final TextEditingController tanggalKunjunganController =
      TextEditingController();
  final TextEditingController materiPenyuluhanController =
      TextEditingController();
  final TextEditingController kritikDanSaranController =
      TextEditingController();
  final TextEditingController deskripsiKendalaController =
      TextEditingController();
  final TextEditingController tanggalPanenController = TextEditingController();
  final TextEditingController totalPanenController =
      TextEditingController();
  final TextEditingController kualitasHasilController = TextEditingController();
  final TextEditingController deskripsiCatatanController =
      TextEditingController();

  // State variables
  bool isInitialized = false;
  bool isLoading = true;
  late ImageHandlerService imageHandler;

  // Dropdown values
  String sumberBenih = 'Mandiri';
  String satuanPupuk = 'Kg';
  String satuanPestisida = 'L';
  String satuanPanen = 'Kg';
  String kualitasHasil = 'Bagus';

  // Dropdown options
  final List<String> sumberBenihOptions = [
    'Mandiri',
    'Bantuan',
    'Dinas',
    'Lainnya',
  ];
  final List<String> satuanPupukOptions = ['Kg', 'L', 'Ton'];
  final List<String> satuanPestisidaOptions = ['Kg', 'L'];
  final List<String> satuanPanenOptions = [
    'Kg',
    'Ton',
  ];
  final List<String> kualitasHasilOptions = ['Bagus', 'Sedang', 'Rusak'];

  // Callback untuk update UI
  final VoidCallback? onStateChanged;

  DetailLaporanLogic({this.onStateChanged});

  // Initialize logic
  void initialize(BuildContext context) {
    imageHandler = ImageHandlerService(
      context: context,
      onStateChanged: () {
        onStateChanged?.call();
      },
    );
  }

  // FIXED: Initialize data dengan token parameter
  Future<void> initializeData(
    BuildContext context,
    int idLahan,
    bool isEdit,
  ) async {
    if (isEdit) {
      await loadExistingData(context, idLahan);
    }
    isLoading = false;
    isInitialized = true;
    onStateChanged?.call();
  }

  // FIXED: Load existing data dengan token parameter
  Future<void> loadExistingData(BuildContext context, int idLahan) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null) {
        print('❌ Token tidak ditemukan saat load existing data');
        return;
      }

      final laporanProvider = Provider.of<LaporanProvider>(
        context,
        listen: false,
      );

      // FIXED: Pass token to fetchLaporan
      await laporanProvider.fetchLaporan(idLahan, token);
      final laporan = laporanProvider.getLaporan(idLahan);
      if (laporan != null) {
        populateFormFromExistingData(laporan);
        print('✅ Data existing berhasil dimuat untuk idLahan: $idLahan');
      } else {
        print('⚠️ Tidak ada data laporan untuk idLahan: $idLahan');
      }
    } catch (e) {
      print('❌ Error loading existing data: $e');
    }
  }

  // Extract image URLs using the same logic as DetailLahanLogic
  List<String> _getImageUrls(Map<String, dynamic> laporan) {
    List<String> imageUrls = [];

    try {
      // Cek berbagai format data gambar yang mungkin

      // 1. Field imageUrls sebagai array (format baru dari DetailLaporan)
      if (laporan['imageUrls'] != null && laporan['imageUrls'] is List) {
        for (var url in laporan['imageUrls']) {
          if (url is String && url.isNotEmpty && _isValidUrl(url)) {
            imageUrls.add(url);
          }
        }
      }

      // 2. Field imageUrl tunggal (untuk backward compatibility)
      if (laporan['imageUrl'] != null &&
          laporan['imageUrl'].toString().isNotEmpty &&
          _isValidUrl(laporan['imageUrl'].toString())) {
        final singleUrl = laporan['imageUrl'].toString();
        if (!imageUrls.contains(singleUrl)) {
          imageUrls.add(singleUrl);
        }
      }

      // 3. Field gambar sebagai array (format lama)
      if (laporan['gambar'] != null && laporan['gambar'] is List) {
        for (var gambar in laporan['gambar']) {
          String? url;

          if (gambar is String && gambar.isNotEmpty) {
            url = gambar;
          } else if (gambar is Map) {
            // Cek berbagai kemungkinan field name
            url = gambar['url_gambar'] ??
                gambar['url'] ??
                gambar['image_url'] ??
                gambar['gambar'] ??
                gambar['Url_Gambar']; // FIXED: Added capital case
          }

          if (url != null &&
              url.isNotEmpty &&
              _isValidUrl(url) &&
              !imageUrls.contains(url)) {
            imageUrls.add(url);
          }
        }
      }

      // 4. Field images sebagai array (format alternatif)
      if (laporan['images'] != null && laporan['images'] is List) {
        for (var img in laporan['images']) {
          String? url;

          if (img is String && img.isNotEmpty) {
            url = img;
          } else if (img is Map) {
            url = img['url'] ?? img['image_url'] ?? img['src'];
          }

          if (url != null &&
              url.isNotEmpty &&
              _isValidUrl(url) &&
              !imageUrls.contains(url)) {
            imageUrls.add(url);
          }
        }
      }

      // Debug print untuk troubleshooting
      print('=== IMAGE DEBUG (DetailLaporanLogic) ===');
      print('Laporan keys: ${laporan.keys.toList()}');
      print('Found ${imageUrls.length} images: $imageUrls');
      print('=======================================');
    } catch (e) {
      print('Error getting image URLs: $e');
    }

    return imageUrls;
  }

  // Helper method to validate URLs
  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  // Populate form from existing data - FIXED to match provider structure
  void populateFormFromExistingData(Map<String, dynamic> laporan) {
    try {
      print('=== POPULATING FORM FROM EXISTING DATA ===');
      print('Laporan structure: ${laporan.keys.toList()}');

      // Data Musim Tanam - FIXED field names to match provider
      final musimTanam = laporan['musimTanam'] as List<dynamic>?;
      if (musimTanam != null && musimTanam.isNotEmpty) {
        final firstMusimTanam = musimTanam[0] as Map<String, dynamic>;
        print('MusimTanam data: $firstMusimTanam');

        tanggalTanamController.text = formatDateForDisplay(
          firstMusimTanam['tanggal_mulai_tanam']?.toString() ??
              firstMusimTanam['Tanggal_Mulai_Tanam']?.toString() ??
              '',
        );
        jenisTanamanController.text =
            firstMusimTanam['jenis_tanaman']?.toString() ??
            firstMusimTanam['Jenis_Tanaman']?.toString() ??
            '';
        sumberBenih =
            firstMusimTanam['sumber_benih']?.toString() ??
            firstMusimTanam['Sumber_Benih']?.toString() ??
            'Mandiri';
      }

      final inputProduksi = laporan['inputProduksi'] as List<dynamic>?;
      if (inputProduksi != null && inputProduksi.isNotEmpty) {
        final firstInput = inputProduksi[0] as Map<String, dynamic>;
        print('InputProduksi data: $firstInput');
        jumlahPupukController.text =
            firstInput['jumlah_pupuk']?.toString() ??
            firstInput['Jumlah_Pupuk']?.toString() ??
            '';
        jumlahPestisidaController.text =
            firstInput['jumlah_pestisida']?.toString() ??
            firstInput['Jumlah_Pestisida']?.toString() ??
            '';
        teknikPengolahanController.text =
            firstInput['teknik_pengolahan_tanah']?.toString() ??
            firstInput['Teknik_Pengolahan_Tanah']?.toString() ??
            '';
        satuanPupuk =
            firstInput['satuan_pupuk']?.toString() ??
            firstInput['Satuan_Pupuk']?.toString() ??
            'Kg';
        satuanPestisida =
            firstInput['satuan_pestisida']?.toString() ??
            firstInput['Satuan_Pestisida']?.toString() ??
            'L';
      }

      // Data Pendampingan - FIXED field names
      final pendampingan = laporan['pendampingan'] as List<dynamic>?;
      if (pendampingan != null && pendampingan.isNotEmpty) {
        final firstPendampingan = pendampingan[0] as Map<String, dynamic>;
        print('Pendampingan data: $firstPendampingan');

        tanggalKunjunganController.text = formatDateForDisplay(
          firstPendampingan['tanggal_kunjungan']?.toString() ??
              firstPendampingan['Tanggal_Kunjungan']?.toString() ??
              '',
        );
        materiPenyuluhanController.text =
            firstPendampingan['materi_penyuluhan']?.toString() ??
            firstPendampingan['Materi_Penyuluhan']?.toString() ??
            '';
        kritikDanSaranController.text =
            firstPendampingan['kritik_dan_saran']?.toString() ??
            firstPendampingan['Kritik_Dan_Saran']?.toString() ??
            '';
      }

      // Data Kendala - FIXED field names
      final kendala = laporan['kendala'] as List<dynamic>?;
      if (kendala != null && kendala.isNotEmpty) {
        final firstKendala = kendala[0] as Map<String, dynamic>;
        print('Kendala data: $firstKendala');

        deskripsiKendalaController.text =
            firstKendala['deskripsi']?.toString() ??
            firstKendala['Deskripsi']?.toString() ??
            '';
      }

      // Data Hasil Panen - FIXED field names and controller assignment
      final hasilPanen = laporan['hasilPanen'] as List<dynamic>?;
      if (hasilPanen != null && hasilPanen.isNotEmpty) {
        final firstHasil = hasilPanen[0] as Map<String, dynamic>;
        print('HasilPanen data: $firstHasil');

        tanggalPanenController.text = formatDateForDisplay(
          firstHasil['tanggal_panen']?.toString() ??
              firstHasil['Tanggal_Panen']?.toString() ??
              '',
        );
        totalPanenController.text =
            firstHasil['total_hasil_panen']?.toString() ??
            firstHasil['Total_Hasil_Panen']?.toString() ??
            '';
        satuanPanen =
            firstHasil['satuan_panen']?.toString() ??
            firstHasil['Satuan_Panen']?.toString() ??
            'Kg';
        kualitasHasil =
            firstHasil['kualitas']?.toString() ??
            firstHasil['Kualitas']?.toString() ??
            'Bagus';
      }

      // Data Catatan - FIXED field names
      final catatan = laporan['catatan'] as List<dynamic>?;
      if (catatan != null && catatan.isNotEmpty) {
        final firstCatatan = catatan[0] as Map<String, dynamic>;
        print('Catatan data: $firstCatatan');

        deskripsiCatatanController.text =
            firstCatatan['deskripsi']?.toString() ??
            firstCatatan['Deskripsi']?.toString() ??
            '';
      }

      // Load existing images using local method instead of provider method
      List<String> existingImages = _getImageUrls(laporan);

      if (existingImages.isNotEmpty) {
        imageHandler.initializeWithExistingImages(existingImages);
        print(
          '✅ Loaded ${existingImages.length} existing images: $existingImages',
        );
      }

      print('=== FORM POPULATION COMPLETED ===');
    } catch (e) {
      print('❌ Error populating form: $e');
    }
  }

  // Format date for display
  String formatDateForDisplay(String dateString) {
    try {
      if (dateString.isEmpty) return '';
      DateTime date = DateTime.parse(dateString);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      print('Date parsing error: $e for date: $dateString');
      return dateString;
    }
  }

  // Format date to ISO string
  String formatTanggal(String input) {
    try {
      if (input.isEmpty) return DateTime.now().toIso8601String();
      DateTime parsed = DateTime.parse(input);
      return parsed.toIso8601String();
    } catch (e) {
      print('Date formatting error: $e for input: $input');
      return DateTime.now().toIso8601String();
    }
  }

  // Validate form
  bool validateForm(BuildContext context) {
    if (tanggalTanamController.text.isEmpty ||
        jenisTanamanController.text.isEmpty ||
        jumlahPupukController.text.isEmpty ||
        jumlahPestisidaController.text.isEmpty ||
        teknikPengolahanController.text.isEmpty ||
        tanggalKunjunganController.text.isEmpty ||
        materiPenyuluhanController.text.isEmpty ||
        kritikDanSaranController.text.isEmpty ||
        deskripsiKendalaController.text.isEmpty ||
        tanggalPanenController.text.isEmpty ||
        totalPanenController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Semua field harus diisi.")));
      return false;
    }

    if (double.tryParse(jumlahPupukController.text) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Jumlah pupuk harus berupa angka.")),
      );
      return false;
    }

    if (double.tryParse(jumlahPestisidaController.text) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Jumlah pestisida harus berupa angka.")),
      );
      return false;
    }

    if (double.tryParse(totalPanenController.text) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Total hasil panen harus berupa angka.")),
      );
      return false;
    }

    return true;
  }

  // FIXED: Prepare laporan data dengan field yang sesuai API
  Map<String, dynamic> prepareLaporanData() {
    return {
      'musimTanam': {
        'tanggalTanam': formatTanggal(tanggalTanamController.text),
        'jenisTanaman': jenisTanamanController.text,
        'sumberBenih': sumberBenih,
      },
      'inputProduksi': {
        'jenisPupuk': 'Tidak Diketahui', // FIXED: Added required field
        'jumlahPupuk': double.tryParse(jumlahPupukController.text) ?? 0.0,
        'satuanPupuk': satuanPupuk,
        'jumlahPestisida':
            double.tryParse(jumlahPestisidaController.text) ?? 0.0,
        'satuanPestisida': satuanPestisida,
        'teknikPengolahan': teknikPengolahanController.text,
      },
      'pendampingan': {
        'tanggalKunjungan': formatTanggal(tanggalKunjunganController.text),
        'materiPenyuluhan': materiPenyuluhanController.text,
        'kritikSaran': kritikDanSaranController.text,
      },
      'kendala': {'deskripsi': deskripsiKendalaController.text},
      'hasilPanen': {
        'tanggalPanen': formatTanggal(tanggalPanenController.text),
        'totalPanen': double.tryParse(totalPanenController.text) ?? 0.0,
        'satuanPanen': satuanPanen,
        'kualitas': kualitasHasil,
      },
      'catatan': {'deskripsi': deskripsiCatatanController.text},
    };
  }

  // FIXED: Save laporan dengan token handling yang proper
  Future<bool> saveLaporan(
    BuildContext context,
    int idLahan,
    bool isEdit,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Token tidak ditemukan. Harap login ulang."),
          ),
        );
        return false;
      }

      if (!validateForm(context)) return false;

      // Upload gambar baru ke Cloudinary jika ada
      List<String> newlyUploadedUrls = [];
      if (imageHandler.hasSelectedImages) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Mengupload gambar...')));

        newlyUploadedUrls = await imageHandler.uploadMultipleToCloudinary(
          onUploadStart: () {
            print('Starting image upload...');
          },
          onProgress: (current, total) {
            print('Uploading image $current of $total');
          },
          onUploadComplete: () {
            print('Image upload completed');
          },
        );

        if (newlyUploadedUrls.isEmpty && imageHandler.hasSelectedImages) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Gagal mengupload beberapa gambar. Melanjutkan dengan gambar yang berhasil diupload.',
              ),
            ),
          );
        }
      }

      // Combine all image URLs (existing + newly uploaded)
      final allImageUrls = <String>[];
      allImageUrls.addAll(imageHandler.existingImageUrls);
      allImageUrls.addAll(newlyUploadedUrls);

      // Remove duplicates
      final uniqueImageUrls = allImageUrls.toSet().toList();

      // Siapkan data laporan
      final laporanData = prepareLaporanData();

      // Gunakan provider untuk save atau update
      final laporanProvider = Provider.of<LaporanProvider>(
        context,
        listen: false,
      );

      bool success;
      if (isEdit) {
        // Mode edit - gunakan update
        final idLaporanLahan = laporanProvider.getLaporanLahanId(idLahan);
        if (idLaporanLahan == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ID Laporan tidak ditemukan')),
          );
          return false;
        }

        success = await laporanProvider.updateLaporan(
          token: token,
          idLaporanLahan: idLaporanLahan,
          laporanData: laporanData,
          imageUrls: uniqueImageUrls.isNotEmpty ? uniqueImageUrls : null,
        );
      } else {
        // Mode create - gunakan save
        success = await laporanProvider.saveLaporan(
          token: token,
          idLahan: idLahan,
          laporanData: laporanData,
          imageUrls: uniqueImageUrls.isNotEmpty ? uniqueImageUrls : null,
        );
      }

      if (success) {
        // Clear selected images but keep existing ones
        _clearSelectedImagesOnly();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEdit
                  ? 'Laporan berhasil diperbarui'
                  : 'Laporan berhasil disimpan',
            ),
          ),
        );
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal ${isEdit ? 'memperbarui' : 'menyimpan'} laporan: ${laporanProvider.error}',
            ),
          ),
        );
        return false;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal ${isEdit ? 'memperbarui' : 'menyimpan'} laporan: $e',
          ),
        ),
      );
      return false;
    }
  }

  // Helper method to clear only selected images, not existing ones
  void _clearSelectedImagesOnly() {
    // Move uploaded images to existing images to preserve them
    if (imageHandler.uploadedImageUrls.isNotEmpty) {
      final currentExisting = List<String>.from(imageHandler.existingImageUrls);
      currentExisting.addAll(imageHandler.uploadedImageUrls);
      imageHandler.initializeWithExistingImages(currentExisting);
    }

    // Clear uploaded URLs since they're now part of existing
    imageHandler.clearUploadedImages();
  }

  // Get image handler for UI access
  ImageHandlerService get getImageHandler => imageHandler;

  // Methods to work with images through the logic layer
  void showImagePicker() {
    imageHandler.showImageSourceDialog();
  }

  bool get hasImages => imageHandler.hasImages;
  bool get isUploadingImages => imageHandler.isUploadingImages;
  int get totalImages => imageHandler.totalImages;

  // Get all image URLs for display
  List<String> getAllDisplayImages() {
    final List<String> allImages = [];
    allImages.addAll(imageHandler.existingImageUrls);
    allImages.addAll(imageHandler.uploadedImageUrls);
    return allImages;
  }

  // Update dropdown values
  void updateSumberBenih(String? value) {
    if (value != null) {
      sumberBenih = value;
      onStateChanged?.call();
    }
  }

  void updateSatuanPupuk(String? value) {
    if (value != null) {
      satuanPupuk = value;
      onStateChanged?.call();
    }
  }

  void updateSatuanPestisida(String? value) {
    if (value != null) {
      satuanPestisida = value;
      onStateChanged?.call();
    }
  }

  void updateSatuanPanen(String? value) {
    if (value != null) {
      satuanPanen = value;
      onStateChanged?.call();
    }
  }

  void updateKualitasHasil(String? value) {
    if (value != null) {
      kualitasHasil = value;
      onStateChanged?.call();
    }
  }

  // Dispose controllers and image handler
  void dispose() {
    tanggalTanamController.dispose();
    jenisTanamanController.dispose();
    jumlahPupukController.dispose();
    jumlahPestisidaController.dispose();
    teknikPengolahanController.dispose();
    tanggalKunjunganController.dispose();
    materiPenyuluhanController.dispose();
    kritikDanSaranController.dispose();
    deskripsiKendalaController.dispose();
    tanggalPanenController.dispose();
    totalPanenController.dispose();
    kualitasHasilController.dispose();
    deskripsiCatatanController.dispose();

    imageHandler.dispose();
  }
}