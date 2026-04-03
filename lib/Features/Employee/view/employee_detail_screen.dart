import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
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

  static const Color kBg = Color(0xFFFFFDE7);
  static const Color kGoldLight = Color(0xFFF3E5AB);
  static const Color kGoldPrimary = Color(0xFFD4AF37);
  static const Color kGoldDark = Color(0xFFC69C34);
  static const Color kCharcoal = Color(0xFF2C2C2C);
  static const Color kWhite = Colors.white;

  @override
  Widget build(BuildContext context) {
    final detailsProv =
    Provider.of<EmployeeDetailsProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: Text(staffName.toUpperCase(),
            style: const TextStyle(
                fontWeight: FontWeight.w900, fontSize: 18, color: kCharcoal)),
        centerTitle: true,
        backgroundColor: kWhite,
        foregroundColor: kCharcoal,
        elevation: 0,
        actions: [
          Consumer<EmployeeDetailsProvider>(
            builder: (context, prov, _) => IconButton(
              icon: const Icon(Icons.history_rounded, color: kGoldDark),
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
        stream:
        FirebaseFirestore.instance.collection('employees').snapshots(),
        builder: (context, empSnapshot) {
          double baseSalary = 0;
          double commRate = 0;
          String empType = "Commission";
          String employeeId = "";

          if (empSnapshot.hasData) {
            for (var doc in empSnapshot.data!.docs) {
              var data = doc.data() as Map<String, dynamic>;
              if (data['name'].toString().toLowerCase().trim() ==
                  staffName.toLowerCase().trim()) {
                employeeId = doc.id;
                empType = data['type'] ?? "Commission";
                baseSalary =
                    (data['salary'] ?? data['base_salary'] ?? 0).toDouble();
                commRate = (data['commission'] ??
                    data['commission_percentage'] ??
                    0)
                    .toDouble();
                if (baseSalary == 0 && commRate == 0) {
                  double oldVal =
                  (data['commission'] ?? data['value'] ?? 0).toDouble();
                  if (empType == "Commission")
                    commRate = oldVal;
                  else
                    baseSalary = oldVal;
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
                  if (transSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(color: kGoldDark));
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
                          _buildHeader(context, prov, empType, employeeId,
                              baseSalary, commRate),
                          const SizedBox(height: 10),
                          Expanded(
                            child: prov.filteredDocs.isEmpty
                                ? const Center(
                                child: Text("No records found.",
                                    style:
                                    TextStyle(color: kCharcoal)))
                                : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              itemCount: prov.filteredDocs.length,
                              itemBuilder: (context, index) {
                                final data =
                                prov.filteredDocs[index].data()
                                as Map<String, dynamic>;
                                return _buildTransactionItem(
                                    context,
                                    data,
                                    prov.filteredDocs[index].id);
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

  Widget _buildHeader(
      BuildContext context,
      EmployeeDetailsProvider prov,
      String type,
      String employeeId,
      double baseSalary,
      double commRate) {
    String earningsLabel = type == "Commission"
        ? "Earned Comm."
        : (type == "Fixed Salary" ? "Fixed Salary" : "Salary + Comm.");

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30)),
        boxShadow: [
          BoxShadow(color: kGoldDark.withOpacity(0.1), blurRadius: 10)
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 25),
      child: Column(
        children: [
          Text(
              filterType == "Custom"
                  ? "Selected Range Report"
                  : "Report for $dateFilter",
              style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
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
              _adjustmentBox(context, "Advance", prov.totalAdvance,
                  kGoldPrimary, Icons.add_circle_outline),
              const SizedBox(width: 12),
              _adjustmentBox(context, "Deduction", prov.totalDeduction,
                  kCharcoal, Icons.remove_circle_outline),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient:
              const LinearGradient(colors: [kGoldPrimary, kGoldDark]),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                    color: kGoldDark.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("NET SETTLEMENT",
                        style: TextStyle(
                            color: kWhite.withOpacity(0.7),
                            fontWeight: FontWeight.bold,
                            fontSize: 10)),
                    const Text("Final Take Home",
                        style: TextStyle(
                            color: kWhite,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                  ],
                ),
                Text("Rs ${prov.finalTakeHome.toStringAsFixed(0)}",
                    style: const TextStyle(
                        color: kWhite,
                        fontSize: 24,
                        fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          if (filterType == "Monthly" || filterType == "Daily")
            _buildPayrollButton(
                context, prov, employeeId, baseSalary, commRate, type),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // ✅ FIXED: Payroll Button
  // isSalaryPaidThisMonth() HATAYA — ab provder ka isPaidThisMonth use
  // + FutureBuilder se Firestore check (ek baar, properly)
  // ══════════════════════════════════════════════════════════════════
  Widget _buildPayrollButton(
      BuildContext context,
      EmployeeDetailsProvider prov,
      String employeeId,
      double baseSalary,
      double commRate,
      String empType) {
    final adminProv = Provider.of<AdminProvider>(context, listen: false);
    final String monthYear = adminProv.getPreviousMonthYear(DateTime.now());
    final String displayMonth = _getReadableMonth(monthYear);

    return Padding(
      padding: const EdgeInsets.only(top: 15),
      child: FutureBuilder<void>(
        // ✅ Provider se payment status check karo (Firestore query)
        future: prov.checkPaymentStatus(staffName, monthYear),
        builder: (context, snapshot) {
          // Loading ke dauran existing state use karo
          final bool isPaid = prov.isPaidThisMonth;

          if (isPaid) {
            return _buildPaidBadge(
                context, prov, displayMonth, monthYear,
                baseSalary, commRate, empType);
          }

          if (prov.isProcessing) {
            return const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ));
          }

          return ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: kGoldDark,
              foregroundColor: kWhite,
              elevation: 5,
              shadowColor: kGoldDark.withOpacity(0.3),
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
            ),
            icon: const Icon(Icons.receipt_long_rounded, size: 20),
            label: const Text("PROCESS PAYROLL",
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    letterSpacing: 1)),
            onPressed: () => _showFinalPayslipAndPayDialog(
                context, prov, employeeId,
                baseSalary: baseSalary,
                commRate: commRate,
                empType: empType),
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // ✅ PAID Badge
  // ══════════════════════════════════════════════════════════════════
  Widget _buildPaidBadge(
      BuildContext context,
      EmployeeDetailsProvider prov,
      String displayMonth,
      String monthYear,
      double baseSalary,
      double commRate,
      String empType) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding:
          const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade600, Colors.green.shade800],
            ),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("SALARY PAID ✓",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              letterSpacing: 1)),
                      Text(displayMonth,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 11)),
                    ],
                  ),
                ],
              ),
              Text("Rs ${prov.paidAmount}",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  elevation: 3,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.send_rounded, size: 20),
                label: const Text("Share Receipt",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                onPressed: () =>
                    _shareWhatsAppReceipt(context, prov, displayMonth),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 1,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: kGoldDark,
                  side: const BorderSide(color: kGoldDark),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text("Re-Pay",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 12)),
                onPressed: () => _showFinalPayslipAndPayDialog(
                    context, prov, "",
                    baseSalary: baseSalary,
                    commRate: commRate,
                    empType: empType),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // ✅ FIXED: Payslip Dialog
  // Consumer HATAYA → FutureBuilder lagaya
  // Ab slip guaranteed dikhegi — infinite spinner fix!
  // ══════════════════════════════════════════════════════════════════
  void _showFinalPayslipAndPayDialog(
      BuildContext context, EmployeeDetailsProvider prov, String employeeId,
      {required double baseSalary,
        required double commRate,
        required String empType}) {
    final adminProv = Provider.of<AdminProvider>(context, listen: false);
    final String accountingMonthYear =
    adminProv.getPreviousMonthYear(DateTime.now());
    final String displayMonth = _getReadableMonth(accountingMonthYear);

    String selectedMethod = 'Cash';
    final TextEditingController refController = TextEditingController();

    // ✅ Future pehle banao — dialog open hone SE PEHLE
    // Yeh ensure karta hai Future sirf ek baar run ho
    final Future<bool> payrollFuture = prov.calculatePreviousMonthPayroll(
      staffName: staffName,
      empType: empType,
      baseSalary: baseSalary,
      commRate: commRate,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Column(
              children: [
                const Center(
                    child: Text("Official Payslip",
                        style: TextStyle(fontWeight: FontWeight.w900))),
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: const Color(0xFFD4AF37).withOpacity(0.4)),
                    ),
                    child: Text(
                      "📅 Accounting: $displayMonth",
                      style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFC69C34),
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ✅ FutureBuilder — Consumer ki jagah
                  FutureBuilder<bool>(
                    future: payrollFuture,
                    builder: (context, snapshot) {
                      // ── Loading ──
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const SizedBox(
                          height: 100,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(
                                    color: kGoldDark),
                                SizedBox(height: 12),
                                Text("Loading payroll data...",
                                    style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                        );
                      }

                      // ── Error / Timeout ──
                      if (snapshot.hasError ||
                          snapshot.data == false) {
                        return SizedBox(
                          height: 120,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.wifi_off_rounded,
                                    color: Colors.red, size: 36),
                                const SizedBox(height: 8),
                                const Text(
                                    "Data load nahi hua.\nInternet check karo.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 12)),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context),
                                  child: const Text("Close"),
                                )
                              ],
                            ),
                          ),
                        );
                      }

                      // ── Success: Payslip ──
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: Colors.grey.shade300, width: 1.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(staffName.toUpperCase(),
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                            Text("Period: $displayMonth",
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 12)),
                            const Divider(thickness: 1),
                            _payslipRow("Total Approved Sales",
                                prov.prevMonthTotalSales),
                            if (empType == "Commission" ||
                                empType == "Both")
                              _payslipRow(
                                  "Commission (${commRate.toStringAsFixed(0)}%)",
                                  prov.prevMonthCommission),
                            if (empType == "Fixed Salary" ||
                                empType == "Both")
                              _payslipRow("Base Salary",
                                  prov.prevMonthBaseSalary),
                            if (prov.prevMonthAdvance > 0)
                              _payslipRow("Advance Deduction",
                                  prov.prevMonthAdvance,
                                  isNegative: true),
                            if (prov.prevMonthDeduction > 0)
                              _payslipRow("Other Deduction",
                                  prov.prevMonthDeduction,
                                  isNegative: true),
                            const Divider(
                                thickness: 1.5, color: Colors.black),
                            _payslipRow(
                                "NET PAYABLE", prov.prevMonthFinalPay,
                                isNet: true),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: selectedMethod,
                    decoration: InputDecoration(
                        labelText: "Payment Method",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12))),
                    items: [
                      'Cash',
                      'Bank Transfer',
                      'JazzCash',
                      'EasyPaisa'
                    ]
                        .map((m) =>
                        DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (v) =>
                        setDialogState(() => selectedMethod = v!),
                  ),
                  const SizedBox(height: 10),
                  if (selectedMethod != 'Cash')
                    TextField(
                      controller: refController,
                      decoration: InputDecoration(
                        labelText: "Transaction Reference ID",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel")),
              // ✅ FutureBuilder for DISBURSE button too
              FutureBuilder<bool>(
                future: payrollFuture,
                builder: (context, snapshot) {
                  final bool isReady =
                      snapshot.connectionState == ConnectionState.done &&
                          snapshot.data == true;
                  return ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isReady
                          ? Colors.green.shade700
                          : Colors.grey.shade300,
                      foregroundColor:
                      isReady ? Colors.white : Colors.grey,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.payments_rounded),
                    label: const Text("DISBURSE SALARY",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    // ✅ Button tab tak disabled jab tak data ready na ho
                    onPressed: !isReady
                        ? null
                        : () async {
                      if (selectedMethod != 'Cash' &&
                          refController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                Text("Please enter Reference ID"),
                                backgroundColor: Colors.orange));
                        return;
                      }

                      Navigator.pop(context);
                      prov.setProcessing(true);

                      try {
                        final double finalAmount =
                        prov.prevMonthFinalPay > 0
                            ? prov.prevMonthFinalPay
                            : 0;

                        // employeeId empty = Re-Pay case
                        if (employeeId.isNotEmpty) {
                          await adminProv.markSalaryAsPaid(
                            employeeId: employeeId,
                            employeeName: staffName,
                            salaryAmount: finalAmount,
                            paymentMethod: selectedMethod,
                            transactionRef:
                            refController.text.trim(),
                            monthYear: accountingMonthYear,
                          );
                        }

                        await prov.markAsPaid(
                          staffName: staffName,
                          amount: finalAmount,
                          monthYear: accountingMonthYear,
                        );

                        prov.setProcessing(false);

                        if (context.mounted) {
                          _showPaymentSuccessDialog(
                              context,
                              prov,
                              displayMonth,
                              finalAmount,
                              selectedMethod);
                        }
                      } catch (e) {
                        prov.setProcessing(false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(
                              content: Text("Error: $e"),
                              backgroundColor: Colors.red));
                        }
                      }
                    },
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // ✅ Payment Success Dialog
  // ══════════════════════════════════════════════════════════════════
  void _showPaymentSuccessDialog(BuildContext context,
      EmployeeDetailsProvider prov, String displayMonth,
      double amount, String method) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: Colors.green, size: 60),
            ),
            const SizedBox(height: 15),
            const Text("Salary Disbursed!",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.green)),
            const SizedBox(height: 8),
            Text("Rs ${amount.toStringAsFixed(0)} paid to $staffName",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
            Text("Period: $displayMonth",
                style:
                const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close",
                  style: TextStyle(color: Colors.grey))),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
            ),
            icon: const Icon(Icons.send_rounded),
            label: const Text("Share on WhatsApp",
                style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.pop(context);
              _shareWhatsAppReceipt(context, prov, displayMonth);
            },
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // ✅ WhatsApp Share (share_plus)
  // ══════════════════════════════════════════════════════════════════
  void _shareWhatsAppReceipt(BuildContext context,
      EmployeeDetailsProvider prov, String displayMonth) {
    final String message = "💈 *SALARY RECEIPT*\n"
        "━━━━━━━━━━━━━━━━━━━━\n"
        "👤 *Employee:* $staffName\n"
        "📅 *Period:* $displayMonth\n"
        "━━━━━━━━━━━━━━━━━━━━\n"
        "💰 *Amount Paid:* Rs ${prov.paidAmount}\n"
        "💳 *Method:* ${prov.paidMethod.isEmpty ? 'Cash' : prov.paidMethod}\n"
        "✅ *Status:* PAID\n"
        "━━━━━━━━━━━━━━━━━━━━\n"
        "✂️ Barber Pro - Staff Management";

    Share.share(message, subject: "Salary Receipt - $staffName");
  }

  String _getReadableMonth(String monthYear) {
    try {
      final parts = monthYear.split('-');
      if (parts.length < 2) return monthYear;
      final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]), 1);
      return DateFormat('MMMM yyyy').format(dt);
    } catch (_) {
      return monthYear;
    }
  }

  Widget _payslipRow(String title, double amount,
      {bool isNegative = false, bool isNet = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(title,
                style: TextStyle(
                    fontSize: isNet ? 14 : 12,
                    fontWeight:
                    isNet ? FontWeight.w900 : FontWeight.normal,
                    color: Colors.black54)),
          ),
          Text(
            "${isNegative ? "-" : ""}Rs ${amount.toStringAsFixed(0)}",
            style: TextStyle(
              fontSize: isNet ? 18 : 13,
              fontWeight: isNet ? FontWeight.w900 : FontWeight.bold,
              color: isNegative
                  ? Colors.red
                  : (isNet ? const Color(0xFFD4AF37) : Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBox(String title, double val, Color col) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: col.withOpacity(0.05),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: col.withOpacity(0.1))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold)),
            Text("Rs ${val.toStringAsFixed(0)}",
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: col)),
          ],
        ),
      ),
    );
  }

  Widget _adjustmentBox(BuildContext context, String title, double val,
      Color col, IconData icon) {
    return Expanded(
      child: InkWell(
        onTap: () => _showAdjustmentDialog(context, title),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: col.withOpacity(0.05),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: col.withOpacity(0.1))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold)),
                  Text("Rs ${val.toStringAsFixed(0)}",
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: col)),
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
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text("Add $type",
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: kCharcoal)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: "Amount",
                  labelStyle: TextStyle(color: kGoldDark),
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: kGoldDark))),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                  labelText: "Reason (Optional)",
                  labelStyle: TextStyle(color: kGoldDark),
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: kGoldDark))),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor:
                type == "Advance" ? kGoldPrimary : kCharcoal),
            onPressed: () {
              if (amountController.text.isNotEmpty) {
                Provider.of<EmployeeDetailsProvider>(context,
                    listen: false)
                    .addAdjustment(
                  staffName: staffName,
                  amount: double.parse(amountController.text),
                  type: type,
                  reason: reasonController.text,
                );
                Navigator.pop(context);
              }
            },
            child: const Text("Confirm",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(
      BuildContext context, Map<String, dynamic> data, String docId) {
    final bool isApproved =
        (data['status'] ?? "Unapproved") == "Approved";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: kGoldDark.withOpacity(0.1), blurRadius: 5)
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "${data['dateOnly'] ?? ''} | ${data['time'] ?? 'N/A'}",
                  style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                "Rs ${data['totalPrice'] ?? 0}",
                style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: kGoldDark,
                    fontSize: 16),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: () => _showDeleteDialog(context, docId),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.red.withOpacity(0.25)),
                  ),
                  child: const Icon(Icons.delete_outline_rounded,
                      color: Colors.red, size: 18),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          _buildServiceChips(data),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor:
                      isApproved ? kGoldDark : kCharcoal,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding:
                      const EdgeInsets.symmetric(vertical: 12)),
                  onPressed: () => _showApproveDialog(
                      context, docId, data['status'] ?? "Unapproved"),
                  child: Text(
                      isApproved ? "Approved ✓" : "Review & Approve",
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 10),
              if (!isApproved)
                Expanded(
                  flex: 1,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: kGoldLight,
                        foregroundColor: kGoldDark,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                                color: kGoldPrimary.withOpacity(0.5))),
                        padding:
                        const EdgeInsets.symmetric(vertical: 12)),
                    onPressed: () =>
                        _showEditDialog(context, docId, data),
                    child: const Icon(Icons.edit_note_rounded, size: 24),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_forever_rounded,
                  color: Colors.red, size: 22),
            ),
            const SizedBox(width: 10),
            const Text("Delete Entry",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.red)),
          ],
        ),
        content: const Text(
          "Are you sure you want to permanently delete this transaction entry",
          style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.5),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel",
                  style: TextStyle(color: Colors.grey))),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
            ),
            icon: const Icon(Icons.delete_rounded, size: 16),
            label: const Text("Delete",
                style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirebaseFirestore.instance
                    .collection('transactions')
                    .doc(docId)
                    .delete();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("✓ Entry successfully deleted!"),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text("Error: $e"),
                        backgroundColor: Colors.red),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildServiceChips(Map<String, dynamic> data) {
    dynamic rawServices =
        data['selectedServices'] ?? data['services'] ?? [];
    List<String> serviceNames = [];
    if (rawServices is List) {
      for (var s in rawServices) {
        serviceNames.add(s is Map ? (s['name'] ?? "") : s.toString());
      }
    }
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: serviceNames
          .map((s) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: kGoldLight,
            borderRadius: BorderRadius.circular(8)),
        child: Text(s,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: kCharcoal)),
      ))
          .toList(),
    );
  }

  void _showEditDialog(
      BuildContext context, String docId, Map<String, dynamic> data) {
    final TextEditingController priceController =
    TextEditingController(text: (data['totalPrice'] ?? 0).toString());
    dynamic rawServices =
        data['selectedServices'] ?? data['services'] ?? [];
    List<Map<String, dynamic>> servicesList = [];
    if (rawServices is List) {
      for (var s in rawServices) {
        if (s is Map) {
          servicesList.add(Map<String, dynamic>.from(s));
        } else {
          servicesList.add({'name': s.toString(), 'price': 0});
        }
      }
    }
    List<TextEditingController> nameControllers = servicesList
        .map((s) =>
        TextEditingController(text: s['name']?.toString() ?? ''))
        .toList();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: const Text("Edit Transaction",
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: kCharcoal)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: priceController,
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: "Final Total Price",
                      prefixText: "Rs ",
                      labelStyle: TextStyle(color: kGoldDark),
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                          borderSide:
                          BorderSide(color: kGoldDark, width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Packages / Services:",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: kCharcoal)),
                      GestureDetector(
                        onTap: () => setState(() {
                          servicesList.add({'name': '', 'price': 0});
                          nameControllers.add(TextEditingController());
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                              color: kCharcoal,
                              borderRadius: BorderRadius.circular(8)),
                          child: const Row(children: [
                            Icon(Icons.add, color: kGoldPrimary, size: 14),
                            SizedBox(width: 4),
                            Text("Add",
                                style: TextStyle(
                                    color: kGoldPrimary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ]),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (servicesList.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('No services. Tap "Add" to add one.',
                          style:
                          TextStyle(color: Colors.grey, fontSize: 12)),
                    ),
                  ...List.generate(servicesList.length, (idx) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: nameControllers[idx],
                              style: const TextStyle(
                                  fontSize: 13, color: kCharcoal),
                              decoration: const InputDecoration(
                                labelText: "Service name",
                                labelStyle: TextStyle(
                                    color: kGoldDark, fontSize: 12),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => setState(() {
                              servicesList.removeAt(idx);
                              nameControllers.removeAt(idx);
                            }),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8)),
                              child: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.red,
                                  size: 18),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 6),
                  const Text(
                      "Note: Edited names and price will be saved.",
                      style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: kGoldDark),
                onPressed: () async {
                  if (priceController.text.isNotEmpty) {
                    for (int i = 0; i < servicesList.length; i++) {
                      servicesList[i]['name'] =
                          nameControllers[i].text.trim();
                    }
                    final double newPrice =
                        double.tryParse(priceController.text) ?? 0;
                    await FirebaseFirestore.instance
                        .collection('transactions')
                        .doc(docId)
                        .update({
                      'totalPrice': newPrice,
                      'selectedServices': servicesList,
                      'adminEdited': true,
                    });
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                child: const Text("Save All",
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showApproveDialog(
      BuildContext context, String docId, String status) {
    String newStatus =
    (status == "Approved") ? "Unapproved" : "Approved";
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Confirm Status Change",
              style: TextStyle(color: kCharcoal)),
          content:
          Text("Do you want to change status to $newStatus?"),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel")),
            ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await FirebaseFirestore.instance
                      .collection('transactions')
                      .doc(docId)
                      .update({'status': newStatus});
                },
                child: const Text("Confirm")),
          ],
        ));
  }
}

