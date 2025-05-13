import 'package:flutter/material.dart';
import 'package:projek_uas/screen/detail/detailLaporan.dart';

class DetailLahan extends StatefulWidget {
  const DetailLahan({super.key});

  @override
  State<DetailLahan> createState() => _DetailLahanState();
}

class _DetailLahanState extends State<DetailLahan> {
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
          "Nama Lahan",
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          Center(
            child: Image.asset(
              "assets/images/lahan1.png",
              width: 382,
              height: 200,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromRGBO(76, 175, 80, 1),
              padding: const EdgeInsets.symmetric(
                vertical: 14,
              ), // Tambahkan padding vertikal
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  4,
                ), // Sudut tidak terlalu lancip (seperti scaffold)
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DetailLaporan()),
              );
            },
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.center, // Posisikan isi ke tengah
              mainAxisSize: MainAxisSize.max,
              children: const [
                Icon(Icons.add, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Tambahkan Lahan',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
