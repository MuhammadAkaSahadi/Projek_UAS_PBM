import 'package:flutter/material.dart';
import 'package:projek_uas/pages/add_mapping.dart';

class DetailTambahLahan extends StatefulWidget {
  const DetailTambahLahan({super.key});

  @override
  State<DetailTambahLahan> createState() => _DetailTambahLahanState();
}

class _DetailTambahLahanState extends State<DetailTambahLahan> {
  final TextEditingController _namaLahanController = TextEditingController();
  final TextEditingController _ukuranLahanController = TextEditingController();

  String? _selectedLokasi;
  String _selectedSatuan = 'Hektar';

  final List<String> _lokasiList = [
    'Jember',
    'Bondowoso',
    'Lumajang',
    'Probolinggo',
    'Banyuwangi',
  ];

  final List<String> _satuanList = ['Hektar', 'm2'];

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey),
      ),
    );
  }

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
          "Detail lahan",
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Informasi lahan",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Nama Lahan
            TextField(
              controller: _namaLahanController,
              decoration: _inputDecoration("Nama lahan"),
            ),
            const SizedBox(height: 16),

            // Lokasi Lahan
            DropdownButtonFormField<String>(
              value: _selectedLokasi,
              onChanged: (value) => setState(() => _selectedLokasi = value),
              items:
                  _lokasiList.map((lokasi) {
                    return DropdownMenuItem(value: lokasi, child: Text(lokasi));
                  }).toList(),
              decoration: _inputDecoration("Lokasi lahan"),
            ),
            const SizedBox(height: 16),

            // Ukuran lahan + satuan
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _ukuranLahanController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration("Ukuran lahan"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: _selectedSatuan,
                    onChanged:
                        (value) => setState(() => _selectedSatuan = value!),
                    items:
                        _satuanList.map((satuan) {
                          return DropdownMenuItem(
                            value: satuan,
                            child: Text(satuan),
                          );
                        }).toList(),
                    decoration: _inputDecoration("Satuan"),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 80,
            ), // untuk memberi ruang dari bottom button
          ],
        ),
      ),

      // Tombol bawah
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddMappingPage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Mulai pemetaan',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
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
