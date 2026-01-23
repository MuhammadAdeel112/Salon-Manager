import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../Auth/admin_login.dart';
import 'manage_employee.dart';
import 'manage_services.dart';
import '../../main.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String selectedFilter = "Daily";

  void _handleLogout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const SalonApp()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isTablet = screenWidth > 600;

    String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    String currentMonth = DateFormat('yyyy-MM').format(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Admin Dashboard",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () => _showLogoutDialog(),
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('transactions').snapshots(),
        builder: (context, salesSnapshot) {
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('expenses').snapshots(),
            builder: (context, expSnapshot) {
              if (salesSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              double totalSalesOverview = 0;
              double totalExpenses = 0;

              for (var doc in salesSnapshot.data?.docs ?? []) {
                var data = doc.data() as Map<String, dynamic>;
                String docDate = data['dateOnly'] ?? "";
                bool shouldInclude = (selectedFilter == "Daily")
                    ? (docDate == todayDate)
                    : (docDate.startsWith(currentMonth));
                if (shouldInclude) totalSalesOverview += (data['totalPrice'] ?? 0).toDouble();
              }

              for (var doc in expSnapshot.data?.docs ?? []) {
                var data = doc.data() as Map<String, dynamic>;
                String docDate = data['dateOnly'] ?? "";
                bool shouldInclude = (selectedFilter == "Daily")
                    ? (docDate == todayDate)
                    : (docDate.startsWith(currentMonth));
                if (shouldInclude) totalExpenses += (data['amount'] ?? 0).toDouble();
              }

              double netProfit = totalSalesOverview - totalExpenses;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _filterButton("Daily"),
                        const SizedBox(width: 10),
                        _filterButton("Monthly"),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text("$selectedFilter Overview",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildStatCard("Total Sales", totalSalesOverview, Colors.green),
                        const SizedBox(width: 8),
                        _buildStatCard("Expenses", totalExpenses, Colors.red),
                        const SizedBox(width: 8),
                        _buildStatCard("Net Profit", netProfit, Colors.blue),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text("Admin Management",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: isTablet ? 1.5 : 0.85,
                      children: [
                        _buildAdminMenuCard(context, "Staff", Icons.people_alt_rounded, Colors.indigo, const ManageEmployees()),
                        _buildAdminMenuCard(context, "Services", Icons.cut_rounded, const Color.fromARGB(255, 14, 126, 116), const ManageServices()),
                        _buildAdminMenuCard(context, "Expenses", Icons.receipt_long, Colors.redAccent, ExpenseHistoryScreen(filterType: selectedFilter, todayDate: todayDate, currentMonth: currentMonth)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _sectionWrapper("Employee Performance", _buildEmployeeTable(todayDate, currentMonth)),
                    const SizedBox(height: 40),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- UI HELPERS ---

  Widget _buildAdminMenuCard(BuildContext context, String title, IconData icon, Color color, Widget nextScreen) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => nextScreen)),
      child: Container(
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(15), border: Border.all(color: color.withOpacity(0.3))),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: color, size: 28), const SizedBox(height: 8), Text(title, textAlign: TextAlign.center, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12))]),
      ),
    );
  }

  Widget _sectionWrapper(String title, Widget child) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      child,
    ]);
  }

  Widget _filterButton(String type) {
    bool isActive = selectedFilter == type;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: isActive ? Colors.black : Colors.grey[200], foregroundColor: isActive ? Colors.white : Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), elevation: 0),
      onPressed: () => setState(() => selectedFilter = type),
      child: Text(type),
    );
  }

  Widget _buildStatCard(String title, double value, Color color) {
    return Expanded(child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)), child: Column(children: [Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey)), const SizedBox(height: 8), FittedBox(child: Text("PKR ${value.toStringAsFixed(0)}", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)))])));
  }

  Widget _buildEmployeeTable(String todayDate, String currentMonth) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('employees').snapshots(),
        builder: (context, empSnapshot) {
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('transactions').snapshots(),
            builder: (context, transSnapshot) {
              if (!empSnapshot.hasData || !transSnapshot.hasData) return const Center(child: LinearProgressIndicator());
              Map<String, double> totalStaffRevenue = {};
              Map<String, double> approvedCommissionPKR = {};
              Map<String, double> staffRates = {};
              Map<String, String> staffTypes = {};

              for (var doc in empSnapshot.data!.docs) {
                var data = doc.data() as Map<String, dynamic>;
                String cleanName = (data['name'] ?? "").toString().toLowerCase().trim();
                staffRates[cleanName] = (data['commission'] ?? data['value'] ?? 0).toDouble();
                staffTypes[cleanName] = (data['type'] ?? "Fixed Salary").toString();
              }

              for (var doc in transSnapshot.data!.docs) {
                var data = doc.data() as Map<String, dynamic>;
                String docDate = data['dateOnly'] ?? "";
                String status = (data['status'] ?? "Unapproved").toString().trim();
                String staffClean = (data['staffName'] ?? "Unknown").toString().toLowerCase().trim();
                double price = (data['totalPrice'] ?? 0).toDouble();
                bool shouldInclude = (selectedFilter == "Daily") ? (docDate == todayDate) : (docDate.startsWith(currentMonth));
                if (shouldInclude) {
                  totalStaffRevenue[staffClean] = (totalStaffRevenue[staffClean] ?? 0) + price;
                  if (status == "Approved" && staffTypes[staffClean] == "Commission") {
                    double rate = staffRates[staffClean] ?? 0;
                    approvedCommissionPKR[staffClean] = (approvedCommissionPKR[staffClean] ?? 0) + (price * rate / 100);
                  }
                }
              }

              return DataTable(
                columnSpacing: 10, horizontalMargin: 10,
                columns: const [
                  DataColumn(label: Text("Staff", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text("Total Rev", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text("Comm (PKR)", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                ],
                rows: empSnapshot.data!.docs.map((empDoc) {
                  var empData = empDoc.data() as Map<String, dynamic>;
                  String originalName = empData['name'] ?? "Unknown";
                  return DataRow(cells: [
                    DataCell(InkWell(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => EmployeeDetailsScreen(
                          staffName: originalName,
                          dateFilter: selectedFilter == "Daily" ? todayDate : currentMonth,
                          filterType: selectedFilter,
                        ))),
                        child: Text(originalName, style: const TextStyle(fontSize: 11, color: Colors.blue, decoration: TextDecoration.underline)))),
                    DataCell(Text("Rs ${totalStaffRevenue[originalName.toLowerCase().trim()]?.toStringAsFixed(0) ?? '0'}", style: const TextStyle(fontSize: 11))),
                    DataCell(Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text("Rs ${approvedCommissionPKR[originalName.toLowerCase().trim()]?.toStringAsFixed(0) ?? '0'}", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: (approvedCommissionPKR[originalName.toLowerCase().trim()] ?? 0) > 0 ? Colors.green : Colors.grey)),
                      Text(empData['type'] == "Commission" ? "${staffRates[originalName.toLowerCase().trim()]}%" : "Salary", style: const TextStyle(fontSize: 9, color: Colors.grey)),
                    ])),
                  ]);
                }).toList(),
              );
            },
          );
        },
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text("Logout"),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        TextButton(onPressed: () { Navigator.pop(context); _handleLogout(); }, child: const Text("Confirm", style: TextStyle(color: Colors.red))),
      ],
    ));
  }
}

