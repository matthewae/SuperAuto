import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/enums.dart';
import '../../models/service_booking.dart';
import '../../providers/app_providers.dart';
import '../../services/notification_service.dart';
import '../../widgets/neumorphic_header.dart';

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
  final _uuid = const Uuid();

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final mainCarId = ref.watch(mainCarIdProvider);
    return Scaffold(
      appBar: GFAppBar(title: const Text('Booking Servis')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NeumorphicHeader(
              title: 'Atur Jadwal',
              subtitle: 'Pilih jenis servis, bengkel, tanggal & waktu',
              trailing: NeumorphicIcon(Icons.build, size: 32, style: const NeumorphicStyle(depth: 8)),
            ),
            const SizedBox(height: 12),
            DropdownButton<ServiceType>(
              value: _type,
              items: const [
                DropdownMenuItem(value: ServiceType.routine, child: Text('Servis Rutin')),
                DropdownMenuItem(value: ServiceType.major, child: Text('Servis Besar')),
                DropdownMenuItem(value: ServiceType.partReplacement, child: Text('Ganti Sparepart')),
              ],
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
            const SizedBox(height: 8),
            TextField(controller: _workshop, decoration: const InputDecoration(labelText: 'Pilih Bengkel')),
            const SizedBox(height: 8),
            Row(children: [
              Text('Tanggal: ${_date.toLocal().toString().split(' ').first}')
              , const SizedBox(width: 8),
              GFButton(
                onPressed: () async {
                  final d = await showDatePicker(
                    context: context,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    initialDate: _date,
                  );
                  if (d != null) setState(() => _date = d);
                },
                text: 'Pilih Tanggal',
                icon: const Icon(Icons.calendar_today),
              )
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Text('Jam: ${_time.format(context)}'),
              const SizedBox(width: 8),
              GFButton(
                onPressed: () async {
                  final t = await showTimePicker(context: context, initialTime: _time);
                  if (t != null) setState(() => _time = t);
                },
                text: 'Pilih Jam',
                icon: const Icon(Icons.schedule),
              )
            ]),
            const SizedBox(height: 8),
            Row(children: [
              const Text('Estimasi Biaya: '),
              Expanded(
                child: Slider(
                  value: _estimated,
                  onChanged: (v) => setState(() => _estimated = v),
                  min: 100000,
                  max: 5000000,
                  divisions: 30,
                  label: _estimated.toStringAsFixed(0),
                ),
              )
            ]),
            const Spacer(),
            GFButton(
              icon: const Icon(Icons.book_online),
              onPressed: () {
                if (user == null || mainCarId.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Login dan pilih mobil utama dulu.')),
                  );
                  return;
                }
                final scheduled = DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);
                final booking = ServiceBooking(
                  id: _uuid.v4(),
                  userId: user.id,
                  carId: mainCarId,
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
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking dibuat')));
              },
              text: 'Booking',
              color: const Color(0xFF1E88E5),
            )
          ],
        ),
      ),
    );
  }
}
