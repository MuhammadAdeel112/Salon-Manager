import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmployeeDetailsProvider with ChangeNotifier {
  List<QueryDocumentSnapshot> filteredDocs = [];
  List<QueryDocumentSnapshot> adjustmentDocs = [];

  double totalApprovedSales = 0;
  double earnedPayment = 0;
  double pendingComm = 0;

  double totalAdvance = 0;
  double totalDeduction = 0;
  double finalTakeHome = 0;

  bool isProcessing = false;

  void setProcessing(bool value) {
    isProcessing = value;
    notifyListeners();
  }

  Stream<QuerySnapshot> getPayoutStatusStream(String staffName, String monthYear) {
    return FirebaseFirestore.instance
        .collection('payouts')
        .where('staffName', isEqualTo: staffName)
        .where('monthYear', isEqualTo: monthYear)
        .snapshots();
  }

  Future<void> markAsPaid({
    required String staffName,
    required double amount,
    required String monthYear,
  }) async {
    await FirebaseFirestore.instance.collection('payouts').add({
      'staffName': staffName,
      'amount': amount,
      'monthYear': monthYear,
      'paidAt': DateTime.now().toIso8601String(),
      'status': 'Paid',
    });
    notifyListeners();
  }

  Stream<QuerySnapshot> getTransactionsStream(String staffName) {
    return FirebaseFirestore.instance
        .collection('transactions')
        .where('staffName', isEqualTo: staffName)
        .snapshots();
  }

  Stream<QuerySnapshot> getAdjustmentsStream(String staffName) {
    return FirebaseFirestore.instance
        .collection('adjustments')
        .where('staffName', isEqualTo: staffName)
        .snapshots();
  }

  // --- UPDATED: Advance will now also be recorded as a Business Expense ---
  Future<void> addAdjustment({
    required String staffName,
    required double amount,
    required String type,
    required String reason,
  }) async {
    // 1. Employee Ledger (Adjustments Table)
    await FirebaseFirestore.instance.collection('adjustments').add({
      'staffName': staffName.trim(),
      'amount': amount,
      'type': type,
      'reason': reason,
      'date': DateTime.now().toIso8601String(),
      'dateOnly': DateTime.now().toString().split(' ')[0],
    });

    // 2. Logic: If Type is "Advance", also add to "expenses" for Net Profit calculation
    if (type == "Advance") {
      await FirebaseFirestore.instance.collection('expenses').add({
        'amount': amount,
        'description': "Advance: $staffName (${reason.isEmpty ? 'No reason' : reason})",
        'dateOnly': DateTime.now().toString().split(' ')[0],
        'timestamp': FieldValue.serverTimestamp(),
        'category': 'Staff Advance',
      });
    }

    notifyListeners();
  }

  // --- UPDATED LOGIC FOR BOTH SALARY AND COMMISSION ---
  void processTransactions({
    required List<QueryDocumentSnapshot> docs,
    required List<QueryDocumentSnapshot> adjustments,
    required String filterType,
    required String dateFilter,
    required DateTimeRange? customRange,
    required String empType,
    required double baseSalary,
    required double commRate,
  }) {
    filteredDocs = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return false;
      final String docDateStr = (data['dateOnly'] ?? "").toString().trim();
      return _isDateInFilter(docDateStr, filterType, dateFilter, customRange);
    }).toList();

    adjustmentDocs = adjustments.where((doc) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return false;
      final String docDateStr = (data['dateOnly'] ?? "").toString().trim();
      return _isDateInFilter(docDateStr, filterType, dateFilter, customRange);
    }).toList();

    totalApprovedSales = 0;
    earnedPayment = 0;
    pendingComm = 0;
    totalAdvance = 0;
    totalDeduction = 0;

    for (var doc in filteredDocs) {
      var data = doc.data() as Map<String, dynamic>;
      double price = (data['totalPrice'] ?? 0).toDouble();
      String status = (data['status'] ?? "Unapproved").toString();

      if (status == "Approved") {
        totalApprovedSales += price;
        if (empType == "Commission" || empType == "Both") {
          earnedPayment += (price * commRate) / 100;
        }
      } else if (empType == "Commission" || empType == "Both") {
        pendingComm += (price * commRate) / 100;
      }
    }

    if (empType == "Fixed Salary" || empType == "Both") {
      earnedPayment += baseSalary;
    }

    for (var doc in adjustmentDocs) {
      var data = doc.data() as Map<String, dynamic>;
      double amount = (data['amount'] ?? 0).toDouble();
      String type = (data['type'] ?? "Advance").toString();

      if (type == "Advance") {
        totalAdvance += amount;
      } else {
        totalDeduction += amount;
      }
    }

    finalTakeHome = earnedPayment - totalAdvance - totalDeduction;
    notifyListeners();
  }

  bool _isDateInFilter(String? docDateStr, String filterType, String dateFilter, DateTimeRange? customRange) {
    if (docDateStr == null || docDateStr.isEmpty) return false;
    final String cleanDate = docDateStr.trim();
    if (filterType == "Daily") return cleanDate == dateFilter;
    if (filterType == "Monthly") return cleanDate.startsWith(dateFilter);
    if (filterType == "Custom" && customRange != null) {
      DateTime? docDate = _parseDate(cleanDate);
      if (docDate == null) return false;
      DateTime check = DateTime(docDate.year, docDate.month, docDate.day);
      DateTime start = DateTime(customRange.start.year, customRange.start.month, customRange.start.day);
      DateTime end = DateTime(customRange.end.year, customRange.end.month, customRange.end.day);
      return (check.isAtSameMomentAs(start) || check.isAfter(start)) &&
          (check.isAtSameMomentAs(end) || check.isBefore(end));
    }
    return false;
  }

  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      try {
        List<String> p = dateStr.split('-');
        if (p.length == 3) return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
      } catch (_) { return null; }
      return null;
    }
  }
}