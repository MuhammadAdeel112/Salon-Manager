import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class AdminProvider extends ChangeNotifier {
  List<DocumentSnapshot> _transactions = [];
  List<DocumentSnapshot> _expenses = [];
  List<DocumentSnapshot> _employees = [];

  List<DocumentSnapshot> get transactions => _transactions;
  List<DocumentSnapshot> get expenses => _expenses;
  List<DocumentSnapshot> get employees => _employees;

  StreamSubscription<QuerySnapshot>? _transactionsSubscription;
  StreamSubscription<QuerySnapshot>? _expensesSubscription;
  StreamSubscription<QuerySnapshot>? _employeesSubscription;

  // ══════════════════════════════════════════════════════════════════
  // Firebase Listeners
  // ══════════════════════════════════════════════════════════════════
  void startListening() {
    _cancelAllListeners();

    _transactionsSubscription = FirebaseFirestore.instance
        .collection('transactions')
        .snapshots()
        .listen((snapshot) {
      _transactions = snapshot.docs;
      notifyListeners();
    });

    _expensesSubscription = FirebaseFirestore.instance
        .collection('expenses')
        .snapshots()
        .listen((snapshot) {
      _expenses = snapshot.docs;
      notifyListeners();
    });

    _employeesSubscription = FirebaseFirestore.instance
        .collection('employees')
        .snapshots()
        .listen((snapshot) {
      _employees = snapshot.docs;
      notifyListeners();
    });
  }

  void disposeListeners() {
    _cancelAllListeners();
    notifyListeners();
  }

  void _cancelAllListeners() {
    _transactionsSubscription?.cancel();
    _expensesSubscription?.cancel();
    _employeesSubscription?.cancel();

    _transactionsSubscription = null;
    _expensesSubscription = null;
    _employeesSubscription = null;
  }

  // ══════════════════════════════════════════════════════════════════
  // Dashboard Totals Calculation
  // ══════════════════════════════════════════════════════════════════
  Map<String, double> calculateTotals(String selectedFilter, String todayDate,
      String currentMonthStr, DateTimeRange? customRange) {
    double sales = 0;
    double expense = 0;

    bool checkInclusion(String docDate) {
      if (docDate.isEmpty) return false;
      String cleanDate = docDate.trim();

      if (selectedFilter == "Daily") return cleanDate == todayDate;
      if (selectedFilter == "Monthly")
        return cleanDate.startsWith(currentMonthStr);
      if (selectedFilter == "Custom" && customRange != null) {
        try {
          DateTime dt = DateTime.parse(cleanDate);
          DateTime check = DateTime(dt.year, dt.month, dt.day);
          DateTime start = DateTime(customRange.start.year,
              customRange.start.month, customRange.start.day);
          DateTime end = DateTime(customRange.end.year,
              customRange.end.month, customRange.end.day);
          return (check.isAtSameMomentAs(start) || check.isAfter(start)) &&
              (check.isAtSameMomentAs(end) || check.isBefore(end));
        } catch (e) {
          return false;
        }
      }
      return false;
    }

    for (var doc in _transactions) {
      var data = doc.data() as Map<String, dynamic>;
      if (checkInclusion(data['dateOnly'] ?? "") &&
          (data['status'] ?? "") == "Approved") {
        sales += (data['totalPrice'] ?? 0).toDouble();
      }
    }

    for (var doc in _expenses) {
      var data = doc.data() as Map<String, dynamic>;
      String dateToCheck = "";
      if ((data['category'] ?? "") == "Salary") {
        dateToCheck = data['accountingDateOnly'] ?? data['dateOnly'] ?? "";
      } else {
        dateToCheck = data['dateOnly'] ?? "";
      }
      if (checkInclusion(dateToCheck)) {
        expense += (data['amount'] ?? 0).toDouble();
      }
    }

    return {"sales": sales, "expenses": expense, "profit": sales - expense};
  }

  // ══════════════════════════════════════════════════════════════════
  // ✅ HELPER: Previous Month ki last date string
  // ══════════════════════════════════════════════════════════════════
  String getPreviousMonthAccountingDate(DateTime paymentDate) {
    DateTime firstOfCurrentMonth =
    DateTime(paymentDate.year, paymentDate.month, 1);
    DateTime lastDayOfPreviousMonth =
    firstOfCurrentMonth.subtract(const Duration(days: 1));
    return "${lastDayOfPreviousMonth.year}-"
        "${lastDayOfPreviousMonth.month.toString().padLeft(2, '0')}-"
        "${lastDayOfPreviousMonth.day.toString().padLeft(2, '0')}";
  }

  // ══════════════════════════════════════════════════════════════════
  // ✅ HELPER: Previous Month ka monthYear string
  // ══════════════════════════════════════════════════════════════════
  String getPreviousMonthYear(DateTime paymentDate) {
    DateTime firstOfCurrentMonth =
    DateTime(paymentDate.year, paymentDate.month, 1);
    DateTime lastDayOfPreviousMonth =
    firstOfCurrentMonth.subtract(const Duration(days: 1));
    return "${lastDayOfPreviousMonth.year}-"
        "${lastDayOfPreviousMonth.month.toString().padLeft(2, '0')}";
  }

  // ══════════════════════════════════════════════════════════════════
  // ✅ NEW: Check karo kya is employee ko is month salary PAID ho chuki hai
  // Lock nahi — sirf payouts collection check hota hai
  // ══════════════════════════════════════════════════════════════════
  Future<bool> isSalaryPaidThisMonth(String employeeName) async {
    final String monthYear = getPreviousMonthYear(DateTime.now());
    final result = await FirebaseFirestore.instance
        .collection('payouts')
        .where('staffName', isEqualTo: employeeName.trim())
        .where('monthYear', isEqualTo: monthYear)
        .get();
    return result.docs.isNotEmpty;
  }

  // ══════════════════════════════════════════════════════════════════
  // ✅ REMOVED: isSalaryLocked() — ab lock system nahi hai
  // Replace: isSalaryPaidThisMonth() use karo
  // ══════════════════════════════════════════════════════════════════

  // ══════════════════════════════════════════════════════════════════
  // ✅ UPDATED: Mark Salary as Paid
  // Lock nahi lagta — sirf payouts mein record save hota hai
  // ══════════════════════════════════════════════════════════════════
  Future<void> markSalaryAsPaid({
    required String employeeId,
    required String employeeName,
    required double salaryAmount,
    required String paymentMethod,
    required String transactionRef,
    required String monthYear,
  }) async {
    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();
      DateTime now = DateTime.now();

      String actualDateOnly =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      String accountingDateOnly = getPreviousMonthAccountingDate(now);
      String accountingMonthYear = getPreviousMonthYear(now);

      // ── 1. EXPENSE register karo ──
      DocumentReference expenseRef =
      FirebaseFirestore.instance.collection('expenses').doc();
      batch.set(expenseRef, {
        'amount': salaryAmount,
        'category': "Salary",
        'description':
        "Monthly Salary paid to $employeeName via $paymentMethod",
        'timestamp': Timestamp.now(),
        'dateOnly': actualDateOnly,
        'accountingDateOnly': accountingDateOnly,
        'accountingMonthYear': accountingMonthYear,
        'staffId': employeeId,
        'paymentMethod': paymentMethod,
        'transactionRef': transactionRef,
        'monthYear': monthYear,
      });

      // ── 2. PAYOUT log karo ──
      DocumentReference payoutRef =
      FirebaseFirestore.instance.collection('payouts').doc();
      batch.set(payoutRef, {
        'employeeId': employeeId,
        'staffName': employeeName.trim(),
        'amount': salaryAmount,
        'monthYear': accountingMonthYear,
        'paidAt': Timestamp.now(),
        'dateOnly': actualDateOnly,
        'accountingDateOnly': accountingDateOnly,
        'paymentMethod': paymentMethod,
        'transactionRef': transactionRef,
        'status': 'Paid',
      });

      // ── 3. EMPLOYEE update: balances reset ──
      // ✅ lastSalaryPaidDate hataya — lock nahi lagta ab
      DocumentReference employeeRef =
      FirebaseFirestore.instance.collection('employees').doc(employeeId);
      batch.update(employeeRef, {
        'advance_balance': 0,
        'deduction_balance': 0,
        'totalPayouts': FieldValue.increment(salaryAmount),
      });

      await batch.commit();
      notifyListeners();
    } catch (e) {
      print("Error in markSalaryAsPaid: $e");
      rethrow;
    }
  }

  @override
  void dispose() {
    _cancelAllListeners();
    super.dispose();
  }
}