import 'package:flutter/material.dart';
import 'package:superauto/models/service_booking.dart';

class CompleteServiceDialog extends StatefulWidget {
  final ServiceBooking booking;
  final Function(String, List<String>, List<String>, int, double) onComplete;

  const CompleteServiceDialog({
    Key? key,
    required this.booking,
    required this.onComplete,
  }) : super(key: key);

  @override
  _CompleteServiceDialogState createState() => _CompleteServiceDialogState();
}

class _CompleteServiceDialogState extends State<CompleteServiceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _jobsController = TextEditingController();
  final _partsController = TextEditingController();
  final _kmController = TextEditingController();
  final _totalCostController = TextEditingController();

  @override
  void dispose() {
    _jobsController.dispose();
    _partsController.dispose();
    _kmController.dispose();
    _totalCostController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Detail Servis'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _jobsController,
                decoration: const InputDecoration(
                  labelText: 'Pekerjaan (pisahkan dengan koma)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Harap isi pekerjaan';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _partsController,
                decoration: const InputDecoration(
                  labelText: 'Part yang Diganti (pisahkan dengan koma)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Harap isi part yang diganti';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _kmController,
                decoration: const InputDecoration(
                  labelText: 'Kilometer',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Harap isi kilometer';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Harap masukkan angka yang valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _totalCostController,
                decoration: const InputDecoration(
                  labelText: 'Total Biaya',
                  border: OutlineInputBorder(),
                  prefixText: 'Rp ',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Harap isi total biaya';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Harap masukkan angka yang valid';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final jobs = _jobsController.text.split(',').map((e) => e.trim()).toList();
              final parts = _partsController.text.split(',').map((e) => e.trim()).toList();
              final km = int.parse(_kmController.text);
              final totalCost = double.parse(_totalCostController.text);

              widget.onComplete(
                widget.booking.id,
                jobs,
                parts,
                km,
                totalCost,
              );
              Navigator.pop(context);
            }
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}