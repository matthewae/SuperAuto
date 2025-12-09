// Create a new file: car_edit_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_providers.dart';
import '../../models/car.dart';

class CarEditPage extends ConsumerStatefulWidget {
  final String carId;
  const CarEditPage({super.key, required this.carId});

  @override
  ConsumerState<CarEditPage> createState() => _CarEditPageState();
}

class _CarEditPageState extends ConsumerState<CarEditPage> {
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _plateController = TextEditingController();
  final _vinController = TextEditingController();
  final _engineController = TextEditingController();
  final _kmController = TextEditingController();

  bool _isLoading = false;
  Car? _car;

  @override
  void initState() {
    super.initState();
    _loadCar();
  }

  Future<void> _loadCar() async {
    final cars = ref.read(carsProvider);
    try {
      _car = cars.firstWhere((c) => c.id == widget.carId);
      _brandController.text = _car!.brand;
      _modelController.text = _car!.model;
      _yearController.text = _car!.year.toString();
      _plateController.text = _car!.plateNumber;
      _vinController.text = _car!.vin;
      _engineController.text = _car!.engineNumber;
      _kmController.text = _car!.initialKm.toString();
    } catch (e) {
      print('Error loading car: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memuat data mobil'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveCar() async {
    if (_car == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedCar = _car!.copyWith(
        brand: _brandController.text,
        model: _modelController.text,
        year: int.tryParse(_yearController.text) ?? _car!.year,
        plateNumber: _plateController.text,
        vin: _vinController.text,
        engineNumber: _engineController.text,
        initialKm: int.tryParse(_kmController.text) ?? _car!.initialKm,
      );

      await ref.read(carsProvider.notifier).updateCar(updatedCar);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data mobil berhasil diperbarui'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      print('Error saving car: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memperbarui data mobil'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Mobil'),
        actions: [
          IconButton(
            icon: _isLoading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
                : const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveCar,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _brandController,
              decoration: const InputDecoration(
                labelText: 'Merek',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _modelController,
              decoration: const InputDecoration(
                labelText: 'Model',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _yearController,
              decoration: const InputDecoration(
                labelText: 'Tahun',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _plateController,
              decoration: const InputDecoration(
                labelText: 'Nomor Polisi',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _vinController,
              decoration: const InputDecoration(
                labelText: 'Nomor Rangka (VIN)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _engineController,
              decoration: const InputDecoration(
                labelText: 'Nomor Mesin',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _kmController,
              decoration: const InputDecoration(
                labelText: 'Kilometer Awal',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }
}