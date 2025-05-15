import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:projek_uas/screen/detail/detail_tips.dart';

class TipsPage extends StatelessWidget {
  const TipsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F9),
        title: const Text(
          "Tips",
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
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTipsCard(
            context: context,
            imageAsset: 'assets/images/GambarArtikel1.webp',
            date: '12 Mei 2025',
            title: 'Strategi Pemupukan Efektif Saat Musim Hujan',
            description:
                'Musim hujan bisa menjadi tantangan bagi pertumbuhan tanaman. Kelembapan tinggi dan curah hujan berlebih perlu strategi pemupukan khusus.',
          ),
          const SizedBox(height: 16),
          _buildTipsCard(
            context: context,
            imageAsset: 'assets/images/GambarArtikel2.jpg',
            date: '9 Mei 2025',
            title: 'Cara Menanam Bibit dengan Baik dan Benar',
            description:
                'Bibit yang ditanam dengan cara yang tepat akan menghasilkan tanaman yang sehat dan produktif. Simak panduan lengkapnya.',
          ),
          const SizedBox(height: 16),
          _buildTipsCard(
            context: context,
            imageAsset: 'assets/images/GambarArtikel3.webp',
            date: '6 Mei 2025',
            title: 'Mengenal Jenis Tanah untuk Pertanian Optimal',
            description:
                'Tidak semua tanah cocok untuk semua jenis tanaman. Pelajari bagaimana mengenali dan memperbaiki tanah untuk hasil panen terbaik.',
          ),
        ],
      ),
    );
  }

  Widget _buildTipsCard({
    required BuildContext context,
    required String imageAsset,
    required String date,
    required String title,
    required String description,
  }) {
    return Card(
      color: const Color(0xFFF9F9F9),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            imageAsset,
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.bottomRight,
                  child: IconButton(
                    icon: const Icon(
                      LucideIcons.arrowUpRight,
                      size: 20,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const DetailTips()),
                      );
                    },
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
