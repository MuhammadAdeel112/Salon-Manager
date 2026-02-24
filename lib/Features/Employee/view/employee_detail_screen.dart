import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../Dashboard/admin_provider.dart';
import 'employee_detail_provider.dart';

class EmployeeDetailsScreen extends StatelessWidget {
  final String staffName;
  final String dateFilter;
  final String filterType;
  final DateTimeRange? customRange;

  const EmployeeDetailsScreen({
    super.key,
    required this.staffName,
    required this.dateFilter,
    required this.filterType,
    this.customRange,
  });

  // --- GOLDEN PALETTE ---
  final Color kBg = const Color(0xFFFFFDE7);
  final Color kGoldLight = const Color(0xFFF3E5AB);
  final Color kGoldPrimary = const Color(0xFFD4AF37);
  final Color kGoldDark = const Color(0xFFC69C34);
  final Color kCharcoal = const Color(0xFF2C2C2C);
  final Color kWhite = Colors.white;

  @override
  Widget build(BuildContext context) {
    final detailsProv = Provider.of<EmployeeDetailsProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: Text(staffName.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: kCharcoal)),
        centerTitle: true,
        backgroundColor: kWhite,
        foregroundColor: kCharcoal,
        elevation: 0,
        actions: [
          Consumer<EmployeeDetailsProvider>(
            builder: (context, prov, _) => IconButton(
              icon: Icon(Icons.history_rounded, color: kGoldDark),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdjustmentHistoryScreen(
                      staffName: staffName,
                      adjustments: prov.adjustmentDocs,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('employees').snapshots(),
        builder: (context, empSnapshot) {
          double baseSalary = 0;
          double commRate = 0;
          String empType = "Commission";
          String employeeId = "";

          if (empSnapshot.hasData) {
            for (var doc in empSnapshot.data!.docs) {
              var data = doc.data() as Map<String, dynamic>;
              if (data['name'].toString().toLowerCase().trim() == staffName.toLowerCase().trim()) {
                employeeId = doc.id;
                empType = data['type'] ?? "Commission";

                // Standardized Field Access (Mapping old to new)
                baseSalary = (data['salary'] ?? data['base_salary'] ?? 0).toDouble();
                commRate = (data['commission'] ?? data['commission_percentage'] ?? 0).toDouble();

                if (baseSalary == 0 && commRate == 0) {
                  double oldVal = (data['commission'] ?? data['value'] ?? 0).toDouble();
                  if (empType == "Commission") commRate = oldVal;
                  else baseSalary = oldVal;
                }
                break;
              }
            }
          }

          return StreamBuilder<QuerySnapshot>(
            stream: detailsProv.getTransactionsStream(staffName),
            builder: (context, transSnapshot) {
              return StreamBuilder<QuerySnapshot>(
                stream: detailsProv.getAdjustmentsStream(staffName),
                builder: (context, adjSnapshot) {
                  if (transSnapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator(color: kGoldDark));
                  }

                  detailsProv.processTransactions(
                    docs: transSnapshot.data?.docs ?? [],
                    adjustments: adjSnapshot.data?.docs ?? [],
                    filterType: filterType,
                    dateFilter: dateFilter,
                    customRange: customRange,
                    empType: empType,
                    baseSalary: baseSalary,
                    commRate: commRate,
                  );

                  return Consumer<EmployeeDetailsProvider>(
                    builder: (context, prov, _) {
                      return Column(
                        children: [
                          _buildHeader(context, prov, empType, employeeId),
                          const SizedBox(height: 10),
                          Expanded(
                            child: prov.filteredDocs.isEmpty
                                ? Center(child: Text("No records found.", style: TextStyle(color: kCharcoal)))
                                : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              itemCount: prov.filteredDocs.length,
                              itemBuilder: (context, index) {
                                final data = prov.filteredDocs[index].data() as Map<String, dynamic>;
                                return _buildTransactionItem(context, data, prov.filteredDocs[index].id);
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, EmployeeDetailsProvider prov, String type, String employeeId) {
    String earningsLabel = "Earned Pay";
    if (type == "Commission") earningsLabel = "Earned Comm.";
    else if (type == "Fixed Salary") earningsLabel = "Fixed Salary";
    else earningsLabel = "Salary + Comm.";

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
        boxShadow: [BoxShadow(color: kGoldDark.withOpacity(0.1), blurRadius: 10)],
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 25),
      child: Column(
        children: [
          Text(filterType == "Custom" ? "Selected Range Report" : "Report for $dateFilter",
              style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          Row(
            children: [
              _statBox("Approved Sales", prov.totalApprovedSales, kGoldDark),
              const SizedBox(width: 12),
              _statBox(earningsLabel, prov.earnedPayment, kCharcoal),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _adjustmentBox(context, "Advance", prov.totalAdvance, kGoldPrimary, Icons.add_circle_outline),
              const SizedBox(width: 12),
              _adjustmentBox(context, "Deduction", prov.totalDeduction, kCharcoal, Icons.remove_circle_outline),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [kGoldPrimary, kGoldDark]),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [BoxShadow(color: kGoldDark.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("NET SETTLEMENT", style: TextStyle(color: kWhite.withOpacity(0.7), fontWeight: FontWeight.bold, fontSize: 10)),
                    Text("Final Take Home", style: TextStyle(color: kWhite, fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
                Text("Rs ${prov.finalTakeHome.toStringAsFixed(0)}",
                    style: TextStyle(color: kWhite, fontSize: 24, fontWeight: FontWeight.w900)),
              ],
            ),
          ),

          if (filterType == "Monthly" || filterType == "Daily")
            StreamBuilder<QuerySnapshot>(
              stream: prov.getPayoutStatusStream(staffName, dateFilter),
              builder: (context, snapshot) {
                final bool isPaid = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
                final bool isAmountZero = prov.finalTakeHome <= 0;

                return Padding(
                  padding: const EdgeInsets.only(top: 15),
                  child: isPaid
                      ? Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    decoration: BoxDecoration(
                        color: kGoldLight.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kGoldPrimary)
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_rounded, color: kGoldDark, size: 22),
                        const SizedBox(width: 8),
                        Text("SETTLED & PAID", style: TextStyle(color: kCharcoal, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                      ],
                    ),
                  )
                      : prov.isProcessing
                      ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()))
                      : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isAmountZero ? Colors.grey[300] : kCharcoal,
                      foregroundColor: isAmountZero ? Colors.grey[600] : kGoldPrimary,
                      elevation: 0,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: isAmountZero ? null : () => _confirmSalaryPayment(context, prov, employeeId),
                    child: const Text("MARK AS PAID (MONTHLY CLOSING)", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  void _confirmSalaryPayment(BuildContext context, EmployeeDetailsProvider prov, String employeeId) {
    if(employeeId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error: Employee Data not found"), backgroundColor: Colors.red));
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Final Settlement", style: TextStyle(fontWeight: FontWeight.bold, color: kCharcoal)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Staff: $staffName"),
            Text("Period: $dateFilter"),
            const SizedBox(height: 10),
            Text("Total Payable: Rs ${prov.finalTakeHome.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            const Text("Warning: This will record an expense and reset this month's advances/deductions.", style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kGoldDark, foregroundColor: kWhite),
            onPressed: () async {
              Navigator.pop(context);
              prov.setProcessing(true);

              try {
                final adminProv = Provider.of<AdminProvider>(context, listen: false);

                // 1. Sync with Admin Dashboard Expenses & Reset Balances
                await adminProv.markSalaryAsPaid(
                  employeeId: employeeId,
                  employeeName: staffName,
                  salaryAmount: prov.finalTakeHome,
                );

                // 2. Mark specific period as Paid in History
                await prov.markAsPaid(
                  staffName: staffName,
                  amount: prov.finalTakeHome,
                  monthYear: dateFilter,
                );

                prov.setProcessing(false);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Salary Disbursed Successfully!"), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                prov.setProcessing(false);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
                }
              }
            },
            child: const Text("Confirm Paid"),
          ),
        ],
      ),
    );
  }

  Widget _statBox(String title, double val, Color col) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: col.withOpacity(0.05), borderRadius: BorderRadius.circular(15), border: Border.all(color: col.withOpacity(0.1))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
            Text("Rs ${val.toStringAsFixed(0)}", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: col)),
          ],
        ),
      ),
    );
  }

  Widget _adjustmentBox(BuildContext context, String title, double val, Color col, IconData icon) {
    return Expanded(
      child: InkWell(
        onTap: () => _showAdjustmentDialog(context, title),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: col.withOpacity(0.05), borderRadius: BorderRadius.circular(15), border: Border.all(color: col.withOpacity(0.1))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                  Text("Rs ${val.toStringAsFixed(0)}", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: col)),
                ],
              ),
              Icon(icon, color: col, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  void _showAdjustmentDialog(BuildContext context, String type) {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Add $type", style: TextStyle(fontWeight: FontWeight.bold, color: kCharcoal)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                  labelText: "Amount",
                  labelStyle: TextStyle(color: kGoldDark),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kGoldPrimary)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kGoldDark))
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                  labelText: "Reason (Optional)",
                  labelStyle: TextStyle(color: kGoldDark),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kGoldPrimary)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kGoldDark))
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: type == "Advance" ? kGoldPrimary : kCharcoal),
            onPressed: () {
              if (amountController.text.isNotEmpty) {
                Provider.of<EmployeeDetailsProvider>(context, listen: false).addAdjustment(
                  staffName: staffName,
                  amount: double.parse(amountController.text),
                  type: type,
                  reason: reasonController.text,
                );
                Navigator.pop(context);
              }
            },
            child: const Text("Confirm", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, Map<String, dynamic> data, String docId) {
    final bool isApproved = (data['status'] ?? "Unapproved") == "Approved";
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: kGoldDark.withOpacity(0.1), blurRadius: 5)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("${data['dateOnly'] ?? ''} | ${data['time'] ?? 'N/A'}", style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
              Text("Rs ${data['totalPrice'] ?? 0}", style: TextStyle(fontWeight: FontWeight.w900, color: kGoldDark, fontSize: 16)),
            ],
          ),
          const Divider(height: 20),
          _buildServiceChips(data),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: isApproved ? kGoldDark : kCharcoal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
              ),
              onPressed: () => _showApproveDialog(context, docId, data['status'] ?? "Unapproved"),
              child: Text(isApproved ? "Approved ✓" : "Review & Approve", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceChips(Map<String, dynamic> data) {
    dynamic rawServices = data['selectedServices'] ?? data['services'] ?? [];
    List<String> serviceNames = [];
    if (rawServices is List) {
      for (var s in rawServices) { serviceNames.add(s is Map ? (s['name'] ?? "") : s.toString()); }
    }
    return Wrap(spacing: 6, runSpacing: 4, children: serviceNames.map((s) => Container(padding: const EdgeInsets.symmetric(horizontal: 10,
        vertical: 4), decoration: BoxDecoration(color: kGoldLight, borderRadius: BorderRadius.circular(8)), child: Text(s, style: TextStyle(fontSize: 11,
        fontWeight: FontWeight.w500, color: kCharcoal)))).toList());
  }

  void _showApproveDialog(BuildContext context, String docId, String status) async {
    String newStatus = (status == "Approved") ? "Unapproved" : "Approved";
    showDialog(context: context, builder: (context) => AlertDialog(
      title: Text("Confirm Status Change", style: TextStyle(color: kCharcoal)),
      content: Text("Do you want to change status to $newStatus?"),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(onPressed: () async {
          Navigator.pop(context);
          await FirebaseFirestore.instance.collection('transactions').doc(docId).update({'status': newStatus});
        }, child: const Text("Confirm")),
      ],
    ));
  }
}

class AdjustmentHistoryScreen extends StatelessWidget {
  final String staffName;
  final List<QueryDocumentSnapshot> adjustments;

