import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../models/enums.dart';
import '../../models/service_booking.dart';
import '../../providers/app_providers.dart';
import '../../services/notification_service.dart';
import '../../widgets/neumorphic_header.dart';
import '../../models/user.dart';  // Adjust the path as needed
class BookingPage extends ConsumerStatefulWidget {
  const BookingPage({super.key});
  @override
  ConsumerState<BookingPage> createState() => _BookingPageState();
}
extension TimeOfDayExtension on TimeOfDay {
  TimeOfDay add({int hours = 0, int minutes = 0}) {
    int newMinutes = (this.minute + minutes) % 60;
    int addHours = (this.minute + minutes) ~/ 60;
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
    final notificationService = NotificationService();

  }

  final TextEditingController _workshopController = TextEditingController(text: 'Bengkel Utama');
  final TextEditingController _notesController = TextEditingController();
  double _estimated = 500000;
  bool _isPickupService = false;
  bool _isSubmitting = false;
  final _uuid = const Uuid();

  // Available time slots (every 30 minutes from 8 AM to 5 PM)
  List<TimeOfDay> get _availableTimeSlots {
    final slots = <TimeOfDay>[];
    for (var hour = 8; hour <= 17; hour++) {
      slots.add(TimeOfDay(hour: hour, minute: 0));
      if (hour < 17) {
        slots.add(TimeOfDay(hour: hour, minute: 30));
      }
    }
    return slots;
  }

