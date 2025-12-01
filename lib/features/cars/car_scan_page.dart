import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:uuid/uuid.dart';
import '../../models/car.dart';
import '../../providers/app_providers.dart';
import '../../widgets/neumorphic_header.dart';

class CarScanPage extends ConsumerStatefulWidget {
  const CarScanPage({super.key});
  @override
  ConsumerState<CarScanPage> createState() => _CarScanPageState();
}

class _CarScanPageState extends ConsumerState<CarScanPage> {
  final _uuid = const Uuid();
  bool _added = false;

  void _addFromMap(Map<String, dynamic> data) {
    final car = Car(
      id: _uuid.v4(),
      brand: data['brand'] ?? 'Unknown',
      model: data['model'] ?? 'Unknown',
      year: (data['year'] ?? 0) is int ? data['year'] : int.tryParse('${data['year']}') ?? 0,
      plateNumber: data['plate'] ?? 'N/A',
      vin: data['vin'] ?? 'N/A',
      engineNumber: data['engine'] ?? 'N/A',
      initialKm: (data['km'] ?? 0) is int ? data['km'] : int.tryParse('${data['km']}') ?? 0,
    );
    ref.read(carsProvider.notifier).add(car);
    final currentMain = ref.read(mainCarIdProvider);
    if (currentMain.isEmpty) {
      ref.read(mainCarIdProvider.notifier).state = car.id;
    }
    setState(() => _added = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GFAppBar(title: const Text('Scan QR Registrasi Mobil')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const NeumorphicHeader(title: 'Registrasi Cepat', subtitle: 'Scan QR atau input manual'),
            if (!kIsWeb)
              Expanded(
                child: MobileScanner(
                  onDetect: (capture) {
                    if (_added) return;
                    final raw = capture.barcodes.isNotEmpty ? capture.barcodes.first.rawValue : null;
                    if (raw != null) {
                      try {
                        final data = jsonDecode(raw);
                        if (data is Map<String, dynamic>) {
                          _addFromMap(data);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mobil ditambahkan')));
                        }
                      } catch (_) {
                        // ignore malformed
                      }
                    }
                  },
                ),
              )
            else
              const Text('Scan QR tidak didukung di web, gunakan input manual.'),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            const Text('Input Manual'),
            const SizedBox(height: 8),
            _ManualForm(onSubmit: _addFromMap),
          ],
        ),
      ),
    );
  }
}

class _ManualForm extends StatefulWidget {
  final void Function(Map<String, dynamic>) onSubmit;
  const _ManualForm({required this.onSubmit});
  @override
  State<_ManualForm> createState() => _ManualFormState();
}

class _ManualFormState extends State<_ManualForm> {
  final _brand = TextEditingController();
  final _model = TextEditingController();
  final _year = TextEditingController();
  final _plate = TextEditingController();
  final _vin = TextEditingController();
  final _engine = TextEditingController();
  final _km = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(controller: _brand, decoration: const InputDecoration(labelText: 'Merek')),
        TextField(controller: _model, decoration: const InputDecoration(labelText: 'Model')),
        TextField(controller: _year, decoration: const InputDecoration(labelText: 'Tahun'), keyboardType: TextInputType.number),
        TextField(controller: _plate, decoration: const InputDecoration(labelText: 'Nomor Polisi')),
        TextField(controller: _vin, decoration: const InputDecoration(labelText: 'Nomor Rangka (VIN)')),
        TextField(controller: _engine, decoration: const InputDecoration(labelText: 'Nomor Mesin')),
        TextField(controller: _km, decoration: const InputDecoration(labelText: 'Kilometer Awal'), keyboardType: TextInputType.number),
        const SizedBox(height: 12),
        GFButton(
          onPressed: () {
            widget.onSubmit({
              'brand': _brand.text,
              'model': _model.text,
              'year': int.tryParse(_year.text) ?? 0,
              'plate': _plate.text,
              'vin': _vin.text,
              'engine': _engine.text,
              'km': int.tryParse(_km.text) ?? 0,
            });
          },
          text: 'Simpan',
          color: const Color(0xFF1E88E5),
        ),
      ],
    );
  }
}
