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

  // ══════════════════════════════════════════════════════════════════
  // Previous Month Payroll Data
  // ══════════════════════════════════════════════════════════════════
  double prevMonthTotalSales = 0;
  double prevMonthCommission = 0;
  double prevMonthBaseSalary = 0;
  double prevMonthAdvance = 0;
  double prevMonthDeduction = 0;
  double prevMonthFinalPay = 0;
  bool isPrevMonthLoaded = false;

  // ✅ NEW: Error state — agar fetch fail ho
  bool isPrevMonthError = false;

  // Payment Status
  bool isPaidThisMonth = false;
  String paidAmount = "0";
  String paidMethod = "";

  void setProcessing(bool value) {
    isProcessing = value;
    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════════════
  // Check payment status
  // ══════════════════════════════════════════════════════════════════
  Future<void> checkPaymentStatus(
      String staffName, String monthYear) async {
    try {
      final result = await FirebaseFirestore.instance
          .collection('payouts')
          .where('staffName', isEqualTo: staffName.trim())
          .where('monthYear', isEqualTo: monthYear)
          .get();

      if (result.docs.isNotEmpty) {
        final data = result.docs.first.data();
        isPaidThisMonth = true;
        paidAmount = (data['amount'] ?? 0).toString();
        paidMethod = (data['paymentMethod'] ?? 'Cash').toString();
      } else {
        isPaidThisMonth = false;
        paidAmount = "0";
        paidMethod = "";
      }
      notifyListeners();
    } catch (e) {
      print("Error checking payment status: $e");
    }
  }

  // ══════════════════════════════════════════════════════════════════
  // ✅ FIXED: calculatePreviousMonthPayroll
  //
  // Masla kya tha:
  //   - notifyListeners() dialog ke Consumer ko properly rebuild
  //     nahi kar raha tha
  //   - Agar Firestore slow hoti toh isPrevMonthLoaded kabhi true
  //     nahi hota tha — infinite spinner
  //
  // Fix kya kiya:
  //   - Ab yeh Future<bool> return karta hai
  //   - Timeout add kiya (10 seconds)
  //   - Error state alag se track hoti hai
  //   - Dialog mein Consumer hataya — ab FutureBuilder use hoga
  //     (Screen file mein change hoga)
  // ══════════════════════════════════════════════════════════════════
  Future<bool> calculatePreviousMonthPayroll({
    required String staffName,
    required String empType,
    required double baseSalary,
    required double commRate,
  }) async {
    final DateTime now = DateTime.now();
    final DateTime firstOfCurrentMonth = DateTime(now.year, now.month, 1);
    final DateTime lastDayOfPrevMonth =
    firstOfCurrentMonth.subtract(const Duration(days: 1));

    final String prevMonthStr =
        "${lastDayOfPrevMonth.year}-${lastDayOfPrevMonth.month.toString().padLeft(2, '0')}";

    // Reset state
    prevMonthTotalSales = 0;
    prevMonthCommission = 0;
    prevMonthBaseSalary = 0;
    prevMonthAdvance = 0;
    prevMonthDeduction = 0;
    prevMonthFinalPay = 0;
    isPrevMonthLoaded = false;
    isPrevMonthError = false;

    try {
      // ✅ Timeout: 10 seconds mein jawab nahi aaya toh error
      final results = await Future.wait([
        FirebaseFirestore.instance
            .collection('transactions')
            .where('staffName', isEqualTo: staffName.trim())
            .get(),
        FirebaseFirestore.instance
            .collection('adjustments')
            .where('staffName', isEqualTo: staffName.trim())
            .get(),
      ]).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception("Firestore timeout"),
      );

      final transSnap = results[0];
      final adjSnap = results[1];

      // ── Transactions ──
      for (var doc in transSnap.docs) {
        final data = doc.data();
        final String dateOnly = (data['dateOnly'] ?? "").toString().trim();
        final String status = (data['status'] ?? "").toString();

        if (dateOnly.startsWith(prevMonthStr) && status == "Approved") {
          final double price = (data['totalPrice'] ?? 0).toDouble();
          prevMonthTotalSales += price;
          if (empType == "Commission" || empType == "Both") {
            prevMonthCommission += (price * commRate) / 100;
          }
        }
      }

      // ── Base Salary ──
      if (empType == "Fixed Salary" || empType == "Both") {
        prevMonthBaseSalary = baseSalary;
      }

      // ── Adjustments ──
      for (var doc in adjSnap.docs) {
        final data = doc.data();
        final String dateOnly = (data['dateOnly'] ?? "").toString().trim();
        final String type = (data['type'] ?? "Advance").toString();

        if (dateOnly.startsWith(prevMonthStr)) {
          final double amount = (data['amount'] ?? 0).toDouble();
          if (type == "Advance") {
            prevMonthAdvance += amount;
          } else {
            prevMonthDeduction += amount;
          }
        }
      }

      // ── Final Pay ──
      prevMonthFinalPay = prevMonthBaseSalary +
          prevMonthCommission -
          prevMonthAdvance -
          prevMonthDeduction;

      isPrevMonthLoaded = true;
      isPrevMonthError = false;
      notifyListeners();
      return true; // ✅ Success

    } catch (e) {
      print("Error calculating previous month payroll: $e");
      isPrevMonthLoaded = false;
      isPrevMonthError = true;
      notifyListeners();
      return false; // ❌ Failed
    }
  }

  // ══════════════════════════════════════════════════════════════════
  // markAsPaid
  // ══════════════════════════════════════════════════════════════════
  Future<void> markAsPaid({
    required String staffName,
    required double amount,
    required String monthYear,
  }) async {
    final String staffNameTrimmed = staffName.trim();

    final existing = await FirebaseFirestore.instance
        .collection('payouts')
        .where('staffName', isEqualTo: staffNameTrimmed)
        .where('monthYear', isEqualTo: monthYear)
        .get();

    if (existing.docs.isEmpty) {
      await FirebaseFirestore.instance.collection('payouts').add({
        'staffName': staffNameTrimmed,
        'amount': amount,
        'monthYear': monthYear,
        'paidAt': Timestamp.now(),
        'status': 'Paid',
      });
    }

    await FirebaseFirestore.instance.collection('employee_history').add({
      'employeeName': staffNameTrimmed,
      'amount': amount,
      'monthYear': monthYear,
      'date': Timestamp.now(),
      'status': 'Paid',
      'type': 'Salary',
    });

    isPaidThisMonth = true;
    paidAmount = amount.toStringAsFixed(0);
    isPrevMonthLoaded = false;
    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════════════
  // Transactions Stream
  // ══════════════════════════════════════════════════════════════════
  Stream<QuerySnapshot> getTransactionsStream(String staffName) {
    return FirebaseFirestore.instance
        .collection('transactions')
        .where('staffName', isEqualTo: staffName)
        .snapshots();
  }

  // ══════════════════════════════════════════════════════════════════
  // Adjustments Stream
  // ══════════════════════════════════════════════════════════════════
  Stream<QuerySnapshot> getAdjustmentsStream(String staffName) {
    return FirebaseFirestore.instance
        .collection('adjustments')
        .where('staffName', isEqualTo: staffName)
        .snapshots();
  }

  // ══════════════════════════════════════════════════════════════════
  // Add Adjustment
  // ══════════════════════════════════════════════════════════════════
  Future<void> addAdjustment({
    required String staffName,
    required double amount,
    required String type,
    required String reason,
  }) async {
    final String today = DateTime.now().toString().split(' ')[0];

    await FirebaseFirestore.instance.collection('adjustments').add({
      'staffName': staffName.trim(),
      'amount': amount,
      'type': type,
      'reason': reason,
      'date': DateTime.now().toIso8601String(),
      'dateOnly': today,
    });

    if (type == "Advance") {
      await FirebaseFirestore.instance.collection('expenses').add({
        'amount': amount,
        'description':
        "Advance: ${staffName.trim()} (${reason.isEmpty ? 'No reason' : reason})",
        'dateOnly': today,
        'accountingDateOnly': today,
        'timestamp': FieldValue.serverTimestamp(),
        'category': 'Staff Advance',
      });
    }

    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════════════
  // processTransactions
  // ══════════════════════════════════════════════════════════════════
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
    filteredDocs = [];
    adjustmentDocs = [];
    totalApprovedSales = 0;
    earnedPayment = 0;
    pendingComm = 0;
    totalAdvance = 0;
    totalDeduction = 0;

    filteredDocs = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final String docDateStr = (data['dateOnly'] ?? "").toString().trim();
      return _isDateInFilter(docDateStr, filterType, dateFilter, customRange);
    }).toList();

    adjustmentDocs = adjustments.where((doc) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final String docDateStr = (data['dateOnly'] ?? "").toString().trim();
      return _isDateInFilter(docDateStr, filterType, dateFilter, customRange);
    }).toList();

    double commissionEarned = 0.0;

    for (var doc in filteredDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final double price = (data['totalPrice'] ?? 0).toDouble();
      final String status = (data['status'] ?? "Unapproved").toString();

      if (status == "Approved") {
        totalApprovedSales += price;
        if (empType == "Commission" || empType == "Both") {
          commissionEarned += (price * commRate) / 100;
        }
      } else if (empType == "Commission" || empType == "Both") {
        pendingComm += (price * commRate) / 100;
      }
    }

    if (empType == "Fixed Salary" || empType == "Both") {
      earnedPayment = baseSalary + commissionEarned;
    } else {
      earnedPayment = commissionEarned;
    }

    for (var doc in adjustmentDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final double amount = (data['amount'] ?? 0).toDouble();
      final String type = (data['type'] ?? "Advance").toString();

      if (type == "Advance") {
        totalAdvance += amount;
      } else {
        totalDeduction += amount;
      }
    }

    finalTakeHome = earnedPayment - totalAdvance - totalDeduction;
    notifyListeners();
  }

  bool _isDateInFilter(String? docDateStr, String filterType,
      String dateFilter, DateTimeRange? customRange) {
    if (docDateStr == null || docDateStr.isEmpty) return false;
    final String cleanDate = docDateStr.trim();

    if (filterType == "Daily") return cleanDate == dateFilter;
    if (filterType == "Monthly") return cleanDate.startsWith(dateFilter);
    if (filterType == "Custom" && customRange != null) {
      DateTime? docDate = _parseDate(cleanDate);
      if (docDate == null) return false;
      DateTime check = DateTime(docDate.year, docDate.month, docDate.day);
      DateTime start = DateTime(customRange.start.year,
          customRange.start.month, customRange.start.day);
      DateTime end = DateTime(
          customRange.end.year, customRange.end.month, customRange.end.day);
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
        if (p.length == 3) {
          return DateTime(
              int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
        }
      } catch (_) {
        return null;
      }
      return null;
    }
  }
}