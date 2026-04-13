import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmployeeDetailsScreen extends StatelessWidget {
  final String staffName;
  final String dateFilter;

  const EmployeeDetailsScreen({
    super.key,
    required this.staffName,
    required this.dateFilter,
  });

  // --- GOLDEN PALETTE ---
  final Color kBg = const Color(0xFFFFFDE7);
  final Color kGoldLight = const Color(0xFFF3E5AB);
  final Color kGoldPrimary = const Color(0xFFD4AF37);
  final Color kGoldDark = const Color(0xFFC69C34);
  final Color kCharcoal = const Color(0xFF2C2C2C);

  void _toggleStatus(String docId, String currentStatus) async {
    String newStatus = (currentStatus == "Approved") ? "Unapproved" : "Approved";
    await FirebaseFirestore.instance
        .collection('transactions')
        .doc(docId)
        .update({'status': newStatus});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg, // Golden Background
      appBar: AppBar(
        title: Column(
          children: [
            Text(staffName.toUpperCase(),
                style: TextStyle(color: kCharcoal, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1)),
            Text(dateFilter,
                style: TextStyle(color: kGoldDark, fontSize: 12, fontWeight: FontWeight.w400)), // Gold date
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: kCharcoal),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('transactions')
            .where('staffName', isEqualTo: staffName)
            .where('dateOnly', isEqualTo: dateFilter)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator(color: kGoldDark));

          var docs = snapshot.data!.docs;
          if (docs.isEmpty) return Center(child: Text("No entries found", style: TextStyle(color: kCharcoal)));

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: kGoldDark.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Column(
                children: [
                  // --- HEADER ---
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                    decoration: BoxDecoration(
                      color: kGoldLight.withValues(alpha: 0.4), // Light Gold Header
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                    ),
                    child: Row(
                      children: [
                        Expanded(flex: 2, child: Text("TIME", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: kCharcoal))),
                        Expanded(flex: 3, child: Text("SERVICE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: kCharcoal))),
                        Expanded(flex: 2, child: Text("PRICE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: kCharcoal))),
                        Expanded(flex: 3, child: Text("STATUS", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: kCharcoal))),
                      ],
                    ),
                  ),
                  // --- ROWS ---
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: docs.length,
                    separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[100]),
                    itemBuilder: (context, index) {
                      var data = docs[index].data() as Map<String, dynamic>;
                      String status = data['status'] ?? "Unapproved";
                      List services = data['selectedServices'] ?? data['services'] ?? [];
                      bool isApproved = status == "Approved";

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                        child: Row(
                          children: [
                            Expanded(flex: 2, child: Text(data['time'] ?? "N/A", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: kCharcoal))),
                            Expanded(flex: 3, child: Text(services.join(", "), style: TextStyle(fontSize: 12, color: kCharcoal), maxLines: 2, overflow: TextOverflow.ellipsis)),
                            Expanded(flex: 2, child: Text(data['totalPrice'].toString(), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kGoldDark))), // Gold Price
                            Expanded(
                              flex: 3,
                              child: InkWell(
                                onTap: () => _toggleStatus(docs[index].id, status),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  decoration: BoxDecoration(
                                    // Approved: Gold Theme, Unapproved: White/Gray
                                    color: isApproved ? kGoldLight : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: isApproved ? kGoldPrimary : Colors.grey.shade300, width: 1),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(isApproved ? Icons.check : Icons.close, size: 12, color: isApproved ? kGoldDark : Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(status, style: TextStyle(color: isApproved ? kCharcoal : Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}