  final Color kBg = const Color(0xFFFFFDE7);
  final Color kGoldLight = const Color(0xFFF3E5AB);
  final Color kGoldPrimary = const Color(0xFFD4AF37);
  final Color kCharcoal = const Color(0xFF2C2C2C);

  const AdjustmentHistoryScreen({super.key, required this.staffName, required this.adjustments});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: Text("$staffName's Ledger History", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kCharcoal)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: kCharcoal,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text("Advances & Deductions", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
            ),
            adjustments.isEmpty
                ? const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("No record found.")))
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: adjustments.length,
              itemBuilder: (context, index) {
                final data = adjustments[index].data() as Map<String, dynamic>;
                final bool isAdvance = (data['type'] ?? "Advance") == "Advance";
                DateTime? date;
                try { if (data['date'] != null) date = DateTime.tryParse(data['date'].toString()); } catch (_) {}
                final DateTime displayDate = date ?? DateTime.now();
                Color itemColor = isAdvance ? kGoldPrimary : kCharcoal;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: itemColor.withOpacity(0.1), blurRadius: 10)]),
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: itemColor.withOpacity(0.1), child: Icon(isAdvance ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, color: itemColor)),
                    title: Text(isAdvance ? "Advance Taken" : "Salary Deduction", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kCharcoal)),
                    subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(data['reason'] ?? "No reason", style: const TextStyle(fontSize: 12, color: Colors.grey)), Text(DateFormat('dd MMM yyyy | hh:mm a').format(displayDate), style: const TextStyle(fontSize: 10, color: Colors.grey))]),
                    trailing: Text("Rs ${data['amount'] ?? 0}", style: TextStyle(fontWeight: FontWeight.w900, color: itemColor)),
                  ),
                );
              },
            ),
            const Divider(thickness: 2),
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 20, 16, 10),
              child: Text("Salary Payout History", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('employee_history').where('employeeName', isEqualTo: staffName.trim()).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Padding(padding: EdgeInsets.all(20), child: Center(child: Text("No payout record found.")));
                List<QueryDocumentSnapshot> docs = snapshot.data!.docs;
                docs.sort((a, b) {
                  final dataA = a.data() as Map<String, dynamic>;
                  final dataB = b.data() as Map<String, dynamic>;
                  return (dataB['date'] as Timestamp).compareTo(dataA['date'] as Timestamp);
                });
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    DateTime date = (data['date'] as Timestamp).toDate();
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: kGoldPrimary.withOpacity(0.1), blurRadius: 10)]),
                      child: ListTile(
                        leading: CircleAvatar(backgroundColor: kGoldPrimary.withOpacity(0.1), child: Icon(Icons.payments_outlined, color: kGoldPrimary)),
                        title: Text("Salary Disbursed", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kCharcoal)),
                        subtitle: Text(DateFormat('dd MMM yyyy | hh:mm a').format(date), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        trailing: Text("Rs ${data['amount'] ?? 0}", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: kGoldPrimary)),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}