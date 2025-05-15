import 'package:flutter/material.dart';
import 'package:projek_uas/screen/detail/detail_add_lahan.dart';
import 'package:projek_uas/weather/cuacaBeranda.dart';

class Beranda extends StatefulWidget {
  const Beranda({super.key});

  @override
  _BerandaState createState() => _BerandaState();
}

class _BerandaState extends State<Beranda> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(247, 247, 247, 1),
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(247, 247, 247, 1),
        elevation: 0,
        title: Row(
          children: [
            Image.asset('assets/logo.png', height: 28),
            const SizedBox(width: 8),
            const Text(
              'PocketFarm',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          const CuacaBeranda(),
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
                MaterialPageRoute(builder: (context) => DetailTambahLahan()),
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

          // const Text(
          //   'Jadwal Hari Ini',
          //   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          // ),
          // const SizedBox(height: 12),
          // Card(
          //   color: Colors.white,
          //   elevation: 2,
          //   shape: RoundedRectangleBorder(
          //     borderRadius: BorderRadius.circular(12),
          //   ),
          //   child: Padding(
          //     padding: const EdgeInsets.all(16),
          //     child: Column(
          //       children: [
          //         Row(
          //           children: const [
          //             Expanded(
          //               child: Text(
          //                 'Sawah Sumbersari',
          //                 style: TextStyle(fontWeight: FontWeight.bold),
          //               ),
          //             ),
          //             Text(
          //               'Jember',
          //               style: TextStyle(fontWeight: FontWeight.bold),
          //             ),
          //           ],
          //         ),
          //         const SizedBox(height: 8),
          //         const Divider(),
          //         const SizedBox(height: 8),
          //         Row(
          //           children: [
          //             Image.asset(
          //               'assets/jadwal/watering.png',
          //               width: 25,
          //               height: 25,
          //             ),
          //             const SizedBox(width: 8),
          //             const Text(
          //               'Penyiraman',
          //               style: TextStyle(
          //                 fontSize: 13,
          //                 fontWeight: FontWeight.w500,
          //               ),
          //             ),
          //             const Spacer(),
          //             Image.asset(
          //               'assets/jadwal/clock.png',
          //               width: 14,
          //               height: 14,
          //             ),
          //             const SizedBox(width: 4),
          //             const Text('08:00', style: TextStyle(fontSize: 12)),
          //           ],
          //         ),
          //         const SizedBox(height: 16),
          //         Row(
          //           children: [
          //             Image.asset(
          //               'assets/jadwal/compost.png',
          //               width: 25,
          //               height: 25,
          //             ),
          //             const SizedBox(width: 8),
          //             const Text(
          //               'Pemupukan',
          //               style: TextStyle(
          //                 fontSize: 13,
          //                 fontWeight: FontWeight.w500,
          //               ),
          //             ),
          //             const Spacer(),
          //             Image.asset(
          //               'assets/jadwal/clock.png',
          //               width: 14,
          //               height: 14,
          //             ),
          //             const SizedBox(width: 4),
          //             const Text('08:00', style: TextStyle(fontSize: 12)),
          //           ],
          //         ),
          //         const SizedBox(height: 16),
          //         Row(
          //           children: [
          //             Image.asset(
          //               'assets/jadwal/shovel.png',
          //               width: 25,
          //               height: 25,
          //             ),
          //             const SizedBox(width: 8),
          //             const Text(
          //               'Penanaman',
          //               style: TextStyle(
          //                 fontSize: 13,
          //                 fontWeight: FontWeight.w500,
          //               ),
          //             ),
          //             const Spacer(),
          //             Image.asset(
          //               'assets/jadwal/clock.png',
          //               width: 14,
          //               height: 14,
          //             ),
          //             const SizedBox(width: 4),
          //             const Text('08:00', style: TextStyle(fontSize: 12)),
          //           ],
          //         ),
          //         const SizedBox(height: 16),
          //         Row(
          //           children: [
          //             Image.asset(
          //               'assets/jadwal/fork.png',
          //               width: 25,
          //               height: 25,
          //             ),
          //             const SizedBox(width: 8),
          //             const Text(
          //               'Pemanenan',
          //               style: TextStyle(
          //                 fontSize: 13,
          //                 fontWeight: FontWeight.w500,
          //               ),
          //             ),
          //             const Spacer(),
          //             ElevatedButton(
          //               style: ElevatedButton.styleFrom(
          //                 backgroundColor: const Color.fromRGBO(
          //                   76,
          //                   175,
          //                   80,
          //                   1,
          //                 ), // Hijau RGBO
          //                 padding: const EdgeInsets.symmetric(
          //                   horizontal: 12,
          //                   vertical: 8,
          //                 ),
          //                 textStyle: const TextStyle(fontSize: 12),
          //               ),
          //               onPressed: () {
          //                 showDialog(
          //                   context: context,
          //                   builder: (BuildContext context) {
          //                     return AlertDialog(
          //                       title: const Text('Konfirmasi'),
          //                       content: const Text('Yakin untuk Panen?'),
          //                       actions: [
          //                         TextButton(
          //                           child: const Text('Batal', style: TextStyle(color: Color.fromARGB(255, 0, 0, 0))),
          //                           onPressed: () {
          //                             Navigator.of(
          //                               context,
          //                             ).pop(); // Tutup dialog
          //                           },
          //                         ),
          //                         ElevatedButton(
          //                           style: ElevatedButton.styleFrom(
          //                             backgroundColor: const Color.fromRGBO(
          //                               76,
          //                               175,
          //                               80,
          //                               1,
          //                             ),
          //                           ),
          //                           child: const Text('Ya', style: TextStyle(color: Colors.white)),
          //                           onPressed: () {
          //                             Navigator.of(
          //                               context,
          //                             ).pop(); // Tutup dialog
          //                             Navigator.push(
          //                               context,
          //                               MaterialPageRoute(
          //                                 builder: (context) => DetailPanen(),
          //                               ),
          //                             );
          //                           },
          //                         ),
          //                       ],
          //                     );
          //                   },
          //                 );
          //               },
          //               child: const Text(
          //                 'Panen',
          //                 style: TextStyle(color: Colors.white),
          //               ),
          //             ),
          //           ],
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
          // const SizedBox(height: 16),
        ],
      ),
    );
  }
}
