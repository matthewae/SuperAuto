class ServiceHistoryItem {
  final String id;
  final String userId;
  final String carId;
  final DateTime date;
  final int km;
  final List<String> jobs;
  final List<String> parts;
  final double totalCost;

  const ServiceHistoryItem({
    required this.id,
    required this.userId,
    required this.carId,
    required this.date,
    required this.km,
    required this.jobs,
    required this.parts,
    required this.totalCost,
  });
}

