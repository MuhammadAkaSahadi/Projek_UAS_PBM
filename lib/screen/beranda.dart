import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:projek_uas/weather/fetchCuaca.dart';

class Beranda extends StatefulWidget {
  const Beranda({super.key});

  @override
  _BerandaState createState() => _BerandaState();
}

class _BerandaState extends State<Beranda> {
  final Map<String, Map<String, double>> daftarKota = {
    'Jember': {'lat': -8.1737, 'lon': 113.7002},
    'Bondowoso': {'lat': -7.9135, 'lon': 113.8208},
    'Lumajang': {'lat': -8.1349, 'lon': 113.2249},
    'Probolinggo': {'lat': -7.7569, 'lon': 113.2115},
    'Banyuwangi': {'lat': -8.2192, 'lon': 114.3691},
  };

  String cityName = '';
  double temperature = 0.0;
  String condition = '';
  List<dynamic> forecastList = [];
  String suggestion = '';
  String? selectedKota;
  bool useManualKota = false;
  String iconMain = 'unknown';

  String _translateCondition(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return 'Cerah';
      case 'clouds':
        return 'Berawan';
      case 'rain':
        return 'Hujan';
      case 'thunderstorm':
        return 'Badai Petir';
      case 'drizzle':
        return 'Gerimis';
      case 'mist':
      case 'haze':
        return 'Berkabut';
      case 'snow':
        return 'Salju';
      default:
        return condition; // fallback: tampilkan aslinya
    }
  }

  @override
  void initState() {
    super.initState();
    _loadWeatherData();
  }

  Future<void> _loadWeatherData() async {
    double lat, lon;

    if (useManualKota && selectedKota != null) {
      lat = daftarKota[selectedKota]!['lat']!;
      lon = daftarKota[selectedKota]!['lon']!;
    } else {
      final position = await Geolocator.getCurrentPosition();
      lat = position.latitude;
      lon = position.longitude;
    }

    final current = await CuacaService.getCurrentWeather(lat, lon);
    final forecast = await CuacaService.getForecast(lat, lon);
    // final city = await CuacaService.getCityName(lat, lon);

    setState(() {
      // cityName = city;
      temperature = current['main']['temp'];
      condition = current['weather'][0]['main'];
      iconMain = _getLocalWeatherIcon(condition);
      forecastList = forecast.take(5).toList();
      suggestion = _getSuggestion(current);
    });
  }

  String _getSuggestion(Map<String, dynamic> weather) {
    double temp = weather['main']['temp'];
    double rain = weather['rain'] != null ? weather['rain']['1h'] ?? 0.0 : 0.0;

    if (rain > 2) {
      return 'Hindari tanam/panen, hujan lebat.';
    } else if (temp > 30) {
      return 'Cuaca panas, baik untuk pengeringan hasil panen.';
    } else if (temp >= 24 && temp <= 30) {
      return 'Ideal untuk penanaman dan penyiraman.';
    }

    return 'Perhatikan cuaca, mungkin tidak ideal untuk aktivitas menanam.';
  }

  String _getLocalWeatherIcon(String main) {
    switch (main.toLowerCase()) {
      case 'clear':
        return 'clear';
      case 'clouds':
        return 'clouds';
      case 'rain':
        return 'rain';
      case 'thunderstorm':
        return 'thunderstorm';
      case 'drizzle':
        return 'drizzle';
      case 'mist':
      case 'haze':
        return 'mist';
      default:
        return 'unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/logo.png', // Ganti dengan path logo kamu
              height: 32, // Atur ukuran sesuai kebutuhan
            ),
            SizedBox(width: 8),
            Text('PocketFarm', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on),
                        SizedBox(width: 4),
                        DropdownButton<String>(
                          hint: Text('Pilih Kota'),
                          value: selectedKota,
                          items:
                              daftarKota.keys.map((String kota) {
                                return DropdownMenuItem<String>(
                                  value: kota,
                                  child: Text(kota),
                                );
                              }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedKota = value;
                              useManualKota = true;
                              _loadWeatherData();
                            });
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${temperature.toStringAsFixed(0)}°C',
                          style: TextStyle(
                            fontSize: 54,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Image.asset(
                          'assets/weather/$iconMain.png',
                          width: 70,
                          height: 70,
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Kondisi : ${_translateCondition(condition)}',
                      style: TextStyle(fontSize: 18),
                    ),
                    Text(
                      suggestion,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Divider(),
                    SizedBox(height: 8),
                    SizedBox(
                      height: 150,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: forecastList.length,
                        itemBuilder: (context, index) {
                          final item = forecastList[index];
                          final icon = _getLocalWeatherIcon(
                            item['weather'][0]['main'],
                          );
                          final waktu = DateFormat(
                            'EEEE, HH:mm',
                            'id_ID',
                          ).format(DateTime.parse(item['dt_txt']));
                          final suhu = item['main']['temp'];
                          final kondisi = _translateCondition(
                            item['weather'][0]['main'],
                          );

                          return Container(
                            width: 100,
                            margin: EdgeInsets.symmetric(horizontal: 8),
                            child: Column(
                              children: [
                                Image.asset(
                                  'assets/weather/$icon.png',
                                  width: 30,
                                  height: 30,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  waktu.split(',')[0],
                                  style: TextStyle(fontSize: 14),
                                ),
                                Text(
                                  waktu.split(',')[1].trim(),
                                  style: TextStyle(fontSize: 14),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '${suhu.toStringAsFixed(1)}°C',
                                  style: TextStyle(fontSize: 14),
                                ),
                                Text(kondisi, style: TextStyle(fontSize: 14)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