// ─── AdjustmentHistoryScreen ──────────────────────────────────────────────────
class AdjustmentHistoryScreen extends StatelessWidget {
  final String staffName;
  final List<QueryDocumentSnapshot> adjustments;

  static const Color kBg = Color(0xFFFFFDE7);
  static const Color kGoldLight = Color(0xFFF3E5AB);
  static const Color kGoldPrimary = Color(0xFFD4AF37);
  static const Color kCharcoal = Color(0xFF2C2C2C);

  const AdjustmentHistoryScreen(
      {super.key, required this.staffName, required this.adjustments});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: Text("$staffName's Ledger History",
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: kCharcoal)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: kCharcoal,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("Advances & Deductions",
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey)),
            ),
            adjustments.isEmpty
                ? const Center(
                child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text("No record found.")))
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: adjustments.length,
              itemBuilder: (context, index) {
                final data = adjustments[index].data()
                as Map<String, dynamic>;
                final bool isAdvance =
                    (data['type'] ?? "Advance") == "Advance";
                DateTime? date;
                try {
                  if (data['date'] != null)
                    date = DateTime.tryParse(data['date'].toString());
                } catch (_) {}
                final DateTime displayDate = date ?? DateTime.now();
                Color itemColor =
                isAdvance ? kGoldPrimary : kCharcoal;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                            color: itemColor.withOpacity(0.1),
                            blurRadius: 10)
                      ]),
                  child: ListTile(
                    leading: CircleAvatar(
                        backgroundColor: itemColor.withOpacity(0.1),
                        child: Icon(
                            isAdvance
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                            color: itemColor)),
                    title: Text(
                        isAdvance
                            ? "Advance Taken"
                            : "Salary Deduction",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: kCharcoal)),
                    subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['reason'] ?? "No reason",
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                          Text(
                              DateFormat('dd MMM yyyy | hh:mm a')
                                  .format(displayDate),
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.grey))
                        ]),
                    trailing: Text("Rs ${data['amount'] ?? 0}",
                        style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: itemColor)),
                  ),
                );
              },
            ),
            const Divider(thickness: 2),
            const Padding(
              padding: EdgeInsets.fromLTRB(16.0, 20, 16, 10),
              child: Text("Salary Payout History",
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey)),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('employee_history')
                  .where('employeeName', isEqualTo: staffName.trim())
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                  return const Padding(
                      padding: EdgeInsets.all(20),
                      child:
                      Center(child: Text("No payout record found.")));
                List<QueryDocumentSnapshot> docs = snapshot.data!.docs;
                docs.sort((a, b) {
                  final dataA = a.data() as Map<String, dynamic>;
                  final dataB = b.data() as Map<String, dynamic>;
                  return (dataB['date'] as Timestamp)
                      .compareTo(dataA['date'] as Timestamp);
                });
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data =
                    docs[index].data() as Map<String, dynamic>;
                    DateTime date =
                    (data['date'] as Timestamp).toDate();
                    final String monthYear = data['monthYear'] ?? "";
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                                color: kGoldPrimary.withOpacity(0.1),
                                blurRadius: 10)
                          ]),
                      child: ListTile(
                        leading: CircleAvatar(
                            backgroundColor: kGoldPrimary.withOpacity(0.1),
                            child: const Icon(Icons.payments_outlined,
                                color: kGoldPrimary)),
                        title: Text("Salary Disbursed ✓",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.green.shade700)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (monthYear.isNotEmpty)
                              Text("Period: $monthYear",
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.grey)),
                            Text(
                                DateFormat('dd MMM yyyy | hh:mm a')
                                    .format(date),
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                        trailing: Text("Rs ${data['amount'] ?? 0}",
                            style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                color: kGoldPrimary)),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}