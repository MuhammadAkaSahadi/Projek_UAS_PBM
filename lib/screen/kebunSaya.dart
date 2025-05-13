import 'package:flutter/material.dart';
import 'package:projek_uas/pages/add_mapping.dart';
import 'package:projek_uas/screen/detail/detailLahan.dart';

class MappingPage extends StatelessWidget {
  const MappingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> lahanList = [
      {
        "title": "Paleran, Jember Jawa Timur",
        "image": "assets/images/lahan1.png",
        "size": "16ha",
      },
      {
        "title": "Sumbersari, Jember Jawa Timur",
        "image": "assets/images/lahan2.png",
        "size": "16ha",
      },
      {
        "title": "Sidomulyo, Jember Jawa Timur",
        "image": "assets/images/lahan3.png",
        "size": "16ha",
      },
    ];

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
      body: ListView.builder(
        itemCount: lahanList.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final lahan = lahanList[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(128, 128, 128, 0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(8),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  lahan["image"]!,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              ),
              title: Text(
                lahan["title"]!,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                lahan["size"]!,
                style: const TextStyle(fontSize: 13),
              ),
              trailing: const Icon(Icons.open_in_new, size: 22),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DetailLahan()),
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
            MaterialPageRoute(builder: (context) => const AddMappingPage()),
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
