import 'package:flutter/material.dart';

class DetailTambahLahan extends StatefulWidget {
  const DetailTambahLahan({super.key});

  @override
  State<DetailTambahLahan> createState() => _DetailTambahLahanState();
}

class _DetailTambahLahanState extends State<DetailTambahLahan> {
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
          "Tambah Lahan",
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
