class SalonTransaction {
  final String id;
  final String employeeName;
  final List<String> services;
  final int totalAmount;
  final DateTime date;
  final String type; // 'service' ya 'expense'

  SalonTransaction({
    required this.id,
    required this.employeeName,
    required this.services,
    required this.totalAmount,
    required this.date,
    this.type = 'service',
  });

  // Data ko Firebase mein bhejne ke liye Map mein badalna
  Map<String, dynamic> toMap() {
    return {
      'employeeName': employeeName,
      'services': services,
      'totalAmount': totalAmount,
      'date': date.toIso8601String(),
      'type': type,
    };
  }
}