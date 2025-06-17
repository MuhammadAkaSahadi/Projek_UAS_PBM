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
  final TextEditingController jumlahPestisidaController = TextEditingController();
  final TextEditingController teknikPengolahanController = TextEditingController();
  final TextEditingController tanggalKunjunganController = TextEditingController();
  final TextEditingController materiPenyuluhanController = TextEditingController();
  final TextEditingController kritikDanSaranController = TextEditingController();
  final TextEditingController deskripsiKendalaController = TextEditingController();
  final TextEditingController tanggalPanenController = TextEditingController();
  final TextEditingController satuanPanenController = TextEditingController();
  final TextEditingController kualitasHasilController = TextEditingController();
  final TextEditingController deskripsiCatatanController = TextEditingController();

  // State variables
  bool isInitialized = false;
  bool isLoading = true;
  late ImageHandlerService imageHandler;

  // Dropdown values
  String sumberBenih = 'Mandiri';
  String satuanPupuk = 'Kg';
  String satuanPestisida = 'L';
  String satuanPanen = 'Ton';
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
  final List<String> satuanPanenOptions = ['Kg', 'Ton'];
  final List<String> kualitasHasilOptions = ['Bagus', 'Sedang', 'Rusak'];

  // Callback untuk update UI
  final VoidCallback? onStateChanged;

  DetailLaporanLogic({this.onStateChanged});

  // Initialize logic
  void initialize() {
    imageHandler = ImageHandlerService(
      onStateChanged: () {
        if (onStateChanged != null) {
          onStateChanged!();
        }
      },
    );
  }

  // Initialize data
  Future<void> initializeData(BuildContext context, int idLahan, bool isEdit) async {
    if (isEdit) {
      await loadExistingData(context, idLahan);
    }
    isLoading = false;
    isInitialized = true;
    if (onStateChanged != null) {
      onStateChanged!();
    }
  }

  // Load existing data
  Future<void> loadExistingData(BuildContext context, int idLahan) async {
    try {
      final laporanProvider = Provider.of<LaporanProvider>(
        context,
        listen: false,
      );

      await laporanProvider.fetchLaporan(idLahan);
      final laporan = laporanProvider.getLaporan(idLahan);
      if (laporan != null) {
        populateFormFromExistingData(laporan);
      }
    } catch (e) {
      print('Error loading existing data: $e');
    }
  }

  // Populate form from existing data
  void populateFormFromExistingData(Map<String, dynamic> laporan) {
    try {
      // Data Musim Tanam
      final musimTanam = laporan['musimTanam'];
      if (musimTanam != null && musimTanam.isNotEmpty) {
        final firstMusimTanam = musimTanam[0];
        tanggalTanamController.text = formatDateForDisplay(
          firstMusimTanam['tanggal_mulai_tanam'] ?? '',
        );
        jenisTanamanController.text = firstMusimTanam['jenis_tanaman'] ?? '';
        sumberBenih = firstMusimTanam['sumber_benih'] ?? 'Mandiri';
      }

      // Data Input Produksi
      final inputProduksi = laporan['inputProduksi'];
      if (inputProduksi != null && inputProduksi.isNotEmpty) {
        final firstInput = inputProduksi[0];
        jumlahPupukController.text = firstInput['jumlah_pupuk']?.toString() ?? '';
        jumlahPestisidaController.text = firstInput['jumlah_pestisida']?.toString() ?? '';
        teknikPengolahanController.text = firstInput['teknik_pengolahan_tanah'] ?? '';
        satuanPupuk = firstInput['satuan_pupuk'] ?? 'Kg';
        satuanPestisida = firstInput['satuan_pestisida'] ?? 'L';
      }

      // Data Pendampingan
      final pendampingan = laporan['pendampingan'];
      if (pendampingan != null && pendampingan.isNotEmpty) {
        final firstPendampingan = pendampingan[0];
        tanggalKunjunganController.text = formatDateForDisplay(
          firstPendampingan['tanggal_kunjungan'] ?? '',
        );
        materiPenyuluhanController.text = firstPendampingan['materi_penyuluhan'] ?? '';
        kritikDanSaranController.text = firstPendampingan['kritik_dan_saran'] ?? '';
      }

      // Data Kendala
      final kendala = laporan['kendala'];
      if (kendala != null && kendala.isNotEmpty) {
        final firstKendala = kendala[0];
        deskripsiKendalaController.text = firstKendala['deskripsi'] ?? '';
      }

      // Data Hasil Panen
      final hasilPanen = laporan['hasilPanen'];
      if (hasilPanen != null && hasilPanen.isNotEmpty) {
        final firstHasil = hasilPanen[0];
        tanggalPanenController.text = formatDateForDisplay(
          firstHasil['tanggal_panen'] ?? '',
        );
        satuanPanenController.text = firstHasil['total_hasil_panen']?.toString() ?? '';
        kualitasHasilController.text = firstHasil['kualitas'] ?? '';
        satuanPanen = firstHasil['satuan_panen'] ?? 'Ton';
        kualitasHasil = firstHasil['kualitas'] ?? 'Bagus';
      }

      // Data Catatan
      final catatan = laporan['catatan'];
      if (catatan != null && catatan.isNotEmpty) {
        final firstCatatan = catatan[0];
        deskripsiCatatanController.text = firstCatatan['deskripsi'] ?? '';
      }

      // Load existing images
      List<String> existingImages = [];
      
      if (laporan['imageUrls'] != null && laporan['imageUrls'] is List) {
        existingImages = List<String>.from(laporan['imageUrls']);
      } else if (laporan['imageUrl'] != null && laporan['imageUrl'].toString().isNotEmpty) {
        existingImages = [laporan['imageUrl'].toString()];
      } else if (laporan['images'] != null && laporan['images'] is List) {
        for (var img in laporan['images']) {
          if (img is String && img.isNotEmpty) {
            existingImages.add(img);
          } else if (img is Map && img['url'] != null) {
            existingImages.add(img['url'].toString());
          }
        }
      }

      if (existingImages.isNotEmpty) {
        imageHandler.initializeWithExistingImages(existingImages);
      }
    } catch (e) {
      print('Error populating form: $e');
    }
  }

  // Format date for display
  String formatDateForDisplay(String dateString) {
    try {
      if (dateString.isEmpty) return '';
      DateTime date = DateTime.parse(dateString);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  // Format date
  String formatTanggal(String input) {
    try {
      DateTime parsed = DateTime.parse(input);
      return parsed.toIso8601String().split('T')[0];
    } catch (e) {
      return input;
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
        satuanPanenController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Semua field harus diisi.")),
      );
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

    if (double.tryParse(satuanPanenController.text) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Total hasil panen harus berupa angka.")),
      );
      return false;
    }

    return true;
  }

  // Prepare laporan data
  Map<String, dynamic> prepareLaporanData(List<String> newlyUploadedUrls) {
    final allImageUrls = imageHandler.getAllImageUrls(newlyUploadedUrls);

    return {
      'musimTanam': {
        'tanggalTanam': formatTanggal(tanggalTanamController.text),
        'jenisTanaman': jenisTanamanController.text,
        'sumberBenih': sumberBenih,
      },
      'inputProduksi': {
        'jumlahPupuk': double.parse(jumlahPupukController.text),
        'satuanPupuk': satuanPupuk,
        'jumlahPestisida': double.parse(jumlahPestisidaController.text),
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
        'totalPanen': double.parse(satuanPanenController.text),
        'satuanPanen': satuanPanen,
        'kualitas': kualitasHasil,
      },
      'catatan': {'deskripsi': deskripsiCatatanController.text},
      'imageUrls': allImageUrls,
      'imageUrl': allImageUrls.isNotEmpty ? allImageUrls.first : null,
    };
  }

  // Save laporan
  Future<bool> saveLaporan(BuildContext context, int idLahan, bool isEdit) async {
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
      if (imageHandler.selectedImages.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mengupload gambar...')),
        );

        newlyUploadedUrls = await imageHandler.uploadMultipleToCloudinary(context);

        if (newlyUploadedUrls.isEmpty && imageHandler.selectedImages.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal mengupload beberapa gambar. Melanjutkan dengan gambar yang berhasil diupload.'),
            ),
          );
        }
      }

      // Siapkan data laporan
      final laporanData = prepareLaporanData(newlyUploadedUrls);

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
          image: null,
        );
      } else {
        // Mode create - gunakan save
        success = await laporanProvider.saveLaporan(
          token: token,
          idLahan: idLahan,
          laporanData: laporanData,
          image: null,
        );
      }

      if (success) {
        imageHandler.clearSelectedImages();
        
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

  // Update dropdown values
  void updateSumberBenih(String? value) {
    if (value != null) {
      sumberBenih = value;
      if (onStateChanged != null) onStateChanged!();
    }
  }

  void updateSatuanPupuk(String? value) {
    if (value != null) {
      satuanPupuk = value;
      if (onStateChanged != null) onStateChanged!();
    }
  }

  void updateSatuanPestisida(String? value) {
    if (value != null) {
      satuanPestisida = value;
      if (onStateChanged != null) onStateChanged!();
    }
  }

  void updateSatuanPanen(String? value) {
    if (value != null) {
      satuanPanen = value;
      if (onStateChanged != null) onStateChanged!();
    }
  }

  void updateKualitasHasil(String? value) {
    if (value != null) {
      kualitasHasil = value;
      if (onStateChanged != null) onStateChanged!();
    }
  }

  // Dispose controllers
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
    satuanPanenController.dispose();
    kualitasHasilController.dispose();
    deskripsiCatatanController.dispose();
  }
}