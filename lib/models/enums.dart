import 'package:flutter/material.dart';

enum ServiceStatus {
  booking,
  waiting,
  inProgress,
  waitingForParts,
  finalCheck,
  done,
}

extension ServiceStatusExt on ServiceStatus {
  String get nameStr => toString().split('.').last;

  static ServiceStatus fromString(String val) {
    return ServiceStatus.values
        .firstWhere((e) => e.toString().split('.').last == val);
  }
}

enum BookingFilter {
  all,
  active,
  completed,
  cancelled,
}

enum BookingStatus {
  pending('Menunggu Konfirmasi'),
  confirmed('Dikonfirmasi'),
  inProgress('Sedang Dikerjakan'),
  waitingParts('Menunggu Part'),
  waitingPayment('Menunggu Pembayaran'),
  readyForPickup('Siap Diambil'),
  completed('Selesai'),
  cancelled('Dibatalkan');

  final String displayName;
  const BookingStatus(this.displayName);

  // Get next possible statuses based on current status
  static List<BookingStatus> getNextPossibleStatuses(BookingStatus current) {
    switch (current) {
      case BookingStatus.pending:
        return [
          BookingStatus.confirmed,
          BookingStatus.cancelled,
        ];
      case BookingStatus.confirmed:
        return [
          BookingStatus.inProgress,
          BookingStatus.waitingParts,
          BookingStatus.cancelled,
        ];
      case BookingStatus.inProgress:
        return [
          BookingStatus.waitingParts,
          BookingStatus.waitingPayment,
          BookingStatus.readyForPickup,
          BookingStatus.completed,
          BookingStatus.cancelled,
        ];
      case BookingStatus.waitingParts:
        return [
          BookingStatus.inProgress,
          BookingStatus.waitingPayment,
          BookingStatus.readyForPickup,
          BookingStatus.completed,
          BookingStatus.cancelled,
        ];
      case BookingStatus.waitingPayment:
        return [
          BookingStatus.readyForPickup,
          BookingStatus.completed,
          BookingStatus.cancelled,
        ];
      case BookingStatus.readyForPickup:
        return [
          BookingStatus.completed,
          BookingStatus.cancelled,
        ];
      case BookingStatus.completed:
      case BookingStatus.cancelled:
        return []; // No further status changes allowed
    }
  }

  // Get display names for dropdown
  static List<DropdownMenuItem<BookingStatus>> getStatusDropdownItems(BookingStatus currentStatus) {
    final possibleStatuses = getNextPossibleStatuses(currentStatus);
    return possibleStatuses
        .map((status) => DropdownMenuItem<BookingStatus>(
      value: status,
      child: Text(status.displayName),
    ))
        .toList();
  }
}
enum ServiceType {
  routine,
  major,
  partReplacement,
}

extension ServiceTypeExt on ServiceType {
  String get nameStr => toString().split('.').last;

  static ServiceType fromString(String val) {
    return ServiceType.values
        .firstWhere((e) => e.toString().split('.').last == val);
  }
}

enum ProductCategory {
  oil,
  fluids,
  engineParts,
  brakes,
  tiresWheels,
  interiorAccessories,
  exteriorAccessories,
  electronics, accessories,
}
enum OrderFilter {
  pending,
  processing,
  shipped,
  delivered,
  cancelled,
}

enum OrderStatus {
  pending('Menunggu Konfirmasi'),
  processing('Diproses'),
  shipped('Dikirim'),
  delivered('Terkirim'),
  cancelled('Dibatalkan');

  final String displayName;
  const OrderStatus(this.displayName);

  String get name => toString().split('.').last;

  // Check if the status can be changed
  bool get isFinalStatus => this == OrderStatus.delivered || this == OrderStatus.cancelled;

  // Get next possible statuses based on current status
  static List<OrderStatus> getNextPossibleStatuses(OrderStatus current) {
    if (current.isFinalStatus) {
      return []; // No further status changes allowed for final statuses
    }

    switch (current) {
      case OrderStatus.pending:
        return [OrderStatus.processing, OrderStatus.cancelled];
      case OrderStatus.processing:
        return [OrderStatus.shipped, OrderStatus.cancelled];
      case OrderStatus.shipped:
        return [OrderStatus.delivered];
      case OrderStatus.delivered:
      case OrderStatus.cancelled:
        return []; // These are final statuses
    }
  }

  // Get display names for dropdown
  static List<DropdownMenuItem<OrderStatus>> getStatusDropdownItems(OrderStatus currentStatus) {
    final possibleStatuses = getNextPossibleStatuses(currentStatus);
    return possibleStatuses
        .map((status) => DropdownMenuItem<OrderStatus>(
      value: status,
      child: Text(status.displayName),
    ))
        .toList();
  }

  // Convert from string
  static OrderStatus fromString(String val) {
    return OrderStatus.values
        .firstWhere((e) => e.name == val, orElse: () => OrderStatus.pending);
  }
}



extension ProductCategoryExt on ProductCategory {
  String get nameStr => toString().split('.').last;

  static ProductCategory fromString(String val) {
    return ProductCategory.values
        .firstWhere((e) => e.toString().split('.').last == val);
  }



}
