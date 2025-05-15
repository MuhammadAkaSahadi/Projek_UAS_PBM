import 'package:flutter/material.dart';

class DetailTips extends StatelessWidget {
  const DetailTips({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Artikel',
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar artikel
            Image.asset(
              'assets/images/GambarArtikel1.webp',
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Judul (h1)
                  const Text(
                    'Sudah Dipupuk, Tapi Tanaman Masih Lambat Tumbuh?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Tanggal (h3 + icon)
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Colors.black.withOpacity(0.6)),
                      const SizedBox(width: 4),
                      Text(
                        '08 Mei 2025',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Deskripsi lengkap (h2)
                  Text(
                    '''Hai Sahabat Yara,

Merawat tanaman itu bukan hanya soal hama dan penyakit saja, loh!

Ada faktor lain yang sering terlupakan tapi diam-diam bikin tanaman lambat tumbuh. Salah satu penyebab utamanya: pH tanah yang tidak sesuai dengan kebutuhan tanaman.

Tapi, pH tanah juga bukan satu-satunya! Masih ada beberapa faktor lain yang harus Sahabat Yara perhatikan agar pertumbuhan tanaman tetap optimal.''',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black.withOpacity(0.8),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
