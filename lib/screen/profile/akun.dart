import 'package:flutter/material.dart';
import 'package:projek_uas/screen/profile/bantuan_screen.dart';
import 'package:projek_uas/screen/profile/masukan_screen.dart';
import 'package:projek_uas/screen/profile/pengaturan_screen.dart';
import 'package:projek_uas/screen/profile/tentang_screen.dart';
import '../../../widgets/profile_menu_item.dart';


class Akun extends StatelessWidget {
  const Akun({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              "Profil",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 10),
            const Text(
              "Anggun Mellanie",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 30),
            ProfileMenuItem(
              icon: Icons.info,
              label: "Tentang",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TentangScreen()),
                );
              },
            ),
            ProfileMenuItem(
              icon: Icons.settings,
              label: "Pengaturan",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PengaturanScreen()),
                );
              },
            ),
            ProfileMenuItem(
              icon: Icons.help,
              label: "Bantuan",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BantuanScreen()),
                );
              },
            ),
            ProfileMenuItem(
              icon: Icons.feedback,
              label: "Masukan",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MasukanScreen()),
                );
              },
            ),
            ProfileMenuItem(
              icon: Icons.logout,
              label: "Keluar",
              onTap: () {
                // Tambahkan logika logout di sini, misal: clear session, redirect login
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Keluar"),
                    content: const Text("Apakah Anda yakin ingin keluar?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Batal"),
                      ),
                      TextButton(
                        onPressed: () {
                          // Contoh aksi logout
                          Navigator.pop(context); // tutup dialog
                          Navigator.pop(context); // kembali ke layar sebelumnya
                        },
                        child: const Text("Keluar"),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
