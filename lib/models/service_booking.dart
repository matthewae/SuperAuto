import 'enums.dart';

class ServiceBooking {
  final String id;
  final String userId;
  final String carId;
  final ServiceType type;
  final String workshop;
  final DateTime scheduledAt;
  final double estimatedCost;
  ServiceStatus status;

  ServiceBooking({
    required this.id,
    required this.userId,
    required this.carId,
    required this.type,
    required this.workshop,
    required this.scheduledAt,
    required this.estimatedCost,
    this.status = ServiceStatus.booking,
  });
}

