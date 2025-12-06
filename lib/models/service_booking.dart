// lib/models/service_booking.dart
class ServiceBooking {
  final String id;
  final String userId;
  final String carId;
  final String serviceType;  // Changed from type to serviceType
  final DateTime scheduledAt;
  final double estimatedCost;
  final String status;
  final String? workshop;    // Make workshop nullable
  final String? notes;
  final String? adminNotes;  // Tambah field untuk catatan admin
  final Map<String, dynamic>? statusHistory;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? serviceDetails;
  final String? mechanicName;
  final bool isPickupService;
  final String? serviceLocation;

   ServiceBooking({
    required this.id,
    required this.userId,
    required this.carId,
    required this.serviceType,
    required this.scheduledAt,
    required this.estimatedCost,
    this.status = 'pending',
    this.workshop,
    this.notes,
    this.adminNotes,
    this.statusHistory,
    DateTime? createdAt,
    this.updatedAt,
    this.serviceDetails,
    this.mechanicName,
    this.isPickupService = false,
    this.serviceLocation,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'carId': carId,
      'serviceType': serviceType,
      'workshop': workshop,
      'scheduledAt': scheduledAt.toIso8601String(),
      'estimatedCost': estimatedCost,
      'status': status,
      'notes': notes,
      'adminNotes': adminNotes,
      'statusHistory': statusHistory,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'serviceDetails': serviceDetails,
      'mechanicName': mechanicName,
      'isPickupService': isPickupService ? 1 : 0,
      'serviceLocation': serviceLocation,
    };
  }

  factory ServiceBooking.fromMap(Map<String, dynamic> map) {
    return ServiceBooking(
      id: map['id'] as String,
      userId: map['userId'] as String,
      carId: map['carId'] as String,
      serviceType: map['serviceType'] as String,
      workshop: map['workshop'] as String?,
      scheduledAt: DateTime.parse(map['scheduledAt'] as String),
      estimatedCost: (map['estimatedCost'] as num).toDouble(),
      status: map['status'] as String? ?? 'pending',
      notes: map['notes'] as String?,
      adminNotes: map['adminNotes'] as String?,
      statusHistory: map['statusHistory'] as Map<String, dynamic>?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
      serviceDetails: map['serviceDetails'] as String?,
      mechanicName: map['mechanicName'] as String?,
      isPickupService: (map['isPickupService'] as int?) == 1,
      serviceLocation: map['serviceLocation'] as String?,
    );
  }

  ServiceBooking copyWith({
    String? id,
    String? userId,
    String? carId,
    String? serviceType,
    DateTime? scheduledAt,
    double? estimatedCost,
    String? status,
    String? workshop,
    String? notes,
    String? adminNotes,
    Map<String, dynamic>? statusHistory,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? serviceDetails,
    String? mechanicName,
    bool? isPickupService,
    String? serviceLocation,
  }) {
    return ServiceBooking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      carId: carId ?? this.carId,
      serviceType: serviceType ?? this.serviceType,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      status: status ?? this.status,
      workshop: workshop ?? this.workshop,
      notes: notes ?? this.notes,
      adminNotes: adminNotes ?? this.adminNotes,
      statusHistory: statusHistory ?? this.statusHistory,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      serviceDetails: serviceDetails ?? this.serviceDetails,
      mechanicName: mechanicName ?? this.mechanicName,
      isPickupService: isPickupService ?? this.isPickupService,
      serviceLocation: serviceLocation ?? this.serviceLocation,
    );
  }
}