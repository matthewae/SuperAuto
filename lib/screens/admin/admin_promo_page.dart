import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../models/promo.dart';
import '../../providers/app_providers.dart';

class AdminPromoPage extends ConsumerStatefulWidget {
  const AdminPromoPage({super.key});

  @override
  ConsumerState<AdminPromoPage> createState() => _AdminPromoPageState();
}

class _AdminPromoPageState extends ConsumerState<AdminPromoPage> {
  @override
  Widget build(BuildContext context) {
    final promos = ref.watch(promosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Promo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddEditPromoDialog(),
          ),
        ],
      ),
      body: promos.isEmpty
          ? const Center(child: Text('Belum ada promo'))
          : ListView.builder(
        itemCount: promos.length,
        itemBuilder: (context, index) {
          final promo = promos[index];
          return _buildPromoCard(promo);
        },
      ),
    );
  }

  Widget _buildPromoCard(Promo promo) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final isActive = promo.isActive();

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    promo.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isActive ? 'Aktif' : 'Tidak Aktif',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Tipe: ${promo.formattedType}',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'Nilai: ${promo.formattedValue}',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'Berlaku: ${dateFormat.format(promo.start)} - ${dateFormat.format(promo.end)}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showAddEditPromoDialog(promo: promo),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _showDeletePromoDialog(promo.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddEditPromoDialog({Promo? promo}) {
    final nameController = TextEditingController(text: promo?.name ?? '');
    String type = promo?.type ?? 'product_discount';
    double value = promo?.value ?? 0.0;
    DateTime startDate = promo?.start ?? DateTime.now();
    DateTime endDate = promo?.end ?? DateTime.now().add(const Duration(days: 30));
    bool isPercentage = promo != null ? promo.value <= 1 : true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(promo == null ? 'Tambah Promo' : 'Edit Promo'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Promo',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: type,
                      decoration: const InputDecoration(
                        labelText: 'Tipe Promo',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'service_discount',
                          child: Text('Diskon Servis'),
                        ),
                        DropdownMenuItem(
                          value: 'product_discount',
                          child: Text('Diskon Produk'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            type = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: isPercentage ? 'Persentase (%)' : 'Nilai (Rp)',
                              border: const OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (text) {
                              final newValue = double.tryParse(text) ?? 0.0;
                              setState(() {
                                value = isPercentage ? newValue / 100 : newValue;
                              });
                            },
                            controller: TextEditingController(
                              text: isPercentage
                                  ? (value * 100).toStringAsFixed(0)
                                  : value.toStringAsFixed(0),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Switch(
                          value: isPercentage,
                          onChanged: (newValue) {
                            setState(() {
                              isPercentage = newValue;
                            });
                          },
                        ),
                        const Text('%'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('Tanggal Mulai'),
                      subtitle: Text(DateFormat('dd MMM yyyy').format(startDate)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: startDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() {
                            startDate = date;
                            if (endDate.isBefore(startDate)) {
                              endDate = startDate.add(const Duration(days: 30));
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      title: const Text('Tanggal Berakhir'),
                      subtitle: Text(DateFormat('dd MMM yyyy').format(endDate)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: endDate,
                          firstDate: startDate,
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() {
                            endDate = date;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Nama promo harus diisi')),
                      );
                      return;
                    }

                    if (value <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Nilai promo harus lebih dari 0')),
                      );
                      return;
                    }

                    final newPromo = Promo(
                      id: promo?.id ?? const Uuid().v4(),
                      name: nameController.text,
                      type: type,
                      value: value,
                      start: startDate,
                      end: endDate,
                      createdAt: promo?.createdAt ?? DateTime.now(),
                      updatedAt: DateTime.now(),
                    );

                    try {
                      if (promo == null) {
                        await ref.read(promosProvider.notifier).add(newPromo);
                      } else {
                        await ref.read(promosProvider.notifier).update(newPromo);
                      }
                      Navigator.of(context).pop();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeletePromoDialog(String promoId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Promo'),
          content: const Text('Apakah Anda yakin ingin menghapus promo ini?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await ref.read(promosProvider.notifier).delete(promoId);
                  Navigator.of(context).pop();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }
}