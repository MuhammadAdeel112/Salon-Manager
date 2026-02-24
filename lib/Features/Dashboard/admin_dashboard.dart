import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';

import '../../main.dart'; // Isme SalonApp (Staff Screen) maujood hai
import 'admin_provider.dart';
import '../Auth/admin_login.dart';
import '../Employee/view/employee_detail_screen.dart';
import '../Employee/expances/expance_history.dart';
import 'employee/manage_employee.dart';
import 'manage_services.dart';


class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String selectedFilter = "Daily";
  DateTimeRange? customRange;
  DateTime _selectedMonth = DateTime.now();

  // --- UPDATED GOLDEN PALETTE ---
  final Color kBg = const Color(0xFFFFFDE7); // Creamy background like login
  final Color kGoldLight = const Color(0xFFF3E5AB);
  final Color kGoldPrimary = const Color(0xFFD4AF37);
  final Color kGoldDark = const Color(0xFFC69C34);
  final Color kCharcoal = const Color(0xFF2C2C2C);
  final Color kWhite = Colors.white;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).startListening();
    });
  }

  DateTime? _safeParse(String dateStr) {
    if (dateStr.isEmpty) return null;
    try {
      return DateTime.parse(dateStr.trim());
    } catch (e) {
      try {
        List<String> parts = dateStr.trim().split('-');
        if (parts.length == 3) {
          return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        }
      } catch (e) {}
      return null;
    }
  }

  String _getHeaderText() {
    if (selectedFilter == "Custom" && customRange != null) {
      String start = DateFormat('dd MMM').format(customRange!.start);
      String end = DateFormat('dd MMM').format(customRange!.end);
      return "$start - $end Overview";
    } else if (selectedFilter == "Monthly") {
      return "${DateFormat('MMMM yyyy').format(_selectedMonth)} Overview";
    }
    return "Daily Overview";
  }

  void _showLogoutDialog() {
    showCupertinoDialog(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to exit the Admin Portal?"),
        actions: [
          CupertinoDialogAction(
            child: const Text("No"),
            onPressed: () => Navigator.pop(dialogContext),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text("Yes"),
            onPressed: () async {
              Navigator.pop(dialogContext);
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const SalonApp()),
                      (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminProv = Provider.of<AdminProvider>(context);
    String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    String currentMonthStr = DateFormat('yyyy-MM').format(_selectedMonth);
    var totals = adminProv.calculateTotals(selectedFilter, todayDate, currentMonthStr, customRange);

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        toolbarHeight: 50,
        centerTitle: true,
        title: Text("Admin Dashboard", style: TextStyle(color: kCharcoal, fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            // Changed to Gold/Dark theme instead of Red
            icon: Icon(Icons.logout_rounded, color: kGoldDark, size: 22),
            onPressed: () => _showLogoutDialog(),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  _filterBtn("Daily"),
                  const SizedBox(width: 10),
                  _filterBtn("Monthly"),
                  const SizedBox(width: 10),
                  _filterBtn("Custom"),
                ],
              ),
            ),
            const SizedBox(height: 15),
            Text(_getHeaderText(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kCharcoal)),
            const SizedBox(height: 12),
            Row(
              children: [
                // PASSING GOLDEN COLORS HERE
                _buildStatCard("Total Sales", totals['sales']!, kGoldLight, kGoldDark, Icons.attach_money),
                const SizedBox(width: 8),
                _buildStatCard("Expenses", totals['expenses']!, kGoldPrimary, kCharcoal, Icons.south_west),
                const SizedBox(width: 8),
                _buildStatCard("Net Profit", totals['profit']!, kCharcoal, kGoldPrimary, Icons.north_east),
              ],
            ),
            const SizedBox(height: 25),
            Text("Admin Management", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kCharcoal)),
            const SizedBox(height: 15),
            Row(
              children: [
                // PASSING GOLDEN COLORS HERE
                _buildSquareMenu("Staff", kGoldPrimary, const ManageEmployees(), "assets/emp.png"),
                const SizedBox(width: 12),
                _buildSquareMenu("Services", kGoldPrimary, const ManageServices(), "assets/logo.png"),
                const SizedBox(width: 12),
                _buildSquareMenu(
                  "Expenses",
                  kGoldPrimary,
                  ExpenseHistoryScreen(filterType: selectedFilter, todayDate: todayDate, currentMonth: currentMonthStr, customRange: customRange),
                  "assets/exp.png",
                ),
              ],
            ),
            const SizedBox(height: 25),
            Text("Employee Performance", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kCharcoal)),
            const SizedBox(height: 10),
            _buildEmployeeTable(adminProv, todayDate, currentMonthStr),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _filterBtn(String label) {
    bool isSel = selectedFilter == label;
    return Expanded(
      child: InkWell(
        onTap: () {
          if (label == "Custom") {
            _pickCustomRange();
          } else if (label == "Monthly") {
            _pickMonth();
          } else {
            setState(() {
              selectedFilter = label;
              customRange = null;
            });
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSel ? kCharcoal : kWhite, // Selected is Dark, Unselected is White
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSel ? kCharcoal : kGoldPrimary.withOpacity(0.3)), // Border is Gold
            boxShadow: isSel ? [BoxShadow(color: kGoldDark.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))] : null,
          ),
          child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: isSel ? kWhite : kCharcoal, fontSize: 14, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, double val, Color bg, Color textCol, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [BoxShadow(color: textCol.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 16, color: textCol),
              ],
            ),
            const SizedBox(height: 10),
            Text(title, style: TextStyle(color: textCol.withOpacity(0.9), fontSize: 10, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            FittedBox(
                alignment: Alignment.centerLeft,
                child: Text(
                    title == "Total Sales" ? val.toStringAsFixed(0) : "PKR ${val.toStringAsFixed(0)}",
                    style: TextStyle(color: textCol, fontSize: 17, fontWeight: FontWeight.bold)
                )
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSquareMenu(String title, Color col, Widget screen, String imagePath) {
    return Expanded(
      child: Column(
        children: [
          InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
            child: Container(
              height: 85,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: col.withOpacity(0.15), width: 1.5),
                boxShadow: [BoxShadow(color: kGoldDark.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))],
                image: DecorationImage(
                  image: AssetImage(imagePath),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(color: kCharcoal, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEmployeeTable(AdminProvider prov, String today, String month) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: kGoldDark.withOpacity(0.05), blurRadius: 8)]),
      child: DataTable(
        columnSpacing: 8,
        horizontalMargin: 10,
        headingRowHeight: 40,
        columns: [
          DataColumn(label: Text("Staff", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: kCharcoal))),
          DataColumn(label: Text("Rev", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: kCharcoal))),
          DataColumn(label: Text("Payout", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: kCharcoal))),
          DataColumn(label: Text("Action", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: kCharcoal))),
        ],
        rows: prov.employees.map((empDoc) {
          var empData = empDoc.data() as Map<String, dynamic>;
          String name = empData['name'] ?? "";
          String type = empData['type'] ?? "Salary"; // Expected values: "Salary", "Commission", "Both"

          // Logic for handling both Salary and Commission fields
          double fixedAmount = (empData['value'] ?? empData['salary'] ?? 0).toDouble();
          double commissionRate = (empData['commission'] ?? 0).toDouble();

          double rev = 0;

          for (var t in prov.transactions) {
            var tData = t.data() as Map<String, dynamic>;
            String docDate = (tData['dateOnly'] ?? "").toString().trim();
            bool include = false;

            if (selectedFilter == "Daily") {
              include = (docDate == today);
            } else if (selectedFilter == "Monthly") {
              include = docDate.startsWith(month);
            } else if (selectedFilter == "Custom" && customRange != null) {
              DateTime? dt = _safeParse(docDate);
              if (dt != null) {
                include = dt.isAfter(customRange!.start.subtract(const Duration(days: 1))) &&
                    dt.isBefore(customRange!.end.add(const Duration(days: 1)));
              }
            }

            if (tData['staffName'] == name && include && tData['status'] == "Approved") {
              rev += (tData['totalPrice'] ?? 0).toDouble();
            }
          }

          // --- FIXED HYBRID PAYOUT CALCULATION ---
          double payout = 0;
          String subTitle = "";

          if (type == "Both") {
            payout = fixedAmount + (rev * commissionRate / 100);
            subTitle = "Fix + $commissionRate%";
          } else if (type == "Commission") {
            payout = (rev * commissionRate / 100);
            subTitle = "$commissionRate%";
          } else {
            // Default is Salary/Fixed
            payout = fixedAmount;
            subTitle = "Fixed";
          }

          return DataRow(cells: [
            DataCell(Text(name, style: TextStyle(fontSize: 11, color: kCharcoal))),
            DataCell(Text(rev.toStringAsFixed(0), style: TextStyle(fontSize: 11, color: kCharcoal))),
            DataCell(
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(payout.toStringAsFixed(0), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: kCharcoal)),
                  Text(subTitle, style: const TextStyle(fontSize: 9, color: Colors.grey)),
                ],
              ),
            ),
            DataCell(
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => EmployeeDetailsScreen(
                      staffName: name,
                      dateFilter: selectedFilter == "Daily" ? today : month,
                      filterType: selectedFilter,
                      customRange: customRange
                  )));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: kGoldLight,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: kGoldPrimary),
                  ),
                  child: Text("View", style: TextStyle(color: kCharcoal, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ]);
        }).toList(),
      ),
    );
  }

  void _pickMonth() {
    showModalBottomSheet(context: context, builder: (_) => SizedBox(height: 300, child: Column(children: [const Padding(padding: EdgeInsets.all(12), child: Text("Select Month", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))), Expanded(child: CupertinoDatePicker(mode: CupertinoDatePickerMode.monthYear, initialDateTime: _selectedMonth, onDateTimeChanged: (d) => _selectedMonth = d)), CupertinoButton(child: const Text("Apply"), onPressed: () { setState(() => selectedFilter = "Monthly"); Navigator.pop(context); })])));
  }

  Future<void> _pickCustomRange() async {
    // Date picker color changed to Gold/Black theme
    DateTimeRange? picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2023),
        lastDate: DateTime.now(),
        builder: (context, child) => Theme(
            data: ThemeData.light().copyWith(
              colorScheme: ColorScheme.light(primary: kGoldDark), // Gold primary color
              buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
            ),
            child: child!
        )
    );
    if (picked != null) setState(() { customRange = picked; selectedFilter = "Custom"; });
  }
}