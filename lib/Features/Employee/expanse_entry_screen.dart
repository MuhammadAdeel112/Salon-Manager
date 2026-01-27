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
      backgroundColor: const Color(0xFFF9FAFD),
      appBar: AppBar(
        title: Column(
          children: [
            Text(staffName.toUpperCase(),
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1)),
            Text(dateFilter,
                style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w400)),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('transactions')
            .where('staffName', isEqualTo: staffName)
            .where('dateOnly', isEqualTo: dateFilter)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          var docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("No entries found"));

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Column(
                children: [
                  // --- HEADER ---
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withOpacity(0.05),
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                    ),
                    child: const Row(
                      children: [
                        Expanded(flex: 2, child: Text("TIME", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.indigo))),
                        Expanded(flex: 3, child: Text("SERVICE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.indigo))),
                        Expanded(flex: 2, child: Text("PRICE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.indigo))),
                        Expanded(flex: 3, child: Text("STATUS", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.indigo))),
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
                            Expanded(flex: 2, child: Text(data['time'] ?? "N/A", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
                            Expanded(flex: 3, child: Text(services.join(", "), style: const TextStyle(fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis)),
                            Expanded(flex: 2, child: Text(data['totalPrice'].toString(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                            Expanded(
                              flex: 3,
                              child: InkWell(
                                onTap: () => _toggleStatus(docs[index].id, status),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isApproved ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: isApproved ? Colors.green : Colors.red, width: 0.5),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(isApproved ? Icons.check : Icons.close, size: 12, color: isApproved ? Colors.green : Colors.red),
                                      const SizedBox(width: 4),
                                      Text(status, style: TextStyle(color: isApproved ? Colors.green[700] : Colors.red[700], fontSize: 10, fontWeight: FontWeight.bold)),
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