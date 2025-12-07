import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
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

  Future<bool> _waitForAuthInitialization() async {
    final authNotifier = ref.read(authProvider.notifier);
    if (authNotifier is! AuthNotifier) return false;
    
    int attempts = 0;
    while (!authNotifier.isInitialized && attempts < 10) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }
    return authNotifier.isInitialized;
  }

  Future<void> _addFromMap(Map<String, dynamic> data) async {
    try {
      // Wait for auth to initialize
      final isInitialized = await _waitForAuthInitialization();
      if (!isInitialized) {
        throw Exception('Gagal memuat data pengguna. Silakan coba lagi.');
      }

      // Get the current auth state
      final authState = ref.read(authProvider);
      final currentUser = authState.when(
        data: (user) => user,
        loading: () {
          print('Auth state is still loading...');
          return null;
        },
        error: (error, stack) {
          print('Error getting auth state: $error');
          return null;
        },
      );

      if (currentUser == null) {
        throw Exception('Anda harus login terlebih dahulu untuk menambahkan mobil.');
      }

      print('Adding car for user: ${currentUser.idString}');

      final car = Car(
        id: _uuid.v4(),
        userId: currentUser.id!,  // Make sure this is the correct user ID
        brand: data['brand'] ?? 'Unknown',
        model: data['model'] ?? 'Unknown',
        year: (data['year'] ?? 0) is int ? data['year'] : int.tryParse('${data['year']}') ?? 0,
        plateNumber: data['plate'] ?? 'N/A',
        vin: data['vin'] ?? 'N/A',
        engineNumber: data['engine'] ?? 'N/A',
        initialKm: (data['km'] ?? 0) is int ? data['km'] : int.tryParse('${data['km']}') ?? 0,
      );

      await ref.read(carsProvider.notifier).add(car);

      final currentMain = ref.read(mainCarIdProvider);
      if (currentMain.isEmpty) {
        await ref.read(mainCarIdProvider.notifier).setMainCarId(currentUser.idString, car.id);
      }

      if (mounted) {
        setState(() => _added = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mobil berhasil ditambahkan')),
        );
      }
    } catch (e) {
      print('Error in _addFromMap: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menambahkan mobil: ${e.toString()}')),
        );
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GFAppBar(title: const Text('Scan QR Registrasi Mobil')),
      body: SafeArea(  // tambahin ini biar aman
        child: SingleChildScrollView(  // INI YANG PALING PENTING!!!
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const NeumorphicHeader(
                title: 'Registrasi Cepat',
                subtitle: 'Scan QR atau input manual',
              ),
              const SizedBox(height: 16),

              // Scanner (tetap Expanded, tapi dibungkus SizedBox biar bisa scroll)
              if (!kIsWeb)
                SizedBox(
                  height: 300, // batasi tinggi scanner
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
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
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(child: Text('Scan QR tidak tersedia di web')),
                ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              const Text('Atau Input Manual', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // Form Manual — sekarang bisa scroll!
              _ManualForm(onSubmit: _addFromMap),

              const SizedBox(height: 100), // jarak bawah biar tombol nggak ketutup keyboard
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
