import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../models/enums.dart';
import '../../models/service_booking.dart';
import '../../providers/app_providers.dart';
import '../../services/notification_service.dart';


class BookingPage extends ConsumerStatefulWidget {
  const BookingPage({super.key});

  @override
  ConsumerState<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends ConsumerState<BookingPage> {
  ServiceType _type = ServiceType.routine;
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _time = const TimeOfDay(hour: 10, minute: 0);
  final TextEditingController _workshop = TextEditingController(text: 'Bengkel Utama');

  double _estimated = 500000;
  String? _selectedCarId;

  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _selectedCarId = ref.read(mainCarIdProvider);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final cars = ref.watch(carsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Atur Jadwal'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [


                  // ---------------------------------------
                  // PILIH MOBIL
                  // ---------------------------------------
                  if (cars.isNotEmpty)
                    Neumorphic(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      style: NeumorphicStyle(
                        shape: NeumorphicShape.flat,
                        boxShape: NeumorphicBoxShape.roundRect(
                          BorderRadius.circular(12),
                        ),
                        depth: 2,
                        lightSource: LightSource.topLeft,
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedCarId,
                            hint: const Text('Pilih Mobil'),
                            items: cars
                                .map(
                                  (car) => DropdownMenuItem(
                                    value: car.id,
                                    child: Text(
                                      '${car.brand} ${car.model} (${car.plateNumber})',
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              setState(() => _selectedCarId = v);
                            },
                          ),
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'Anda belum memiliki mobil terdaftar. Silakan tambahkan mobil terlebih dahulu.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),

                  const SizedBox(height: 8),

                  // ---------------------------------------
                  // JENIS SERVIS
                  // ---------------------------------------
                  Neumorphic(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    style: NeumorphicStyle(
                      shape: NeumorphicShape.flat,
                      boxShape: NeumorphicBoxShape.roundRect(
                        BorderRadius.circular(12),
                      ),
                      depth: 2,
                      lightSource: LightSource.topLeft,
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<ServiceType>(
                          isExpanded: true,
                          value: _type,
                          items: const [
                            DropdownMenuItem(
                              value: ServiceType.routine,
                              child: Text('Servis Rutin'),
                            ),
                            DropdownMenuItem(
                              value: ServiceType.major,
                              child: Text('Servis Besar'),
                            ),
                            DropdownMenuItem(
                              value: ServiceType.partReplacement,
                              child: Text('Ganti Sparepart'),
                            ),
                          ],
                          onChanged: (v) {
                            setState(() => _type = v ?? _type);
                          },
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ---------------------------------------
                  // BENGKEL
                  // ---------------------------------------
                  Neumorphic(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    style: NeumorphicStyle(
                      shape: NeumorphicShape.flat,
                      boxShape: NeumorphicBoxShape.roundRect(
                        BorderRadius.circular(12),
                      ),
                      depth: 2,
                      lightSource: LightSource.topLeft,
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: TextField(
                        controller: _workshop,
                        decoration: const InputDecoration(
                          labelText: 'Pilih Bengkel',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ---------------------------------------
                  // TANGGAL
                  // ---------------------------------------
                  Neumorphic(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    style: NeumorphicStyle(
                      shape: NeumorphicShape.flat,
                      boxShape: NeumorphicBoxShape.roundRect(
                        BorderRadius.circular(12),
                      ),
                      depth: 2,
                      lightSource: LightSource.topLeft,
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                    ),
                    child: GFButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                          initialDate: _date,
                        );

                        if (picked != null) {
                          setState(() {
                            _date = picked;
                          });
                        }
                      },
                      text:
                          'Tanggal: ${_date.toLocal().toString().split(' ').first}',
                      icon: const Icon(Icons.calendar_today),
                      blockButton: true,
                      type: GFButtonType.transparent,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ---------------------------------------
                  // JAM
                  // ---------------------------------------
                  Neumorphic(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    style: NeumorphicStyle(
                      shape: NeumorphicShape.flat,
                      boxShape: NeumorphicBoxShape.roundRect(
                        BorderRadius.circular(12),
                      ),
                      depth: 2,
                      lightSource: LightSource.topLeft,
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                    ),
                    child: GFButton(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _time,
                        );

                        if (picked != null) {
                          setState(() => _time = picked);
                        }
                      },
                      text: 'Jam: ${_time.format(context)}',
                      icon: const Icon(Icons.schedule),
                      blockButton: true,
                      type: GFButtonType.transparent,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ---------------------------------------
                  // ESTIMASI BIAYA
                  // ---------------------------------------
                  Neumorphic(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    style: NeumorphicStyle(
                      shape: NeumorphicShape.flat,
                      boxShape: NeumorphicBoxShape.roundRect(
                        BorderRadius.circular(12),
                      ),
                      depth: 2,
                      lightSource: LightSource.topLeft,
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Estimasi Biaya: Rp ${_estimated.toStringAsFixed(0)}',
                          ),
                          Slider(
                            value: _estimated,
                            onChanged: (v) =>
                                setState(() => _estimated = v),
                            min: 100000,
                            max: 5000000,
                            divisions: 49,
                            label: _estimated.toStringAsFixed(0),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ---------------------------------------
                  // TOMBOL BOOKING
                  // ---------------------------------------
                  Builder(
                    builder: (innerContext) => GFButton(
                      icon: const Icon(Icons.book_online),
                      onPressed: () {
                        if (user == null || _selectedCarId == null) {
                          ScaffoldMessenger.of(innerContext).showSnackBar(
                            const SnackBar(
                              content: Text('Login dan pilih mobil dulu.'),
                            ),
                          );
                          return;
                        }

                        final scheduled = DateTime(
                          _date.year,
                          _date.month,
                          _date.day,
                          _time.hour,
                          _time.minute,
                        );

                        final booking = ServiceBooking(
                          id: _uuid.v4(),
                          userId: user.id,
                          carId: _selectedCarId!,
                          type: _type,
                          workshop: _workshop.text,
                          scheduledAt: scheduled,
                          estimatedCost: _estimated,
                        );

                        ref.read(bookingsProvider.notifier).add(booking);

                        NotificationService().scheduleServiceReminder(
                          id: booking.hashCode,
                          title: 'Pengingat Servis',
                          body: 'Jadwal servis besok di ${booking.workshop}.',
                          when: scheduled.subtract(const Duration(days: 1)),
                        );

                        ScaffoldMessenger.of(innerContext).showSnackBar(
                          const SnackBar(
                            content: Text('Booking berhasil dibuat!'),
                          ),
                        );
                      },
                      text: 'Booking',
                      color: const Color(0xFF1E88E5),
                    ),
                  ),
                ],
              ),
            ),
    )
    );
  }
}
