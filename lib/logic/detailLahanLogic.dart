import 'package:flutter/material.dart';
import 'package:projek_uas/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:projek_uas/screen/KebunSaya/detailLaporan.dart';
import 'package:projek_uas/providers/lahan_provider.dart';
import 'package:projek_uas/providers/laporan_provider.dart';

extension FirstOrNullExt<T> on List<T> {
  T? firstOrNull() => isEmpty ? null : first;
}

class DetailLahanLogic {
  final BuildContext context;
  final int idLahan;
  String? token;

  DetailLahanLogic(this.context, this.idLahan);

  // ===== TOKEN MANAGEMENT =====
  Future<String?> getTokenFromAuthProvider() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      return authProvider.token;
    } catch (e) {
      print('Error getting token from provider: $e');
      return null;
    }
  }

  // ===== DATA INITIALIZATION =====
  Future<void> initializeData() async {
    token = await getTokenFromAuthProvider();

    // Fetch laporan menggunakan provider
    final laporanProvider = Provider.of<LaporanProvider>(
      context,
      listen: false,
    );
    await laporanProvider.fetchLaporan(idLahan);
  }

  // ===== LAPORAN OPERATIONS =====
  Future<void> refreshLaporan() async {
    final laporanProvider = Provider.of<LaporanProvider>(
      context,
      listen: false,
    );
    // Clear cache dulu untuk memastikan data terbaru
    laporanProvider.clearLaporanCache(idLahan);
    await laporanProvider.fetchLaporan(idLahan);
  }

  Future<void> createLaporan() async {
    if (token == null) {
      _showSnackBar(
        'Token tidak tersedia. Silakan login ulang.',
        Colors.red,
      );
      return;
    }

    // Navigate ke halaman create laporan
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailLaporan(idLahan: idLahan, isEdit: false),
      ),
    );

    // Jika create berhasil, refresh data
    if (result == true) {
      await refreshLaporan();
      _showSnackBar(
        'Laporan berhasil dibuat',
        Colors.green,
      );
    }
  }

  Future<void> editLaporan() async {
    if (token == null) {
      _showSnackBar(
        'Token tidak tersedia. Silakan login ulang.',
        Colors.red,
      );
      return;
    }

    // Navigate ke halaman edit dengan data laporan yang sudah ada
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailLaporan(idLahan: idLahan, isEdit: true),
      ),
    );

    // Jika edit berhasil, refresh data
    if (result == true) {
      await refreshLaporan();
      _showSnackBar(
        'Laporan berhasil diperbarui',
        Colors.green,
      );
    }
  }

  Future<void> deleteLaporan() async {
    if (token == null) {
      _showSnackBar(
        'Token tidak tersedia. Silakan login ulang.',
        Colors.red,
      );
      return;
    }

    // Dapatkan ID laporan lahan dari provider
    final laporanProvider = Provider.of<LaporanProvider>(
      context,
      listen: false,
    );
    final idLaporanLahan = laporanProvider.getLaporanLahanId(idLahan);

    if (idLaporanLahan == null) {
      _showSnackBar(
        'ID laporan tidak ditemukan',
        Colors.red,
      );
      return;
    }

    // Tampilkan dialog konfirmasi
    final shouldDelete = await _showDeleteConfirmationDialog();

    if (shouldDelete == true) {
      // Tampilkan loading
      _showLoadingDialog();

      final success = await laporanProvider.deleteLaporan(
        token!,
        idLaporanLahan,
      );

      // Tutup loading dialog
      Navigator.of(context).pop();

      if (success) {
        _showSnackBar(
          'Laporan berhasil dihapus',
          Colors.green,
        );
        // Refresh data untuk update UI
        await refreshLaporan();
      } else {
        _showSnackBar(
          laporanProvider.error ?? 'Gagal menghapus laporan',
          Colors.red,
        );
      }
    }
  }

  // ===== IMAGE PROCESSING =====
  List<String> getImageUrls(Map<String, dynamic> laporan) {
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
                gambar['gambar'];
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
      print('=== IMAGE DEBUG ===');
      print('Laporan keys: ${laporan.keys.toList()}');
      print('Found ${imageUrls.length} images: $imageUrls');
      print('==================');
    } catch (e) {
      print('Error getting image URLs: $e');
    }

    return imageUrls;
  }

  bool hasImages(Map<String, dynamic>? laporan) {
    if (laporan == null) return false;
    final imageUrls = getImageUrls(laporan);
    return imageUrls.isNotEmpty;
  }

  // ===== DATA FORMATTING =====
  String formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String formatNumber(dynamic number, String unit) {
    if (number == null) return '-';
    return '$number $unit';
  }

  String formatLuasLahan(LahanProvider lahanProvider) {
    return lahanProvider.formatLuasLahan(idLahan);
  }

  String formatKoordinat(LahanProvider lahanProvider) {
    return lahanProvider.formatKoordinat(idLahan);
  }

  String formatCentroidLat(LahanProvider lahanProvider) {
    return lahanProvider.formatCentroid(idLahan, 'lat');
  }

  String formatCentroidLng(LahanProvider lahanProvider) {
    return lahanProvider.formatCentroid(idLahan, 'lng');
  }

  String getNamaLahan(LahanProvider lahanProvider, String fallbackTitle) {
    return lahanProvider.getNamaLahan(idLahan, fallback: fallbackTitle);
  }

  // ===== DATA EXTRACTION =====
  Map<String, String> getMusimTanamData(Map<String, dynamic>? laporan) {
    if (laporan == null ||
        laporan['musimTanam'] == null ||
        laporan['musimTanam'] is! List ||
        (laporan['musimTanam'] as List).isEmpty) {
      return {};
    }

    final musimTanam = (laporan['musimTanam'] as List).firstOrNull();
    return {
      "Tanggal Mulai Tanam": formatDate(musimTanam?['tanggal_mulai_tanam']),
      "Jenis Tanaman": musimTanam?['jenis_tanaman'] ?? '-',
      "Sumber Benih": musimTanam?['sumber_benih'] ?? '-',
    };
  }

  Map<String, String> getInputProduksiData(Map<String, dynamic>? laporan) {
    if (laporan == null ||
        laporan['inputProduksi'] == null ||
        laporan['inputProduksi'] is! List ||
        (laporan['inputProduksi'] as List).isEmpty) {
      return {};
    }

    final inputProduksi = (laporan['inputProduksi'] as List).firstOrNull();
    return {
      "Jumlah Pupuk": formatNumber(
        inputProduksi?['jumlah_pupuk'],
        inputProduksi?['satuan_pupuk'] ?? '',
      ),
      "Jumlah Pestisida": formatNumber(
        inputProduksi?['jumlah_pestisida'],
        inputProduksi?['satuan_pestisida'] ?? '',
      ),
      "Teknik Pengolahan": inputProduksi?['teknik_pengolahan_tanah'] ?? '-',
    };
  }

  Map<String, String> getHasilPanenData(Map<String, dynamic>? laporan) {
    if (laporan == null ||
        laporan['hasilPanen'] == null ||
        laporan['hasilPanen'] is! List ||
        (laporan['hasilPanen'] as List).isEmpty) {
      return {};
    }

    final hasilPanen = (laporan['hasilPanen'] as List).firstOrNull();
    return {
      "Tanggal Panen": formatDate(hasilPanen?['tanggal_panen']),
      "Total Panen": formatNumber(
        hasilPanen?['total_hasil_panen'],
        hasilPanen?['satuan_panen'] ?? '',
      ),
      "Kualitas": hasilPanen?['kualitas'] ?? '-',
    };
  }

  Map<String, String> getPendampinganData(Map<String, dynamic>? laporan) {
    if (laporan == null ||
        laporan['pendampingan'] == null ||
        laporan['pendampingan'] is! List ||
        (laporan['pendampingan'] as List).isEmpty) {
      return {};
    }

    final pendampingan = (laporan['pendampingan'] as List).firstOrNull();
    return {
      "Tanggal Kunjungan": formatDate(pendampingan?['tanggal_kunjungan']),
      "Materi Penyuluhan": pendampingan?['materi_penyuluhan'] ?? '-',
      "Kritik dan Saran": pendampingan?['kritik_dan_saran'] ?? '-',
    };
  }

  Map<String, String> getKendalaData(Map<String, dynamic>? laporan) {
    if (laporan == null ||
        laporan['kendala'] == null ||
        laporan['kendala'] is! List ||
        (laporan['kendala'] as List).isEmpty) {
      return {};
    }

    final kendala = (laporan['kendala'] as List).firstOrNull();
    return {
      "Deskripsi": kendala?['deskripsi'] ?? '-',
    };
  }

  Map<String, String> getCatatanData(Map<String, dynamic>? laporan) {
    if (laporan == null ||
        laporan['catatan'] == null ||
        laporan['catatan'] is! List ||
        (laporan['catatan'] as List).isEmpty) {
      return {};
    }

    final catatan = (laporan['catatan'] as List).firstOrNull();
    return {
      "Deskripsi": catatan?['deskripsi'] ?? '-',
    };
  }

  Map<String, String> getInformasiLahanData(LahanProvider lahanProvider, String fallbackTitle) {
    return {
      "Nama Lahan": getNamaLahan(lahanProvider, fallbackTitle),
      "Luas Lahan": formatLuasLahan(lahanProvider),
      "Koordinat": formatKoordinat(lahanProvider),
      "Centroid Lat": formatCentroidLat(lahanProvider),
      "Centroid Lng": formatCentroidLng(lahanProvider),
    };
  }

  // ===== DEBUG HELPERS =====
  void debugPrintLahan(LahanProvider lahanProvider) {
    final currentLahan = lahanProvider.getLahanById(idLahan);
    
    print('=== DETAIL LAHAN BUILD DEBUG ===');
    print('IdLahan: $idLahan');
    print('CurrentLahan: $currentLahan');
    print('CurrentLahan keys: ${currentLahan?.keys.toList()}');
    
    if (currentLahan != null) {
      print('Nama lahan: ${currentLahan['nama_lahan']}');
      print('Luas lahan: ${currentLahan['luas_lahan']}');
      print('Satuan luas: ${currentLahan['satuan_luas']}');
      print('Koordinat: ${currentLahan['koordinat']}');
      print('Centroid lat: ${currentLahan['centroid_lat']}');
      print('Centroid lng: ${currentLahan['centroid_lng']}');

      // Debug semua field yang ada
      currentLahan.forEach((key, value) {
        print('Field $key: $value (${value.runtimeType})');
      });
    }
    print('================================');
  }

  // ===== PRIVATE HELPER METHODS =====
  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

  Future<bool?> _showDeleteConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: const Text(
            'Apakah Anda yakin ingin menghapus laporan ini? '
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
  }
}