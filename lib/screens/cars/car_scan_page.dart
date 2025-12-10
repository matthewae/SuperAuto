import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:uuid/uuid.dart';
import '../../models/car.dart';
import '../../providers/app_providers.dart';

class CarScanPage extends ConsumerStatefulWidget {
  const CarScanPage({super.key});
  @override
  ConsumerState<CarScanPage> createState() => _CarScanPageState();
}

class _CarScanPageState extends ConsumerState<CarScanPage> {
  final _uuid = const Uuid();
  final bool _added = false;


  Future<bool> _waitForAuthInitialization() async {
    final authNotifier = ref.read(authProvider.notifier);
    int attempts = 0;
    while (!authNotifier.isInitialized && attempts < 10) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }
    return authNotifier.isInitialized;
  }

  Future<void> _addFromMap(Map<String, dynamic> data) async {
    try {

      final isInitialized = await _waitForAuthInitialization();
      if (!isInitialized) {
        throw Exception('Gagal memuat data pengguna. Silakan coba lagi.');
      }

      final currentUser = ref.read(authProvider).value;
      if (currentUser == null) {
        throw Exception('Anda harus login terlebih dahulu untuk menambahkan mobil.');
      }

      final car = Car(
        id: _uuid.v4(),
        userId: currentUser.id,
        brand: data['brand'] ?? 'Unknown',
        model: data['model'] ?? 'Unknown',
        year: (data['year'] ?? 0) is int ? data['year'] : int.tryParse('${data['year']}') ?? 0,
        plateNumber: data['plate'] ?? 'N/A',
        vin: data['vin'] ?? 'N/A',
        engineNumber: data['engine'] ?? 'N/A',
        initialKm: (data['km'] ?? 0) is int ? data['km'] : int.tryParse('${data['km']}') ?? 0,
        isMain: false,
      );

      await ref.read(carsProvider.notifier).add(car);

      // Check if this is the first car being added
      final userCars = ref.read(carsProvider);
      final hasMainCar = userCars.any((c) => c.isMain);
      if (!hasMainCar) {
        await ref.read(carDaoProvider).updateMainCarStatus(car.id, true);
        ref.invalidate(carsProvider);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mobil berhasil ditambahkan')),
      );

      // Optionally navigate back or reset the form
      if (mounted) {
        Navigator.of(context).pop(true); // Return success
      }
    } catch (e) {
      debugPrint('Error in _addFromMap: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menambahkan mobil: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {

    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrasi Mobil'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Registrasi Mobil Baru',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Scan QR code atau isi form manual di bawah',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              if (!kIsWeb)
                Container(
                  height: 250,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: MobileScanner(
                      onDetect: (capture) {
                        if (_added) return;
                        final raw = capture.barcodes.isNotEmpty ? capture.barcodes.first.rawValue : null;
                        if (raw != null) {
                          try {
                            final data = jsonDecode(raw);
                            if (data is Map<String, dynamic>) {
                              _addFromMap(data);
                            }
                          } catch (_) {
                            // ignore
                          }
                        }
                      },
                    ),
                  ),
                )
              else
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_scanner, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('Scan QR tidak tersedia di web'),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 32),
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text('ATAU', style: TextStyle(color: Colors.grey)),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 24),
              
              _ManualForm(onSubmit: _addFromMap),
              const SizedBox(height: 24),
            ],
          ),
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _brand,
          decoration: InputDecoration(
            labelText: 'Merek',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _model,
          decoration: InputDecoration(
            labelText: 'Model',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _year,
          decoration: InputDecoration(
            labelText: 'Tahun',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _plate,
          decoration: InputDecoration(
            labelText: 'Nomor Polisi',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _vin,
          decoration: InputDecoration(
            labelText: 'Nomor Rangka (VIN)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _engine,
          decoration: InputDecoration(
            labelText: 'Nomor Mesin',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _km,
          decoration: InputDecoration(
            labelText: 'Kilometer Awal',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
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
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Simpan Data Mobil',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
