import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:projek_uas/screen/detail/detailLahan.dart';
import 'package:projek_uas/screen/detail/detail_add_lahan.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';

class MappingPage extends StatefulWidget {
  final int? idLahan;
  const MappingPage({super.key, this.idLahan});

  @override
  State<MappingPage> createState() => _MappingPageState();
}

class _MappingPageState extends State<MappingPage> {
  List<Map<String, dynamic>> lahanList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchLahan();
  }

  Future<void> fetchLahan() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || JwtDecoder.isExpired(token)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Token tidak valid")));
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://192.168.43.143:5042/api/Laporan/lahan'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          lahanList = List<Map<String, dynamic>>.from(data);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil data: ${response.body}')),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Kesalahan saat mengambil data: $e")),
      );
    }
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
          "Daftar Lahan",
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : lahanList.isEmpty
              ? const Center(child: Text("Belum ada lahan ditambahkan."))
              : ListView.builder(
                itemCount: lahanList.length,
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  final lahan = lahanList[index];
                  final title =
                      '${lahan['nama_lahan'] ?? 'Nama Tidak Ada'}, ${lahan['koordinat'] ?? 'Koordinat Tidak Ada'}';
                  final desc = '${lahan['luas_lahan']} ${lahan['satuan_luas']}';
                  final imageUrl = lahan['gambar'];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromRGBO(128, 128, 128, 0.1),
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(8),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child:
                            imageUrl != null && imageUrl != ""
                                ? Image.network(
                                  imageUrl,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) =>
                                          const Icon(
                                            Icons.broken_image,
                                            size: 40,
                                            color: Colors.grey,
                                          ),
                                )
                                : const Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 40,
                                  color: Colors.black54,
                                ),
                      ),
                      title: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        desc,
                        style: const TextStyle(fontSize: 13),
                      ),
                      trailing: const Icon(Icons.open_in_new, size: 22),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailLahan(),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DetailTambahLahan()),
          );
        },
        backgroundColor: const Color(0xFFC9E5BA),
        shape: const CircleBorder(),
        elevation: 0,
        highlightElevation: 0,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}
