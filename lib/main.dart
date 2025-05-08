import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:projek_uas/screen/beranda.dart';
import 'package:projek_uas/screen/kebunSaya.dart';
import 'package:projek_uas/screen/hasilLaporan.dart';
import 'package:projek_uas/screen/akun.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pocket Farm',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Pocket Farm'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  // Daftar widget halaman
  final List<Widget> _pages = [
    Beranda(),
    KebunSaya(),
    HasilLaporan(),
    Akun()
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color.fromARGB(255, 0, 0, 0),
        items: [
          BottomNavigationBarItem(
            icon: Image.asset(
              _selectedIndex == 0
                  ? 'assets/Beranda_hitam.png'
                  : 'assets/Beranda.png',
              width: 20,
              height: 20,
            ),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              _selectedIndex == 1
                  ? 'assets/Kebun Saya_hitam.png'
                  : 'assets/Kebun Saya.png',
              width: 20,
              height: 20,
            ),
            label: 'Kebun Saya',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              _selectedIndex == 2
                  ? 'assets/Hasil Laporan_hitam.png'
                  : 'assets/Hasil Laporan.png',
              width: 20,
              height: 20,
            ),
            label: 'Hasil Laporan',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              _selectedIndex == 3
                  ? 'assets/Akun_hitam.png'
                  : 'assets/Akun.png',
              width: 20,
              height: 20,
            ),
            label: 'Akun',
          ),
        ],
      ),
    );
  }
}