  @override
  void dispose() {
    _workshopController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _date) {
      setState(() {
        _date = picked;
      });
    }
  }

  String _formatDate(BuildContext context, DateTime date) {
    return MaterialLocalizations.of(context).formatMediumDate(date);
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

  Future<void> _submitBooking() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);
    try {
      final user = ref.read(authProvider).value;
      final mainCarId = ref.read(mainCarIdProvider);

      if (user == null || mainCarId.isEmpty) {
        throw Exception('User not authenticated or no car selected');
      }

      final scheduled = DateTime(
          _date.year,
          _date.month,
          _date.day,
          _time.hour,
          _time.minute
      );

      final booking = ServiceBooking(
        id: _uuid.v4(),
        userId: user.idString,
        carId: mainCarId,
        serviceType: _type.toString().split('.').last,
        scheduledAt: scheduled,
        estimatedCost: _estimated,
        workshop: 'Bengkel Utama',
        status: 'pending',
        isPickupService: _isPickupService,
        notes: _notesController.text.trim(),
        createdAt: DateTime.now(),
      );

      ref.read(bookingsProvider.notifier).add(booking);

      // Schedule reminder one day before
      await NotificationService().scheduleServiceReminder(
        id: booking.id.hashCode,
        title: 'Pengingat Servis',
        body: 'Anda memiliki jadwal servis hari ini',
        when: booking.scheduledAt,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking berhasil dibuat'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat booking: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final mainCarId = ref.watch(mainCarIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Servis'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NeumorphicHeader(
                title: 'Atur Jadwal Servis',
                subtitle: 'Pilih detail servis dan jadwal yang diinginkan',
                trailing: NeumorphicIcon(
                  Icons.calendar_today,
                  size: 32,
                  style: const NeumorphicStyle(depth: 8),
                ),
              ),

              const SizedBox(height: 24),

              // Service Type
              _buildSectionTitle('Jenis Servis'),
              _buildServiceTypeSelector(),

              const SizedBox(height: 16),

              // Workshop Selection
              _buildSectionTitle('Bengkel'),
              _buildWorkshopField(),

              const SizedBox(height: 16),

              // Date & Time
              _buildSectionTitle('Tanggal & Waktu'),
              Row(
                children: [
                  Expanded(
                    child: _buildDateField(),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTimeField(),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Pickup Service Toggle
              _buildPickupServiceToggle(),

              const SizedBox(height: 16),

              // Estimated Cost
              _buildSectionTitle('Estimasi Biaya'),
              _buildEstimatedCostSlider(),

              const SizedBox(height: 16),

              // Additional Notes
              _buildSectionTitle('Catatan Tambahan'),
              _buildNotesField(),

              const SizedBox(height: 32),

              // Submit Button
              _buildSubmitButton(authState, mainCarId),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildServiceTypeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ServiceType>(
          value: _type,
          isExpanded: true,
          items: ServiceType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(
                type.toString().split('.').last.replaceAllMapped(
                  RegExp(r'([A-Z])'),
                      (match) => ' ${match.group(0)}',
                ).trim(),
                style: const TextStyle(fontSize: 16),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _type = value);
              // Update estimated cost based on service type
              switch (value) {
                case ServiceType.routine:
                  setState(() => _estimated = 500000);
                  break;
                case ServiceType.major:
                  setState(() => _estimated = 2500000);
                  break;
                case ServiceType.partReplacement:
                  setState(() => _estimated = 1000000);
                  break;
              }
            }
          },
        ),
      ),
    );
  }

  Widget _buildWorkshopField() {
    return TextFormField(
      readOnly: true,
      controller: _workshopController,
      decoration: InputDecoration(
        labelText: 'Nama Bengkel',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        prefixIcon: const Icon(Icons.business),
        suffixIcon: const Icon(Icons.lock, size: 18),

        // suffixIcon: PopupMenuButton<String>(
        //   icon: const Icon(Icons.arrow_drop_down),
        //   onSelected: (value) {
        //     _workshopController.text = value;
        //   },
        //   itemBuilder: (context) {
        //     return [
        //       'Bengkel Utama',
        //       'Bengkel Cempaka',
        //       'Bengkel Melati',
        //       'Bengkel Anggrek',
        //     ].map((workshop) {
        //       return PopupMenuItem(
        //         value: workshop,
        //         child: Text(workshop),
        //       );
        //     }).toList();
        //   },
        // ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Silakan pilih bengkel';
        }
        return null;
      },
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tanggal Servis', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDate(context),
          child: InputDecorator(
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.all(12),
              suffixIcon: const Icon(Icons.calendar_today),
            ),
            child: Text(_formatDate(context, _date)),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeField() {
    return InkWell(
      onTap: _selectTime,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Waktu',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          prefixIcon: const Icon(Icons.access_time),
        ),
        child: Text(
          _time.format(context),
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildPickupServiceToggle() {
    return SwitchListTile(
      title: const Text('Layanan Jemput Mobil'),
      subtitle: const Text('Aktifkan untuk menggunakan layanan jemput mobil'),
      value: _isPickupService,
      onChanged: (value) {
        setState(() {
          _isPickupService = value;
          if (value) {
            _estimated += 50000; // Add pickup service fee
          } else {
            _estimated = _estimated > 50000 ? _estimated - 50000 : 0;
          }
        });
      },
      secondary: const Icon(Icons.directions_car),
      activeColor: Theme.of(context).primaryColor,
    );
  }

  Widget _buildEstimatedCostSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Estimasi Biaya:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Rp ${NumberFormat('#,###').format(_estimated)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Theme.of(context).primaryColor,
            inactiveTrackColor: Colors.grey[300],
            thumbColor: Theme.of(context).primaryColor,
            overlayColor: Theme.of(context).primaryColor.withOpacity(0.3),
            valueIndicatorColor: Theme.of(context).primaryColor,
            showValueIndicator: ShowValueIndicator.always,
          ),
          child: Slider(
            value: _estimated,
            min: 100000,
            max: 5000000,
            divisions: 49,
            label: 'Rp ${NumberFormat('#,###').format(_estimated)}',
            onChanged: (value) => setState(() => _estimated = value),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    return TextField(
      controller: _notesController,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: 'Contoh: Ganti oli, periksa rem, dll.',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.all(12),
      ),
    );
  }

  Widget _buildSubmitButton(AsyncValue<User?> authState, String mainCarId) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: authState.when(
        data: (user) {
          if (user == null) {
            return _buildAuthRequiredButton('Silakan login terlebih dahulu');
          }

          if (mainCarId.isEmpty) {
            return _buildAuthRequiredButton('Pilih mobil utama terlebih dahulu');
          }

          return ElevatedButton(
            onPressed: _isSubmitting ? null : _submitBooking,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: _isSubmitting
                ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
                : const Text(
              'Buat Janji Servis',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildAuthRequiredButton('Error: $error'),
      ),
    );
  }

  Widget _buildAuthRequiredButton(String message) {
    return OutlinedButton(
      onPressed: () {
        Navigator.of(context).pushNamed('/login');
      },
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Theme.of(context).primaryColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}