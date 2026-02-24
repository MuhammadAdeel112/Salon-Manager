import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdjustmentHistoryScreen extends StatelessWidget {
  final String staffName;
  final List<QueryDocumentSnapshot> adjustments;

  // --- GOLDEN PALETTE (Maintaining App Theme) ---
  final Color kBg = const Color(0xFFFFFDE7);
  final Color kGoldLight = const Color(0xFFF3E5AB);
  final Color kGoldPrimary = const Color(0xFFD4AF37);
  final Color kGoldDark = const Color(0xFFC69C34);
  final Color kCharcoal = const Color(0xFF2C2C2C);
  final Color kWhite = Colors.white;

  const AdjustmentHistoryScreen({
    super.key,
    required this.staffName,
    required this.adjustments,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: Text("$staffName's History", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kCharcoal)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: kCharcoal,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SECTION 1: ADVANCES & DEDUCTIONS ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text("Advances & Deductions", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
            ),
            adjustments.isEmpty
                ? Center(child: Padding(padding: const EdgeInsets.all(20), child: Text("No adjustments found.", style: TextStyle(color: kCharcoal))))
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: adjustments.length,
              itemBuilder: (context, index) {
                // 1. Safe Casting
                final data = adjustments[index].data() as Map<String, dynamic>? ?? {};

                // 2. Safe Type Check
                final bool isAdvance = (data['type'] ?? "Advance") == "Advance";

                // 3. SAFE DATE PARSING (Fixed to handle Timestamps properly)
                DateTime displayDate;
                try {
                  if (data['date'] != null) {
                    if (data['date'] is Timestamp) {
                      displayDate = (data['date'] as Timestamp).toDate();
                    } else {
                      displayDate = DateTime.parse(data['date'].toString());
                    }
                  } else {
                    displayDate = DateTime.now();
                  }
                } catch (e) {
                  displayDate = DateTime.now();
                }

                // Theme Colors
                Color itemColor = isAdvance ? kGoldPrimary : kCharcoal;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [BoxShadow(color: itemColor.withOpacity(0.1), blurRadius: 10)],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: itemColor.withOpacity(0.1),
                      child: Icon(
                        isAdvance ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                        color: itemColor,
                      ),
                    ),
                    title: Text(
                      isAdvance ? "Advance Taken" : "Salary Deduction",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kCharcoal),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(data['reason']?.toString() ?? "No reason provided", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(DateFormat('dd MMM yyyy | hh:mm a').format(displayDate), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                    trailing: Text(
                      "Rs ${data['amount'] ?? 0}",
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: itemColor),
                    ),
                  ),
                );
              },
            ),

            // --- SECTION 2: SALARY PAYMENTS HISTORY ---
            const Divider(thickness: 2),
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 20, 16, 10),
              child: Text("Salary Payments", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('employee_history')
                  .where('employeeName', isEqualTo: staffName.trim()) // FIX: Added .trim()
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Padding(padding: EdgeInsets.all(20), child: Center(child: Text("No payment history found.", style: TextStyle(color: Colors.grey))));
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;

                    // Safe Date Parsing for Salary History
                    DateTime date;
                    try {
                      if (data['date'] is Timestamp) {
                        date = (data['date'] as Timestamp).toDate();
                      } else {
                        date = DateTime.parse(data['date'].toString());
                      }
                    } catch (e) {
                      date = DateTime.now();
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [BoxShadow(color: kGoldPrimary.withOpacity(0.1), blurRadius: 10)],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: kGoldPrimary.withOpacity(0.1),
                          child: Icon(Icons.payments_outlined, color: kGoldPrimary),
                        ),
                        title: Text("Salary Paid", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kCharcoal)),
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