import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'admin_provider.dart';
import '../employee/view/employee_detail_screen.dart';
import '../employee/expances/expance_history.dart';
import 'employee/manage_employee.dart';
import 'manage_services.dart';
import 'logout_dialog.dart';
import 'app_drawer.dart'; // ← Sirf yeh naya import add kiya

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String selectedFilter = "Daily";
  DateTimeRange? customRange;
  DateTime _selectedMonth = DateTime.now();

  final Color kBg = const Color(0xFFFDFAF3);
  final Color kGoldLight = const Color(0xFFF8E9B0);
  final Color kGoldPrimary = const Color(0xFFD4AF37);
  final Color kGoldDark = const Color(0xFFAA8C2C);
  final Color kCharcoal = const Color(0xFF1F1F1F);
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
          return DateTime(int.parse(parts[0]), int.parse(parts[1]),
              int.parse(parts[2]));
        }
      } catch (_) {}
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

  @override
  Widget build(BuildContext context) {
    final adminProv = Provider.of<AdminProvider>(context);

    final double sw = MediaQuery.of(context).size.width;
    final bool isTablet = sw >= 600;

    String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    String currentMonthStr = DateFormat('yyyy-MM').format(_selectedMonth);
    var totals = adminProv.calculateTotals(
        selectedFilter, todayDate, currentMonthStr, customRange);

    return Scaffold(
      backgroundColor: kBg,

      // ✅ SIRF YEH DRAWER ADD KIYA — baaki sab same hai
      drawer: AppDrawer(
        selectedFilter: selectedFilter,
        todayDate: todayDate,
        currentMonth: currentMonthStr,
        customRange: customRange,
      ),

      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        toolbarHeight: 50,
        centerTitle: true,

        // ✅ Drawer icon automatically AppBar mein aa jayega
        // Flutter khud hamburger icon add karta hai jab drawer ho

        title: Text(
          "Admin Dashboard",
          style: TextStyle(
            color: kCharcoal,
            fontSize: isTablet ? 18 : 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout_rounded,
                color: kGoldDark, size: isTablet ? 22 : 20),
            onPressed: () => LogoutDialog.show(context),
          )
        ],
      ),

      // ✅ Body bilkul same — koi change nahi
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 15 : 12, vertical: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  _filterBtn("Daily", isTablet),
                  const SizedBox(width: 10),
                  _filterBtn("Monthly", isTablet),
                  const SizedBox(width: 10),
                  _filterBtn("Custom", isTablet),
                ],
              ),
            ),
            const SizedBox(height: 15),
            Text(
              _getHeaderText(),
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.bold,
                color: kCharcoal,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatCard("Total Sales", totals['sales']!, kGoldLight,
                    kGoldDark, Icons.attach_money, isTablet),
                const SizedBox(width: 8),
                _buildStatCard("Expenses", totals['expenses']!, kGoldPrimary,
                    kCharcoal, Icons.south_west, isTablet),
                const SizedBox(width: 8),
                _buildStatCard("Net Profit", totals['profit']!, kCharcoal,
                    kGoldPrimary, Icons.north_east, isTablet),
              ],
            ),
            const SizedBox(height: 30),
            Text(
              "Admin Management",
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.bold,
                color: kCharcoal,
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                _buildSquareMenu("Staff", kGoldPrimary,
                    const ManageEmployees(), "assets/emp.png", isTablet),
                const SizedBox(width: 12),
                _buildSquareMenu("Services", kGoldPrimary,
                    const ManageServices(), "assets/logo.png", isTablet),
                const SizedBox(width: 12),
                _buildSquareMenu(
                  "Expenses",
                  kGoldPrimary,
                  ExpenseHistoryScreen(
                    filterType: selectedFilter,
                    todayDate: todayDate,
                    currentMonth: currentMonthStr,
                    customRange: customRange,
                  ),
                  "assets/exp.png",
                  isTablet,
                ),
              ],
            ),
            const SizedBox(height: 30),
            Text(
              "Employee Performance",
              style: TextStyle(
                fontSize: isTablet ? 18 : 15,
                fontWeight: FontWeight.bold,
                color: kCharcoal,
              ),
            ),
            const SizedBox(height: 12),
            _buildEmployeeTable(
                adminProv, todayDate, currentMonthStr, sw, isTablet),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _filterBtn(String label, bool isTablet) {
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
          padding: EdgeInsets.symmetric(vertical: isTablet ? 14 : 11),
          decoration: BoxDecoration(
            color: isSel ? kCharcoal : kWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isSel
                    ? kCharcoal
                    : kGoldPrimary.withValues(alpha: 0.3)),
            boxShadow: isSel
                ? [
              BoxShadow(
                  color: kGoldDark.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2))
            ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSel ? kWhite : kCharcoal,
              fontSize: isTablet ? 14 : 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, double val, Color bg, Color textCol,
      IconData icon, bool isTablet) {
    return Expanded(
      child: Container(
        height: isTablet ? 160 : 130,
        padding: EdgeInsets.symmetric(
            vertical: isTablet ? 24 : 16,
            horizontal: isTablet ? 14 : 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [bg, bg.withOpacity(0.7)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: textCol.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 5))
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: isTablet ? 28 : 22, color: textCol),
            SizedBox(height: isTablet ? 12 : 6),
            Text(
              title,
              style: TextStyle(
                color: textCol.withOpacity(0.8),
                fontSize: isTablet ? 14 : 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: isTablet ? 8 : 4),
            FittedBox(
              alignment: Alignment.centerLeft,
              child: Text(
                title == "Total Sales"
                    ? val.toStringAsFixed(0)
                    : "PKR ${val.toStringAsFixed(0)}",
                style: TextStyle(
                  color: textCol,
                  fontSize: isTablet ? 26 : 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ).animate().fade(duration: 500.ms).slideY(begin: 0.2, curve: Curves.easeOutQuad),
    );
  }

  Widget _buildSquareMenu(String title, Color col, Widget screen,
      String imagePath, bool isTablet) {
    return Expanded(
      child: Column(
        children: [
          InkWell(
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => screen)),
            child: Container(
              height: isTablet ? 180 : 140,
              decoration: BoxDecoration(
                color: kWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: col.withValues(alpha: 0.2), width: 1.5),
                boxShadow: [
                  BoxShadow(
                      color: kGoldDark.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
                image: DecorationImage(
                  image: AssetImage(imagePath),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              color: kCharcoal,
              fontSize: isTablet ? 13 : 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeTable(AdminProvider prov, String today, String month,
      double sw, bool isTablet) {
    if (prov.employees.isEmpty) {
      return const Center(child: Text("No Staff Found", style: TextStyle(color: Colors.grey)));
    }
    return Column(
      children: prov.employees.map((empDoc) {
        var empData = empDoc.data() as Map<String, dynamic>;
        String name = empData['name'] ?? "Unknown";
        String type = empData['type'] ?? "Salary";

        double fixedAmount =
        (empData['value'] ?? empData['salary'] ?? 0).toDouble();
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

        double payout = 0;
        String subTitle = "";
        Color payoutColor = kCharcoal;

        if (type == "Both") {
          payout = fixedAmount + (rev * commissionRate / 100);
          subTitle = "Fix + ${commissionRate.toStringAsFixed(0)}%";
          payoutColor = Colors.blue.shade700;
        } else if (type == "Commission") {
          payout = (rev * commissionRate / 100);
          subTitle = "${commissionRate.toStringAsFixed(0)}%";
          payoutColor = Colors.amber.shade800;
        } else {
          payout = fixedAmount;
          subTitle = "Fixed";
          payoutColor = Colors.green.shade700;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(isTablet ? 20 : 16),
          decoration: BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: kGoldDark.withOpacity(0.06),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: isTablet ? 26 : 22,
                backgroundColor: kGoldPrimary.withOpacity(0.15),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : "?",
                  style: TextStyle(
                    color: kGoldDark,
                    fontWeight: FontWeight.bold,
                    fontSize: isTablet ? 20 : 18,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: isTablet ? 16 : 15,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2C2C2C),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.attach_money, size: isTablet ? 16 : 14, color: Colors.grey),
                        Text(
                          "Rev: ${rev.toStringAsFixed(0)}",
                          style: TextStyle(fontSize: isTablet ? 13 : 12, color: Colors.grey),
                        ),
                        const SizedBox(width: 10),
                        Icon(Icons.payments_rounded, size: isTablet ? 16 : 14, color: payoutColor),
                        Text(
                          " PKR ${payout.toStringAsFixed(0)}",
                          style: TextStyle(fontSize: isTablet ? 13 : 12, fontWeight: FontWeight.bold, color: payoutColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EmployeeDetailsScreen(
                        staffName: name,
                        dateFilter: selectedFilter == "Daily" ? today : month,
                        filterType: selectedFilter,
                        customRange: customRange,
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: isTablet ? 18 : 14, vertical: isTablet ? 10 : 8),
                  decoration: BoxDecoration(
                    color: kGoldPrimary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kGoldPrimary.withOpacity(0.3)),
                  ),
                  child: Text(
                    "View",
                    style: TextStyle(
                      color: const Color(0xFFC69C34),
                      fontSize: isTablet ? 14 : 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ).animate().fade().slideX(begin: 0.1, curve: Curves.easeOut);
      }).toList(),
    );
  }

  void _pickMonth() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SizedBox(
        height: 300,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text("Select Month",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.monthYear,
                initialDateTime: _selectedMonth,
                onDateTimeChanged: (d) => _selectedMonth = d,
              ),
            ),
            CupertinoButton(
              child: const Text("Apply"),
              onPressed: () {
                setState(() => selectedFilter = "Monthly");
                Navigator.pop(context);
              },
            )
          ],
        ),
      ),
    );
  }

  Future<void> _pickCustomRange() async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: ColorScheme.light(primary: kGoldDark),
          buttonTheme: const ButtonThemeData(
              textTheme: ButtonTextTheme.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        customRange = picked;
        selectedFilter = "Custom";
      });
    }
  }
}