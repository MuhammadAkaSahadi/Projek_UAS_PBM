// lib/providers/laporan_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class LaporanProvider with ChangeNotifier {
  final Map<int, Map<String, dynamic>> _laporanCache = {};
  bool _isLoading = false;
  String? _error;

  static const String baseUrl = 'http://192.168.43.143:5042/api/Laporan';

  bool get isLoading => _isLoading;
  String? get error => _error;

  Map<String, dynamic>? getLaporan(int idLahan) {
    return _laporanCache[idLahan];
  }

  // ✅ FIXED: Tambahkan token parameter dan Authorization header
  Future<void> fetchLaporan(int idLahan, String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/laporan/$idLahan'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',  // ✅ Tambahkan Authorization header
        },
      );

      print('=== FETCH LAPORAN DEBUG ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('Token: ${token.substring(0, 20)}...'); // Log partial token untuk debug

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is Map<String, dynamic>) {
          final normalizedData = _normalizeResponseData(data);
          _laporanCache[idLahan] = normalizedData;
          _error = null;
          print('Laporan berhasil dimuat untuk ID Lahan: $idLahan');
        } else {
          _error = 'Format data tidak valid';
          print('Error: Format data tidak valid - $data');
        }
      } else if (response.statusCode == 404) {
        _laporanCache[idLahan] = _createEmptyLaporanStructure();
        _error = null;
        print('Laporan tidak ditemukan untuk ID Lahan: $idLahan, membuat struktur kosong');
      } else if (response.statusCode == 401) {
        _error = 'Token tidak valid atau sudah kadaluarsa';
        print('Error 401: Unauthorized - Token issue');
      } else if (response.statusCode == 403) {
        _error = 'Akses ditolak - Anda tidak memiliki izin untuk melihat laporan ini';
        print('Error 403: Forbidden - Access denied');
      } else {
        _error = 'Gagal mengambil laporan: ${response.statusCode} - ${response.body}';
        print('Error: $_error');
      }
    } catch (e) {
      _error = 'Kesalahan saat mengambil laporan: $e';
      _laporanCache[idLahan] = _createEmptyLaporanStructure();
      print('Exception: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ✅ FIXED: Update method untuk refresh data dengan token
  Future<void> refreshLaporan(int idLahan, String token) async {
    _laporanCache.remove(idLahan);
    await fetchLaporan(idLahan, token);
  }

  // ✅ FIXED: Update loadLaporanForEdit dengan token parameter
  Future<bool> loadLaporanForEdit(int idLahan, String token) async {
    try {
      if (!_laporanCache.containsKey(idLahan)) {
        await fetchLaporan(idLahan, token);
      }

      final laporan = _laporanCache[idLahan];
      return laporan != null;
    } catch (e) {
      _error = 'Gagal memuat data laporan: $e';
      return false;
    }
  }

  Map<String, dynamic> _normalizeResponseData(Map<String, dynamic> data) {
    final normalized = <String, dynamic>{};

    if (data.containsKey('laporan_lahan')) {
      normalized['laporan_lahan'] = data['laporan_lahan'];
    }

    // Mapping sesuai dengan response API yang sebenarnya
    final apiToAppMapping = {
      'musimTanam': 'musimTanam',
      'inputProduksi': 'inputProduksi',
      'pendampingan': 'pendampingan',
      'kendala': 'kendala',
      'hasilPanen': 'hasilPanen',
      'catatan': 'catatan',
      'gambar': 'gambar',
    };

    for (final entry in apiToAppMapping.entries) {
      final apiKey = entry.key;
      final appKey = entry.value;

      if (data.containsKey(apiKey)) {
        final sectionData = data[apiKey];

        if (sectionData is List) {
          normalized[appKey] = List.from(sectionData);
        } else if (sectionData is Map && sectionData.isNotEmpty) {
          normalized[appKey] = [Map.from(sectionData)];
        } else {
          normalized[appKey] = [];
        }
      } else {
        normalized[appKey] = [];
      }
    }

    return normalized;
  }

  Map<String, dynamic> _createEmptyLaporanStructure() {
    return {
      'laporan_lahan': null,
      'musimTanam': [],
      'inputProduksi': [],
      'pendampingan': [],
      'kendala': [],
      'hasilPanen': [],
      'catatan': [],
      'gambar': [],
    };
  }

  bool isLaporanEmpty(int idLahan) {
    final laporan = _laporanCache[idLahan];

    if (laporan == null) return true;

    final sectionsToCheck = [
      'musimTanam',
      'hasilPanen',
      'inputProduksi',
      'pendampingan',
      'kendala',
      'catatan',
      'gambar',
    ];

    for (final section in sectionsToCheck) {
      final sectionData = laporan[section];

      if (sectionData is List && sectionData.isNotEmpty) {
        return false;
      } else if (sectionData is Map && sectionData.isNotEmpty) {
        return false;
      }
    }

    return true;
  }

  bool hasSectionData(int idLahan, String sectionName) {
    final laporan = _laporanCache[idLahan];
    if (laporan == null) return false;

    final section = laporan[sectionName];
    if (section is List) {
      return section.isNotEmpty;
    } else if (section is Map) {
      return section.isNotEmpty;
    }
    return false;
  }

  List<dynamic> getSectionData(int idLahan, String sectionName) {
    final laporan = _laporanCache[idLahan];
    if (laporan == null) return [];

    final section = laporan[sectionName];
    if (section is List) {
      return section;
    }
    return [];
  }

  Map<String, dynamic>? getLaporanLahanInfo(int idLahan) {
    final laporan = _laporanCache[idLahan];
    if (laporan == null) return null;

    return laporan['laporan_lahan'] as Map<String, dynamic>?;
  }

  List<Map<String, dynamic>> _formatGambarData(List<String> imageUrls) {
    return imageUrls
        .where((url) => url.isNotEmpty)
        .map((url) => {'Url_Gambar': url})
        .toList();
  }

  bool _isValidImageUrl(String url) {
    if (url.isEmpty) return false;

    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasAbsolutePath) return false;

    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'];
    final lowerUrl = url.toLowerCase();

    return imageExtensions.any((ext) => lowerUrl.contains(ext)) ||
        url.startsWith('http://') ||
        url.startsWith('https://');
  }

  // Method untuk validasi data sesuai dengan API requirements
  bool _validateLaporanData(Map<String, dynamic> laporanData) {
    // Validasi Musim Tanam
    final musimTanam = laporanData['musimTanam'];
    if (musimTanam != null) {
      if (musimTanam['jenisTanaman'] == null ||
          (musimTanam['jenisTanaman'] as String).trim().isEmpty) {
        _error = 'Jenis tanaman tidak boleh kosong';
        return false;
      }
      if (musimTanam['sumberBenih'] == null ||
          (musimTanam['sumberBenih'] as String).trim().isEmpty) {
        _error = 'Sumber benih tidak boleh kosong';
        return false;
      }
    }

    // Validasi Input Produksi
    final inputProduksi = laporanData['inputProduksi'];
    if (inputProduksi != null) {
      if (inputProduksi['jenisPupuk'] == null ||
          (inputProduksi['jenisPupuk'] as String).trim().isEmpty) {
        _error = 'Jenis pupuk tidak boleh kosong';
        return false;
      }
      if (inputProduksi['satuanPupuk'] == null ||
          (inputProduksi['satuanPupuk'] as String).trim().isEmpty) {
        _error = 'Satuan pupuk tidak boleh kosong';
        return false;
      }
      if (inputProduksi['satuanPestisida'] == null ||
          (inputProduksi['satuanPestisida'] as String).trim().isEmpty) {
        _error = 'Satuan pestisida tidak boleh kosong';
        return false;
      }

      final jumlahPupuk =
          double.tryParse(inputProduksi['jumlahPupuk']?.toString() ?? '0') ??
          0.0;
      final jumlahPestisida =
          double.tryParse(
            inputProduksi['jumlahPestisida']?.toString() ?? '0',
          ) ??
          0.0;

      if (jumlahPupuk < 0) {
        _error = 'Jumlah pupuk tidak boleh negatif';
        return false;
      }
      if (jumlahPestisida < 0) {
        _error = 'Jumlah pestisida tidak boleh negatif';
        return false;
      }
    }

    // Validasi Pendampingan
    final pendampingan = laporanData['pendampingan'];
    if (pendampingan != null) {
      if (pendampingan['materiPenyuluhan'] == null ||
          (pendampingan['materiPenyuluhan'] as String).trim().isEmpty) {
        _error = 'Materi penyuluhan tidak boleh kosong';
        return false;
      }
    }

    // Validasi Kendala
    final kendala = laporanData['kendala'];
    if (kendala != null) {
      if (kendala['deskripsi'] == null ||
          (kendala['deskripsi'] as String).trim().isEmpty) {
        _error = 'Deskripsi kendala tidak boleh kosong';
        return false;
      }
    }

    // Validasi Hasil Panen
    final hasilPanen = laporanData['hasilPanen'];
    if (hasilPanen != null) {
      final totalPanen =
          double.tryParse(hasilPanen['totalPanen']?.toString() ?? '0') ?? 0.0;
      if (totalPanen <= 0) {
        _error = 'Total hasil panen harus lebih dari 0';
        return false;
      }
    }

    // Validasi Catatan
    final catatan = laporanData['catatan'];
    if (catatan != null) {
      if (catatan['deskripsi'] == null ||
          (catatan['deskripsi'] as String).trim().isEmpty) {
        _error = 'Deskripsi catatan tidak boleh kosong';
        return false;
      }
    }

    return true;
  }

  Future<bool> saveLaporan({
    required String token,
    required int idLahan,
    required Map<String, dynamic> laporanData,
    List<String>? imageUrls,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Validasi data input
      if (!_validateLaporanData(laporanData)) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Langkah 1: Buat laporan lahan terlebih dahulu
      final laporanLahanResponse = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'Id_Lahan': idLahan,
          'Tanggal_Laporan': DateTime.now().toIso8601String(),
        }),
      );

      if (laporanLahanResponse.statusCode != 200) {
        throw Exception(
          'Gagal membuat laporan lahan: ${laporanLahanResponse.body}',
        );
      }

      final laporanLahanResult = jsonDecode(laporanLahanResponse.body);
      final idLaporanLahan = laporanLahanResult['id_laporan_lahan'];

      // Langkah 2: Buat request body untuk laporan lengkap
      final requestBody = <String, dynamic>{'Id_Laporan_Lahan': idLaporanLahan};

      // Musim Tanam - sesuai dengan model API
      final musimTanam = laporanData['musimTanam'];
      if (musimTanam != null && musimTanam['jenisTanaman'] != null) {
        requestBody['MusimTanam'] = {
          'Tanggal_Mulai_Tanam':
              musimTanam['tanggalTanam'] ?? DateTime.now().toIso8601String(),
          'Jenis_Tanaman': musimTanam['jenisTanaman'],
          'Sumber_Benih': musimTanam['sumberBenih'] ?? '',
        };
      }

      // Input Produksi - sesuai dengan model API
      final inputProduksi = laporanData['inputProduksi'];
      if (inputProduksi != null && inputProduksi['satuanPupuk'] != null) {
        requestBody['InputProduksi'] = {
          'Jenis_Pupuk': inputProduksi['jenisPupuk'] ?? 'Tidak Diketahui',
          'Jumlah_Pupuk':
              double.tryParse(
                inputProduksi['jumlahPupuk']?.toString() ?? '0',
              ) ??
              0.0,
          'Satuan_Pupuk': inputProduksi['satuanPupuk'],
          'Jumlah_Pestisida':
              double.tryParse(
                inputProduksi['jumlahPestisida']?.toString() ?? '0',
              ) ??
              0.0,
          'Satuan_Pestisida': inputProduksi['satuanPestisida'] ?? 'L',
          'Teknik_Pengolahan_Tanah': inputProduksi['teknikPengolahan'] ?? '',
        };
      }

      // Pendampingan - sesuai dengan model API
      final pendampingan = laporanData['pendampingan'];
      if (pendampingan != null && pendampingan['materiPenyuluhan'] != null) {
        requestBody['Pendampingan'] = {
          'Tanggal_Kunjungan':
              pendampingan['tanggalKunjungan'] ??
              DateTime.now().toIso8601String(),
          'Materi_Penyuluhan': pendampingan['materiPenyuluhan'],
          'Kritik_Dan_Saran': pendampingan['kritikSaran'] ?? '',
        };
      }

      // Kendala - sesuai dengan model API
      final kendala = laporanData['kendala'];
      if (kendala != null &&
          kendala['deskripsi'] != null &&
          kendala['deskripsi'].toString().trim().isNotEmpty) {
        requestBody['Kendala'] = {'Deskripsi': kendala['deskripsi']};
      }

      // Hasil Panen - sesuai dengan model API
      final hasilPanen = laporanData['hasilPanen'];
      if (hasilPanen != null && hasilPanen['totalPanen'] != null) {
        requestBody['HasilPanen'] = {
          'Tanggal_Panen':
              hasilPanen['tanggalPanen'] ?? DateTime.now().toIso8601String(),
          'Total_Hasil_Panen':
              double.tryParse(hasilPanen['totalPanen']?.toString() ?? '0') ??
              0.0,
          'Satuan_Panen': hasilPanen['satuanPanen'] ?? 'Kg',
          'Kualitas': hasilPanen['kualitas'] ?? '',
        };
      }

      // Catatan - sesuai dengan model API
      final catatan = laporanData['catatan'];
      if (catatan != null &&
          catatan['deskripsi'] != null &&
          catatan['deskripsi'].toString().trim().isNotEmpty) {
        requestBody['Catatan'] = {'Deskripsi': catatan['deskripsi']};
      }

      // Gambar - sesuai dengan model API
      if (imageUrls != null && imageUrls.isNotEmpty) {
        final validUrls =
            imageUrls.where((url) => _isValidImageUrl(url)).toList();
        if (validUrls.isNotEmpty) {
          requestBody['Gambar'] = _formatGambarData(validUrls);
        }
      }

      // Langkah 3: Kirim data laporan lengkap
      final response = await http.post(
        Uri.parse('$baseUrl/laporan'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Refresh cache setelah berhasil menyimpan
        _laporanCache.remove(idLahan);
        await Future.delayed(const Duration(milliseconds: 500));
        await fetchLaporan(idLahan, token); // ✅ Pass token here

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        throw Exception("Gagal menyimpan laporan lengkap: ${response.body}");
      }
    } catch (e) {
      _error = 'Gagal menyimpan laporan: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateLaporan({
    required String token,
    required int idLaporanLahan,
    required Map<String, dynamic> laporanData,
    List<String>? imageUrls,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Validasi data input
      if (!_validateLaporanData(laporanData)) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Buat request body sesuai dengan UpdateLaboranRequest model API
      final requestBody = <String, dynamic>{};

      // Musim Tanam
      final musimTanam = laporanData['musimTanam'];
      if (musimTanam != null) {
        requestBody['MusimTanam'] = {
          'Tanggal_Mulai_Tanam': musimTanam['tanggalTanam'],
          'Jenis_Tanaman': musimTanam['jenisTanaman'],
          'Sumber_Benih': musimTanam['sumberBenih'],
        };
      }

      // Input Produksi
      final inputProduksi = laporanData['inputProduksi'];
      if (inputProduksi != null) {
        requestBody['InputProduksi'] = {
          'Jenis_Pupuk': inputProduksi['jenisPupuk'] ?? 'Tidak Diketahui',
          'Jumlah_Pupuk':
              double.tryParse(
                inputProduksi['jumlahPupuk']?.toString() ?? '0',
              ) ??
              0.0,
          'Satuan_Pupuk': inputProduksi['satuanPupuk'],
          'Jumlah_Pestisida':
              double.tryParse(
                inputProduksi['jumlahPestisida']?.toString() ?? '0',
              ) ??
              0.0,
          'Satuan_Pestisida': inputProduksi['satuanPestisida'],
          'Teknik_Pengolahan_Tanah': inputProduksi['teknikPengolahan'],
        };
      }

      // Kegiatan Pendampingan
      final pendampingan = laporanData['pendampingan'];
      if (pendampingan != null) {
        requestBody['KegiatanPendampingan'] = {
          'Tanggal_Kunjungan': pendampingan['tanggalKunjungan'],
          'Materi_Penyuluhan': pendampingan['materiPenyuluhan'],
          'Kritik_Dan_Saran': pendampingan['kritikSaran'],
        };
      }

      // Kendala - dengan nama field yang benar sesuai API
      final kendala = laporanData['kendala'];
      if (kendala != null) {
        requestBody['KendalaDiLapngan'] = {'Deskripsi': kendala['deskripsi']};
      }

      // Hasil Panen
      final hasilPanen = laporanData['hasilPanen'];
      if (hasilPanen != null) {
        requestBody['HasilPanen'] = {
          'Tanggal_Panen': hasilPanen['tanggalPanen'],
          'Total_Hasil_Panen':
              double.tryParse(hasilPanen['totalPanen']?.toString() ?? '0') ??
              0.0,
          'Satuan_Panen': hasilPanen['satuanPanen'],
          'Kualitas': hasilPanen['kualitas'],
        };
      }

      // Catatan Tambahan
      final catatan = laporanData['catatan'];
      if (catatan != null) {
        requestBody['CatatanTambahan'] = {'Deskripsi': catatan['deskripsi']};
      }

      // Note: Gambar tidak ada dalam update endpoint, mungkin harus dihandle terpisah

      final response = await http.put(
        Uri.parse('$baseUrl/laporan/$idLaporanLahan'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        // Cari idLahan berdasarkan idLaporanLahan
        int? idLahan;
        _laporanCache.forEach((key, value) {
          if (value['laporan_lahan']?['id_laporan_lahan'] == idLaporanLahan) {
            idLahan = key;
          }
        });

        // Refresh cache
        if (idLahan != null) {
          _laporanCache.remove(idLahan);
          await Future.delayed(const Duration(milliseconds: 500));
          await fetchLaporan(idLahan!, token); // ✅ Pass token here
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        throw Exception("Gagal mengupdate laporan: ${response.body}");
      }
    } catch (e) {
      _error = 'Gagal mengupdate laporan: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  int? getLaporanLahanId(int idLahan) {
    final laporan = _laporanCache[idLahan];
    return laporan?['laporan_lahan']?['id_laporan_lahan'];
  }

  List<String> getImageUrls(int idLahan) {
    final gambarList = getSectionData(idLahan, 'gambar');
    return gambarList
        .map(
          (item) =>
              item['url_gambar'] as String? ??
              item['Url_Gambar'] as String? ??
              '',
        )
        .where((url) => url.isNotEmpty)
        .toList();
  }

  void addImageUrl(int idLahan, String imageUrl) {
    if (!_isValidImageUrl(imageUrl)) return;

    final laporan = _laporanCache[idLahan];
    if (laporan != null) {
      final gambarList = laporan['gambar'] as List<dynamic>? ?? [];
      gambarList.add({'Url_Gambar': imageUrl});
      laporan['gambar'] = gambarList;
      notifyListeners();
    }
  }

  void removeImageUrl(int idLahan, String imageUrl) {
    final laporan = _laporanCache[idLahan];
    if (laporan != null) {
      final gambarList = laporan['gambar'] as List<dynamic>? ?? [];
      gambarList.removeWhere(
        (item) =>
            item['url_gambar'] == imageUrl || item['Url_Gambar'] == imageUrl,
      );
      laporan['gambar'] = gambarList;
      notifyListeners();
    }
  }

  Future<bool> deleteLaporan(String token, int idLaporanLahan) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/laporan/$idLaporanLahan'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // Hapus dari cache
        _laporanCache.removeWhere(
          (key, value) =>
              value['laporan_lahan']?['id_laporan_lahan'] == idLaporanLahan,
        );

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        throw Exception("Gagal menghapus laporan: ${response.body}");
      }
    } catch (e) {
      _error = 'Gagal menghapus laporan: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearLaporanCache(int idLahan) {
    _laporanCache.remove(idLahan);
    notifyListeners();
  }

  void clearAllCache() {
    _laporanCache.clear();
    notifyListeners();
  }

  // Helper method untuk mendapatkan data dari cache dengan format yang konsisten
  Map<String, dynamic>? getFormattedLaporanData(int idLahan) {
    final laporan = _laporanCache[idLahan];
    if (laporan == null) return null;

    return {
      'laporan_lahan': laporan['laporan_lahan'],
      'musimTanam': _formatSectionForForm(laporan['musimTanam']),
      'inputProduksi': _formatSectionForForm(laporan['inputProduksi']),
      'pendampingan': _formatSectionForForm(laporan['pendampingan']),
      'kendala': _formatSectionForForm(laporan['kendala']),
      'hasilPanen': _formatSectionForForm(laporan['hasilPanen']),
      'catatan': _formatSectionForForm(laporan['catatan']),
      'gambar': laporan['gambar'] ?? [],
    };
  }

  dynamic _formatSectionForForm(dynamic section) {
    if (section is List && section.isNotEmpty) {
      return section.first;
    } else if (section is Map && section.isNotEmpty) {
      return section;
    }
    return null;
  }
}