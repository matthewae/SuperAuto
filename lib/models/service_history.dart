import 'dart:convert';
import 'package:superauto/models/service_booking.dart';

class ServiceHistoryItem {
  final String id;
  final String userId;
  final String carId;
  final DateTime date;
  final int km;
  final List<String> jobs;
  final List<String> parts;
  final double totalCost;
  final String? serviceType;
  final String? notes;
  final DateTime? createdAt;

  const ServiceHistoryItem({
    required this.id,
    required this.userId,
    required this.carId,
    required this.date,
    required this.km,
    required this.jobs,
    required this.parts,
    required this.totalCost,
    this.serviceType,
    this.notes,
    this.createdAt,
  });

  factory ServiceHistoryItem.fromServiceBooking(
      ServiceBooking booking, {
        required List<String> jobs,
        required List<String> parts,
        required double totalCost,
        int? km,
      }) {
    return ServiceHistoryItem(
      id: booking.id,
      userId: booking.userId,
      carId: booking.carId,
      date: booking.scheduledAt,
      km: km ?? 0,
      jobs: jobs,
      parts: parts,
      totalCost: totalCost,
      serviceType: booking.serviceType,
      notes: booking.notes,
      createdAt: DateTime.now(),
    );
  }

  // Add toMap and fromJson if needed
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'carId': carId,
      'date': date.toIso8601String(),
      'km': km,
      'jobs': jsonEncode(jobs),
      'parts': jsonEncode(parts),
      'totalCost': totalCost,
      'serviceType': serviceType,
      'notes': notes,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory ServiceHistoryItem.fromMap(Map<String, dynamic> map) {
    return ServiceHistoryItem(
      id: map['id'] as String,
      userId: map['userId'] as String,
      carId: map['carId'] as String,
      date: DateTime.parse(map['date'] as String),
      km: map['km'] as int,
      jobs: List<String>.from(jsonDecode(map['jobs'] as String)),
      parts: List<String>.from(jsonDecode(map['parts'] as String)),
      totalCost: (map['totalCost'] as num).toDouble(),
      serviceType: map['serviceType'] as String?,
      notes: map['notes'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
    );
  }
}