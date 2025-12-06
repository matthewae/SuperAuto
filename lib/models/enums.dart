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

extension ProductCategoryExt on ProductCategory {
  String get nameStr => toString().split('.').last;

  static ProductCategory fromString(String val) {
    return ProductCategory.values
        .firstWhere((e) => e.toString().split('.').last == val);
  }
}
