import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminProvider extends ChangeNotifier {
  List<DocumentSnapshot> _transactions = [];
  List<DocumentSnapshot> _expenses = [];
  List<DocumentSnapshot> _employees = [];

  List<DocumentSnapshot> get transactions => _transactions;
  List<DocumentSnapshot> get expenses => _expenses;
  List<DocumentSnapshot> get employees => _employees;

  // Firebase Listeners
  void startListening() {
    FirebaseFirestore.instance.collection('transactions').snapshots().listen((snapshot) {
      _transactions = snapshot.docs;
      notifyListeners();
    });

    FirebaseFirestore.instance.collection('expenses').snapshots().listen((snapshot) {
      _expenses = snapshot.docs;
      notifyListeners();
    });

    FirebaseFirestore.instance.collection('employees').snapshots().listen((snapshot) {
      _employees = snapshot.docs;
      notifyListeners();
    });
  }

  // Calculation Logic
  Map<String, double> calculateTotals(String selectedFilter, String todayDate, String currentMonthStr, DateTimeRange? customRange) {
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
        } catch (e) { return false; }
      }
      return false;
    }

    // 1. Calculate Sales (Revenue)
    for (var doc in _transactions) {
      var data = doc.data() as Map<String, dynamic>;
      if (checkInclusion(data['dateOnly'] ?? "") && (data['status'] ?? "") == "Approved") {
        sales += (data['totalPrice'] ?? 0).toDouble();
      }
    }

    // 2. Calculate Shop Expenses (Ab is mein Paid Salaries bhi khud hi shamil ho jayengi)
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

  // --- UPDATED: Professional Salary Payout Logic ---
  Future<void> markSalaryAsPaid({
    required String employeeId,
    required String employeeName,
    required double salaryAmount,
  }) async {
    try {
      // BATCH use kar rahe hain taake agar ek bhi kaam rukay toh poora process cancel ho jaye (Safe approach)
      WriteBatch batch = FirebaseFirestore.instance.batch();

      DateTime now = DateTime.now();
      String dateOnly = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      // 1. Register as SHOP EXPENSE (Dashboard Profit-Loss mein dikhane ke liye)
      DocumentReference expenseRef = FirebaseFirestore.instance.collection('expenses').doc();
      batch.set(expenseRef, {
        'amount': salaryAmount,
        'category': "Salary",
        'description': "Monthly Salary paid to $employeeName",
        'timestamp': Timestamp.now(),
        'dateOnly': dateOnly, // Dashboard filtering ke liye zaroori hai
        'staffId': employeeId,
      });

      // 2. Log in EMPLOYEE HISTORY (Staff ke Ledger record ke liye)
      DocumentReference historyRef = FirebaseFirestore.instance.collection('employee_history').doc();
      batch.set(historyRef, {
        'employeeId': employeeId,
        'employeeName': employeeName.trim(),
        'amount': salaryAmount,
        'date': Timestamp.now(),
        'dateOnly': dateOnly,
        'type': 'salary_paid',
        'status': 'Completed'
      });

      // 3. RESET STAFF BALANCES (Agla mahina Fresh start/Unlock karne ke liye)
      DocumentReference employeeRef = FirebaseFirestore.instance.collection('employees').doc(employeeId);

      // Note: Hum yahan fields ko 0 kar rahe hain taake next month ka Advance 0 se shuru ho
      batch.update(employeeRef, {
        'advance_balance': 0, // Aapke schema ke mutabiq name adjust karlein
        'deduction_balance': 0,
        'lastSalaryPaidDate': Timestamp.now(),
        'totalPayouts': FieldValue.increment(salaryAmount), // Total lifetime earning track karne ke liye
      });

      // Sab kuch ek saath execute karein
      await batch.commit();

      notifyListeners();

    } catch (e) {
      print("Error in markSalaryAsPaid: $e");
      rethrow;
    }
  }
}