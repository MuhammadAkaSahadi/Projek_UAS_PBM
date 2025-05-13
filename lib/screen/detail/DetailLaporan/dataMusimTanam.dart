import 'package:flutter/material.dart';

class DataMusimTanamSection extends StatelessWidget {
  final TextEditingController tanggalTanamController;
  final TextEditingController jenisTanamanController;
  final TextEditingController luasLahanController;
  final String satuanLuas;
  final String sumberBenih;
  final List<String> satuanLuasOptions;
  final List<String> sumberBenihOptions;
  final ValueChanged<String?> onSatuanLuasChanged;
  final ValueChanged<String?> onSumberBenihChanged;

  const DataMusimTanamSection({
    super.key,
    required this.tanggalTanamController,
    required this.jenisTanamanController,
    required this.luasLahanController,
    required this.satuanLuas,
    required this.sumberBenih,
    required this.satuanLuasOptions,
    required this.sumberBenihOptions,
    required this.onSatuanLuasChanged,
    required this.onSumberBenihChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Data Musim Tanam',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: tanggalTanamController,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Tanggal Mulai Tanam',
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.calendar_today),
            ),
            onTap: () async {
              DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2101),
              );
              if (pickedDate != null) {
                tanggalTanamController.text =
                    "${pickedDate.day}-${pickedDate.month}-${pickedDate.year}";
              }
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: jenisTanamanController,
            decoration: const InputDecoration(
              labelText: 'Jenis Tanaman',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: luasLahanController,
                  decoration: const InputDecoration(
                    labelText: 'Luas Lahan',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  value: satuanLuas,
                  items: satuanLuasOptions
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: onSatuanLuasChanged,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: sumberBenih,
            items: sumberBenihOptions
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: onSumberBenihChanged,
            decoration: const InputDecoration(
              labelText: 'Sumber Benih',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}
