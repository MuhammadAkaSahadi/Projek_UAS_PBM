import 'package:flutter/material.dart';

class DetailPanen extends StatefulWidget {
  const DetailPanen({super.key});

  @override
  State<DetailPanen> createState() => _DetailPanenState();
}

class _DetailPanenState extends State<DetailPanen> {
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
          "Konfirmasi Panen",
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
