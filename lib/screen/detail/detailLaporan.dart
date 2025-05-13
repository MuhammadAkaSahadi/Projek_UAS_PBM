import 'package:flutter/material.dart';
import 'package:projek_uas/screen/detail/DetailLaporan/catatanTambahan.dart';
import 'package:projek_uas/screen/detail/DetailLaporan/dataMusimTanam.dart';
import 'package:projek_uas/screen/detail/DetailLaporan/hasilPanen.dart';
import 'package:projek_uas/screen/detail/DetailLaporan/inputProduksi.dart';
import 'package:projek_uas/screen/detail/DetailLaporan/kegiatanPendampingan.dart';
import 'package:projek_uas/screen/detail/DetailLaporan/kendalaDiLapangan.dart';

class DetailLaporan extends StatefulWidget {
  const DetailLaporan({super.key});

  @override
  State<DetailLaporan> createState() => _DetailLaporanState();
}

class _DetailLaporanState extends State<DetailLaporan> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final TextEditingController _tanggalTanamController = TextEditingController();
  final TextEditingController _jenisTanamanController = TextEditingController();
  final TextEditingController _luasLahanController = TextEditingController();
  final TextEditingController _jumlahPupukController = TextEditingController();
  final TextEditingController _jumlahPestisidaController =
      TextEditingController();
  final TextEditingController _teknikPengolahanController =
      TextEditingController();
  final TextEditingController _tanggalKunjunganController =
      TextEditingController();
  final TextEditingController _materiPenyuluhanController =
      TextEditingController();
  final TextEditingController _kritikDanSaranController =
      TextEditingController();
  final TextEditingController _deskripsiKendalaController = TextEditingController();
  final TextEditingController _tanggalPanenController = TextEditingController();
  final TextEditingController _satuanPanenController = TextEditingController();
  final TextEditingController _kualitasHasilController = TextEditingController();
  final TextEditingController _deskripsiCatatanController = TextEditingController();


  // Dropdown values
  String satuanLuas = 'Hektar';
  String sumberBenih = 'Mandiri';
  String satuanPupuk = 'Kg';
  String satuanPestisida = 'L';
  String satuanPanen = 'Ton';
  String kualitasHasil = 'Bagus';

  // Dropdown options
  final List<String> satuanLuasOptions = ['Hektar', 'Acre', 'm²'];
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F9),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "Tambahkan Laporan",
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Gambar
            Column(
              children: const [
                Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 80,
                  color: Colors.black54,
                ),
                SizedBox(height: 8),
                Text(
                  'Tambahkan Gambar',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Data Musim Tanam
            DataMusimTanamSection(
              tanggalTanamController: _tanggalTanamController,
              jenisTanamanController: _jenisTanamanController,
              luasLahanController: _luasLahanController,
              satuanLuas: satuanLuas,
              sumberBenih: sumberBenih,
              satuanLuasOptions: satuanLuasOptions,
              sumberBenihOptions: sumberBenihOptions,
              onSatuanLuasChanged: (val) {
                if (val != null) setState(() => satuanLuas = val);
              },
              onSumberBenihChanged: (val) {
                if (val != null) setState(() => sumberBenih = val);
              },
            ),

            // Input Produksi
            InputProduksiSection(
              jenisTanamanController: _jenisTanamanController,
              jumlahPupukController: _jumlahPupukController,
              jumlahPestisidaController: _jumlahPestisidaController,
              teknikPengolahanController: _teknikPengolahanController,
              satuanPupuk: satuanPupuk,
              satuanPestisida: satuanPestisida,
              satuanPupukOptions: satuanPupukOptions,
              satuanPestisidaOptions: satuanPestisidaOptions,
              onSatuanPupukChanged: (val) {
                if (val != null) setState(() => satuanPupuk = val);
              },
              onSatuanPestisidaChanged: (val) {
                if (val != null) setState(() => satuanPestisida = val);
              },
            ),
            const SizedBox(height: 24),

            // Kegiatan Pendampingan
            KegiatanPendampinganSection(
              tanggalKunjunganController: _tanggalKunjunganController,
              materiPenyuluhanController: _materiPenyuluhanController,
              kritikDanSaranController: _kritikDanSaranController,
            ),

            // Kendala di Lapngan
            KendalaDiLapanganSection(
              deskripsiKendalaController: _deskripsiKendalaController
            ),

            // Hasil Panen
            HasilPanenSection(
              tanggalPanenController: _tanggalPanenController,
              satuanPanenController: _satuanPanenController,
              kualitasHasilController: _kualitasHasilController,
              satuanPanen: satuanPanen,
              kualitasHasil: kualitasHasil,
              satuanPanenOptions: satuanPanenOptions,
              kualitasHasilOptions: kualitasHasilOptions,
              onSatuanPanenChanged: (val) {
                if (val != null) setState(() => satuanPanen = val);
              },
              onKualitasHasilChanged: (val) {
                if (val != null) setState(() => kualitasHasil = val);
              },
            ),

            // Catatan Tambahan
            CatatanTambahanSection(
              deskripsiCatatanController: _deskripsiCatatanController
            ),

            const SizedBox(height: 24),

            // Tombol Simpan
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // TODO: Simpan data laporan
                  }
                },
                child: const Text(
                  'Simpan Laporan',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
