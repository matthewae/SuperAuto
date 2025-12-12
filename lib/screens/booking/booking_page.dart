import 'package:getwidget/getwidget.dart';
import 'package:collection/collection.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../../models/enums.dart';
import '../../models/service_booking.dart';
import '../../models/promo.dart';
import '../../providers/app_providers.dart';
import '../../services/notification_service.dart';

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
  late TimeOfDay _time;
  ServiceType _type = ServiceType.routine;
  DateTime _date = DateTime.now().add(const Duration(days: 1));

  final TextEditingController _workshopController = TextEditingController(text: 'Bengkel Utama');
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _promoCodeController = TextEditingController();

  double _estimated = 500000;
  String? _selectedCarId;
  String? _selectedPromoId;
  double _discount = 0.0;
  double _finalCost = 500000;
  bool _showPromoSection = false;

  bool _isSubmitting = false;
  final _uuid = const Uuid();

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Initialize _time to next hour
    final now = TimeOfDay.now();
    _time = TimeOfDay(hour: now.hour, minute: 0);
    _time = _time.add(hours: 1);

    final userCars = ref.read(carsProvider);
    _selectedCarId = userCars.firstWhereOrNull((car) => car.isMain)?.id;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_isInitialized) {
      // Pre-fill notes if returning from a previous booking attempt
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is Map) {
        final Map<String, dynamic> argsMap = args as Map<String, dynamic>;
        if (argsMap['notes'] != null) {
          _notesController.text = argsMap['notes'] as String;
        }
      }
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _workshopController.dispose();
    _notesController.dispose();
    _promoCodeController.dispose();
    super.dispose();
  }

  // Calculate final cost based on selected promo
  Future<void> _calculateFinalCost() async {
    if (_selectedPromoId != null) {
      try {
        final promo = await ref.read(promoDaoProvider).getById(_selectedPromoId!);
        if (promo != null && promo.isActive()) {
          _discount = promo.calculateDiscount(_estimated);
        } else {
          _discount = 0.0;
        }
      } catch (e) {
        print('Error calculating discount: $e');
        _discount = 0.0;
      }
    } else {
      _discount = 0.0;
    }

    setState(() {
      _finalCost = _estimated - _discount;
    });
  }

  // Apply promo code
  Future<void> _applyPromoCode() async {
    final promoCode = _promoCodeController.text.trim();
    if (promoCode.isEmpty) return;

    try {
      final promos = await ref.read(promosProvider.notifier).getActivePromosByType('service_discount');
      final matchingPromo = promos.firstWhere(
            (promo) => promo.name.toLowerCase() == promoCode.toLowerCase(),
        orElse: () => Promo(
          id: '',
          name: '',
          type: '',
          value: 0,
          start: DateTime.now(),
          end: DateTime.now(),
          createdAt: DateTime.now(),
        ),
      );

      if (matchingPromo.id.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kode promo tidak valid')),
        );
        return;
      }

      setState(() {
        _selectedPromoId = matchingPromo.id;
        _promoCodeController.clear();
      });

      await _calculateFinalCost();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Promo ${matchingPromo.name} berhasil diterapkan')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;

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

      // Find selected car
      final selectedCar = userCars.firstWhere(
            (car) => car.id == _selectedCarId,
        orElse: () => throw Exception('Mobil tidak ditemukan'),
      );

      final scheduled = DateTime(
          _date.year, _date.month, _date.day, _time.hour, _time.minute
      );

      final booking = ServiceBooking(
        id: _uuid.v4(),
        userId: user.idString,
        carId: selectedCar.id,
        serviceType: _type.toString().split('.').last,
        scheduledAt: scheduled,
        estimatedCost: _estimated,
        notes: _notesController.text,
        status: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        promoId: _selectedPromoId,
      );

      // Save booking
      ref.read(bookingsProvider.notifier).add(booking);

      // Schedule notification
      NotificationService().scheduleServiceReminder(
        id: booking.hashCode,
        title: 'Pengingat Servis',
        body: 'Jadwal servis besok di ${booking.workshop}',
        when: scheduled.subtract(const Duration(days: 1)),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking berhasil dibuat')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuat booking: $e')),
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
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: user == null
          ? const Center(child: Text('Silakan login terlebih dahulu'))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

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
                            ))
                            .toList(),
                        onChanged: (v) {
                          setState(() {
                            _selectedCarId = v;
                          });
                        },
                      ),
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Anda belum menambahkan mobil. Silakan tambahkan mobil terlebih dahulu.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),

              const SizedBox(height: 8),

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
                        setState(() {
                          _type = v ?? _type;
                          // Update estimated cost based on service type
                          switch (_type) {
                            case ServiceType.routine:
                              _estimated = 500000.0;
                              break;
                            case ServiceType.major:
                              _estimated = 1000000.0;
                              break;
                            case ServiceType.partReplacement:
                              _estimated = 750000.0;
                              break;
                          }
                          _calculateFinalCost();
                        });
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

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
                  onPressed: _selectTime,
                  text: 'Jam: ${_time.format(context)}',
                  icon: const Icon(Icons.schedule),
                  blockButton: true,
                  type: GFButtonType.transparent,
                ),
              ),

              const SizedBox(height: 8),

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
                        onChanged: (v) {
                          setState(() {
                            _estimated = v;
                          });
                          _calculateFinalCost();
                        },
                        min: 100000,
                        max: 5000000,
                        divisions: 49,
                        label: _estimated.toStringAsFixed(0),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // ---------------------------------------
              // PROMO SECTION
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
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Promo',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _showPromoSection = !_showPromoSection;
                              });
                            },
                            child: Text(_showPromoSection ? 'Sembunyikan' : 'Pilih Promo'),
                          ),
                        ],
                      ),
                      if (_showPromoSection) ...[
                        const SizedBox(height: 8),
                        // Promo Code Input
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _promoCodeController,
                                decoration: const InputDecoration(
                                  labelText: 'Kode Promo',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _applyPromoCode,
                              child: const Text('Gunakan'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Available Promos
                        FutureBuilder<List<Promo>>(
                          future: ref.read(promosProvider.notifier).getActivePromosByType('service_discount'),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            if (snapshot.hasError || !snapshot.hasData) {
                              return const Text('Tidak ada promo tersedia');
                            }

                            final promos = snapshot.data!;
                            if (promos.isEmpty) {
                              return const Text('Tidak ada promo tersedia');
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Promo Tersedia:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                ...promos.map((promo) {
                                  final isSelected = _selectedPromoId == promo.id;
                                  return InkWell(
                                    onTap: () async {
                                      setState(() {
                                        _selectedPromoId = isSelected ? null : promo.id;
                                      });
                                      await _calculateFinalCost();
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      margin: const EdgeInsets.only(bottom: 8),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: isSelected
                                              ? Theme.of(context).primaryColor
                                              : Colors.grey.shade300,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        color: isSelected
                                            ? Theme.of(context).primaryColor.withOpacity(0.1)
                                            : null,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            isSelected
                                                ? Icons.radio_button_checked
                                                : Icons.radio_button_unchecked,
                                            color: isSelected
                                                ? Theme.of(context).primaryColor
                                                : null,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  promo.name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  'Berlaku hingga ${DateFormat('dd MMM yyyy').format(promo.end)}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            promo.formattedValue,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ],
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Estimasi Biaya',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('Rp ${_estimated.toStringAsFixed(0)}'),
                        ],
                      ),
                      if (_discount > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Diskon',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '-Rp ${_discount.toStringAsFixed(0)}',
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ],
                      const Divider(),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Biaya',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Rp ${_finalCost.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

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
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Catatan (Opsional)',
                      border: InputBorder.none,
                      hintText: 'Permintaan khusus atau informasi tambahan',
                    ),
                    maxLines: 3,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              GFButton(
                onPressed: _isSubmitting ? null : _submitBooking,
                icon: const Icon(Icons.book_online),
                text: _isSubmitting
                    ? 'Memproses...'
                    : 'Booking',
                color: const Color(0xFF1E88E5),
                textColor: Colors.white,
                size: GFSize.LARGE,
                fullWidthButton: true,
                shape: GFButtonShape.pills,
              ),
            ],
          ),
        ),
      ),
    );
  }
}