// -----------------------------------------------------------------
// EXPENSE HISTORY SCREEN
// -----------------------------------------------------------------
class ExpenseHistoryScreen extends StatelessWidget {
  final String filterType;
  final String todayDate;
  final String currentMonth;

  const ExpenseHistoryScreen({super.key, required this.filterType, required this.todayDate, required this.currentMonth});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(title: Text("$filterType Expenses"), backgroundColor: Colors.white, elevation: 0.5, iconTheme: const IconThemeData(color: Colors.black)),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('expenses').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var filteredDocs = snapshot.data!.docs.where((doc) {
            String docDate = doc['dateOnly'] ?? "";
            return filterType == "Daily" ? docDate == todayDate : docDate.startsWith(currentMonth);
          }).toList();
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredDocs.length,
            itemBuilder: (context, index) {
              var data = filteredDocs[index].data() as Map<String, dynamic>;
              return Card(child: ListTile(title: Text(data['description'] ?? ""), subtitle: Text(data['dateOnly'] ?? ""), trailing: Text("Rs ${data['amount']}", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))));
            },
          );
        },
      ),
    );
  }
}

// -----------------------------------------------------------------
// EMPLOYEE DETAILS SCREEN (FIXED FOR MONTHLY)
// -----------------------------------------------------------------
class EmployeeDetailsScreen extends StatelessWidget {
  final String staffName;
  final String dateFilter;
  final String filterType;

  const EmployeeDetailsScreen({super.key, required this.staffName, required this.dateFilter, required this.filterType});

  void _toggleStatus(String docId, String currentStatus) async {
    String newStatus = (currentStatus == "Approved") ? "Unapproved" : "Approved";
    await FirebaseFirestore.instance.collection('transactions').doc(docId).update({'status': newStatus});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        title: Column(children: [
          Text(staffName.toUpperCase(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
          Text(filterType == "Daily" ? dateFilter : "Month: $dateFilter", style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ]),
        centerTitle: true, backgroundColor: Colors.white, elevation: 0.5, iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('transactions').where('staffName', isEqualTo: staffName).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          // Filtering logic for Daily vs Monthly
          var docs = snapshot.data!.docs.where((doc) {
            String docDate = doc['dateOnly'] ?? "";
            return filterType == "Daily" ? docDate == dateFilter : docDate.startsWith(dateFilter);
          }).toList();

          if (docs.isEmpty) return const Center(child: Text("No records found."));

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              String status = (data['status'] ?? "Unapproved").toString().trim();
              bool isApproved = status == "Approved";
              dynamic rawServices = data['selectedServices'] ?? data['services'] ?? [];
              List<String> serviceNames = [];
              if (rawServices is List) {
                for (var s in rawServices) serviceNames.add(s is Map ? (s['name'] ?? "") : s.toString());
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)]),
                child: Table(
                  border: TableBorder.all(color: Colors.grey.shade200, width: 1),
                  columnWidths: const {0: FlexColumnWidth(1), 1: FlexColumnWidth(2)},
                  children: [
                    TableRow(children: [_cellTitle("Date & Time"), Padding(padding: const EdgeInsets.all(12), child: Text("${data['dateOnly']} | ${data['time'] ?? 'N/A'}"))]),
                    TableRow(children: [
                      _cellTitle("Service & Price"),
                      Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text("Rs ${data['totalPrice']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                        const Divider(),
                        ...serviceNames.map((s) => Text("• $s", style: const TextStyle(fontSize: 12))),
                      ])),
                    ]),
                    TableRow(children: [
                      _cellTitle("Action"),
                      Padding(padding: const EdgeInsets.all(12), child: InkWell(
                        onTap: () => _toggleStatus(docs[index].id, status),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(color: isApproved ? Colors.green : Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: isApproved ? Colors.green : Colors.red)),
                          child: Text(isApproved ? "Approved" : "Unapproved (Approve)", textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isApproved ? Colors.white : Colors.red)),
                        ),
                      )),
                    ]),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _cellTitle(String text) => Container(color: Colors.grey.shade50, padding: const EdgeInsets.all(12), child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)));
}