import 'dart:convert';
class ServiceBooking {
  final String id;
  final String userId;
  final String carId;
  final String serviceType;
  final DateTime scheduledAt;
  final double estimatedCost;
  final String status;
  final String? workshop;
  final String? notes;
  final String? adminNotes;
  final Map<String, dynamic>? statusHistory;
  final List<String> jobs;
  final List<String> parts;
  final int? km;
  final double? totalCost;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? serviceDetails;
  final String? mechanicName;
  final bool isPickupService;
  final String? serviceLocation;
  final String? promoId;

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
    this.jobs = const [],
    this.parts = const [],
    this.km,
    this.totalCost,
    DateTime? createdAt,
    this.updatedAt,
    this.serviceDetails,
    this.mechanicName,
    this.isPickupService = false,
    this.serviceLocation,
    this.promoId,
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
      'statusHistory': statusHistory != null ? jsonEncode(statusHistory) : null,
      'jobs': jsonEncode(jobs),
      'parts': jsonEncode(parts),
      'km': km,
      'totalCost': totalCost,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'serviceDetails': serviceDetails,
      'mechanicName': mechanicName,
      'isPickupService': isPickupService ? 1 : 0,
      'serviceLocation': serviceLocation,
      'promoId': promoId,
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
      statusHistory: map['statusHistory'] != null
          ? Map<String, dynamic>.from(jsonDecode(map['statusHistory']))
          : null,
      jobs: map['jobs'] != null
          ? List<String>.from(jsonDecode(map['jobs']))
          : [],
      parts: map['parts'] != null
          ? List<String>.from(jsonDecode(map['parts']))
          : [],
      km: map['km'] != null ? map['km'] as int : null,
      totalCost: map['totalCost']?.toDouble(),
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
      promoId: map['promoId'] as String?,
    );
  }

  ServiceBooking copyWith({
    String? id,
    String? userId,
    String? carId,
    String? serviceType,
    String? workshop,
    DateTime? scheduledAt,
    String? status,
    double? estimatedCost,
    String? notes,
    String? adminNotes,
    Map<String, dynamic>? statusHistory,
    List<String>? jobs,
    List<String>? parts,
    int? km,
    double? totalCost,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? serviceDetails,
    String? mechanicName,
    bool? isPickupService,
    String? serviceLocation,
    String? promoId,
  }) {
    return ServiceBooking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      carId: carId ?? this.carId,
      serviceType: serviceType ?? this.serviceType,
      workshop: workshop ?? this.workshop,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      status: status ?? this.status,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      notes: notes ?? this.notes,
      adminNotes: adminNotes ?? this.adminNotes,
      statusHistory: statusHistory ?? this.statusHistory,
      jobs: jobs ?? this.jobs,
      parts: parts ?? this.parts,
      km: km ?? this.km,
      totalCost: totalCost ?? this.totalCost,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      serviceDetails: serviceDetails ?? this.serviceDetails,
      mechanicName: mechanicName ?? this.mechanicName,
      isPickupService: isPickupService ?? this.isPickupService,
      serviceLocation: serviceLocation ?? this.serviceLocation,
      promoId: promoId ?? this.promoId,
    );
  }
}