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

  // Store subscriptions to cancel them later
  StreamSubscription<QuerySnapshot>? _transactionsSubscription;
  StreamSubscription<QuerySnapshot>? _expensesSubscription;
  StreamSubscription<QuerySnapshot>? _employeesSubscription;

  // Firebase Listeners
  void startListening() {
    // Cancel previous listeners if any (safety)
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

  // Cancel all active listeners (Important for Logout)
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

  // Calculation Logic
  Map<String, double> calculateTotals(String selectedFilter, String todayDate,
      String currentMonthStr, DateTimeRange? customRange) {
    double sales = 0;
    double expense = 0;

    bool checkInclusion(String docDate) {
      if (docDate.isEmpty) return false;
      String cleanDate = docDate.trim();

      if (selectedFilter == "Daily") return cleanDate == todayDate;
      if (selectedFilter == "Monthly") return cleanDate.startsWith(currentMonthStr);
      if (selectedFilter == "Custom" && customRange != null) {
        try {
          DateTime dt = DateTime.parse(cleanDate);
          DateTime check = DateTime(dt.year, dt.month, dt.day);
          DateTime start = DateTime(customRange.start.year, customRange.start.month, customRange.start.day);
          DateTime end = DateTime(customRange.end.year, customRange.end.month, customRange.end.day);

          return (check.isAtSameMomentAs(start) || check.isAfter(start)) &&
              (check.isAtSameMomentAs(end) || check.isBefore(end));
        } catch (e) {
          return false;
        }
      }
      return false;
    }

    // Calculate Sales
    for (var doc in _transactions) {
      var data = doc.data() as Map<String, dynamic>;
      if (checkInclusion(data['dateOnly'] ?? "") &&
          (data['status'] ?? "") == "Approved") {
        sales += (data['totalPrice'] ?? 0).toDouble();
      }
    }

    // Calculate Expenses
    for (var doc in _expenses) {
      var data = doc.data() as Map<String, dynamic>;
      if (checkInclusion(data['dateOnly'] ?? "")) {
        expense += (data['amount'] ?? 0).toDouble();
      }
    }

    return {
      "sales": sales,
      "expenses": expense,
      "profit": sales - expense
    };
  }

  // ══════════════════════════════════════════════════════════════════
  // ✅ UPDATED: Premium Payroll Support Added
  // ══════════════════════════════════════════════════════════════════
  Future<void> markSalaryAsPaid({
    required String employeeId,
    required String employeeName,
    required double salaryAmount,
    required String paymentMethod,  // <-- NAYA ADD KIYA
    required String transactionRef, // <-- NAYA ADD KIYA
  }) async {
    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();

      DateTime now = DateTime.now();
      String dateOnly = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      // 1. Register as SHOP EXPENSE (Accounting mein record ke liye method bhi save kiya)
      DocumentReference expenseRef = FirebaseFirestore.instance.collection('expenses').doc();
      batch.set(expenseRef, {
        'amount': salaryAmount,
        'category': "Salary",
        'description': "Monthly Salary paid to $employeeName via $paymentMethod",
        'timestamp': Timestamp.now(),
        'dateOnly': dateOnly,
        'staffId': employeeId,
        'paymentMethod': paymentMethod, // <-- NAYA
        'transactionRef': transactionRef, // <-- NAYA
      });

      // 2. Log in EMPLOYEE HISTORY (Payslip record)
      DocumentReference historyRef = FirebaseFirestore.instance.collection('employee_history').doc();
      batch.set(historyRef, {
        'employeeId': employeeId,
        'employeeName': employeeName.trim(),
        'amount': salaryAmount,
        'date': Timestamp.now(),
        'dateOnly': dateOnly,
        'type': 'salary_paid',
        'status': 'Completed',
        'paymentMethod': paymentMethod, // <-- NAYA
        'transactionRef': transactionRef, // <-- NAYA
      });

      // 3. Reset Staff Balances (Month Lock)
      DocumentReference employeeRef = FirebaseFirestore.instance.collection('employees').doc(employeeId);
      batch.update(employeeRef, {
        'advance_balance': 0,
        'deduction_balance': 0,
        'lastSalaryPaidDate': Timestamp.now(),
        'totalPayouts': FieldValue.increment(salaryAmount),
      });

      await batch.commit();
      notifyListeners();

    } catch (e) {
      print("Error in markSalaryAsPaid: $e");
      rethrow;
    }
  }

  // Good practice: Jab provider dispose ho to listeners bhi cancel ho jayen
  @override
  void dispose() {
    _cancelAllListeners();
    super.dispose();
  }
}