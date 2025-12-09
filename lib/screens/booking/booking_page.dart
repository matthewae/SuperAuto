
import 'package:getwidget/getwidget.dart';
import 'package:collection/collection.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';


import '../../models/enums.dart';
import '../../models/service_booking.dart';
import '../../providers/app_providers.dart';
import '../../services/notification_service.dart';


import '../../models/car.dart';

class BookingPage extends ConsumerStatefulWidget {

  const BookingPage({super.key});

  @override
  ConsumerState<BookingPage> createState() => _BookingPageState();
}
extension TimeOfDayExtension on TimeOfDay {
  TimeOfDay add({int hours = 0, int minutes = 0}) {
    int newMinutes = (minute + minutes) % 60;
    int addHours = (minute + minutes) ~/ 60;
    int newHours = (this.hour + hours + addHours) % 24;
    return TimeOfDay(hour: newHours, minute: newMinutes);
  }
}
class _BookingPageState extends ConsumerState<BookingPage> {
  final _formKey = GlobalKey<FormState>();
  late TimeOfDay _time; // Add this line
  ServiceType _type = ServiceType.routine;
  DateTime _date = DateTime.now().add(const Duration(days: 1));

  @override
  void initState() {
    super.initState();
    // Initialize _time to the next hour
    final now = TimeOfDay.now();
    _time = TimeOfDay(hour: now.hour, minute: 0);
    _time = _time.add(hours: 1);
    
    final userCars = ref.read(carsProvider);
    _selectedCarId = userCars.firstWhereOrNull((car) => car.isMain)?.id;

  }

  final TextEditingController _workshopController = TextEditingController(text: 'Bengkel Utama');
  final TextEditingController _notesController = TextEditingController();
  double _estimated = 500000;
  String? _selectedCarId;


  bool _isSubmitting = false;
  final _uuid = const Uuid();





  @override
  void dispose() {
    _workshopController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitBooking() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);
    try {
      final user = ref.read(authProvider).value;
      if (user == null) {
        throw Exception('Silakan login terlebih dahulu');
      }

      // Get user's cars
      final userCars = await ref.read(carDaoProvider).getByUserId(user.idString);
      if (userCars.isEmpty) {
        throw Exception('Anda belum menambahkan mobil. Silakan tambahkan mobil terlebih dahulu.');
      }

      // Find the main car
      final mainCar = userCars.firstWhere(
        (car) => car.isMain,
        orElse: () {
          // If no main car is set, use the first car
          if (userCars.isNotEmpty) {
            // Set the first car as main
            ref.read(carDaoProvider).updateMainCarStatus(userCars.first.id, true);
            return userCars.first;
          }
          throw Exception('Tidak ada mobil yang tersedia');
        },
      );

      final scheduled = DateTime(
          _date.year, _date.month, _date.day, _time.hour, _time.minute
      );

      final booking = ServiceBooking(
        id: const Uuid().v4(),
        userId: user.idString,
        carId: mainCar.id,  // Use the verified car ID
        serviceType: _type.toString().split('.').last,
        scheduledAt: scheduled,
        estimatedCost: _estimated,
        notes: _notesController.text,
        status: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save booking
      ref.read(bookingsProvider.notifier).add(booking);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking berhasil dibuat')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }




  Future<void> _selectTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              surface: Theme.of(context).scaffoldBackgroundColor,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedTime != null && pickedTime != _time) {
      setState(() => _time = pickedTime);
    }
  }


  @override
  Widget build(BuildContext context) {

    
    final authState = ref.watch(authProvider);
    final user = authState.value;
    final userCars = ref.watch(carsProvider);
    final mainCar = userCars.firstWhereOrNull((car) => car.isMain);

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
                  if (userCars.isNotEmpty)
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
                            items: userCars
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
                        controller: _workshopController,
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
                        final user = ref.read(authProvider).value;
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
                          userId: user.idString,
                          carId: _selectedCarId!,
                          serviceType: _type.toString().split('.').last,
                          workshop: _workshopController.text,
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