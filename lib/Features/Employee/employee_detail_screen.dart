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

  // FIX: Status must match exactly what Admin Dashboard is looking for ("Approved" vs "Unapproved")
  void _toggleStatus(String docId, String currentStatus) async {
    // Dashboard logic ke mutabiq "Unapproved" rakhen taake mismatch na ho
    String newStatus = (currentStatus == "Approved") ? "Unapproved" : "Approved";
    await FirebaseFirestore.instance
        .collection('transactions')
        .doc(docId)
        .update({'status': newStatus});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        title: Column(
          children: [
            Text(staffName.toUpperCase(),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
            Text(dateFilter, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
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
          if (docs.isEmpty) return const Center(child: Text("No records found."));

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              // Default value "Unapproved" rakhen
              String status = data['status'] ?? "Unapproved";
              bool isApproved = status == "Approved";

              dynamic rawServices = data['selectedServices'] ?? data['services'] ?? [];
              List<String> serviceNames = [];
              if (rawServices is List) {
                for (var s in rawServices) {
                  serviceNames.add(s is Map ? (s['name'] ?? "") : s.toString());
                }
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Table(
                    border: TableBorder.all(color: Colors.grey.shade200, width: 1),
                    columnWidths: const {
                      0: FlexColumnWidth(1),
                      1: FlexColumnWidth(2),
                    },
                    children: [
                      _tableRow("Time", data['time'] ?? "N/A"),
                      TableRow(
                        children: [
                          _cellTitle("Service & Price"),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Rs ${data['totalPrice']}",
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo, fontSize: 14)),
                                const Divider(height: 15),
                                ...serviceNames.map((s) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text("• $s", style: const TextStyle(fontSize: 12, color: Colors.black87)),
                                )),
                              ],
                            ),
                          ),
                        ],
                      ),
                      TableRow(
                        children: [
                          _cellTitle("Action"),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: InkWell(
                              onTap: () => _toggleStatus(docs[index].id, status),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: isApproved ? Colors.green : Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: isApproved ? Colors.green : Colors.red),
                                ),
                                child: Text(
                                  isApproved ? "Approved" : "Unapproved (Click to Approve)",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isApproved ? Colors.white : Colors.red,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  TableRow _tableRow(String title, String value) {
    return TableRow(
      children: [
        _cellTitle(title),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  Widget _cellTitle(String text) {
    return Container(
      color: Colors.grey.shade50,
      padding: const EdgeInsets.all(12),
      child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
    );
  }
}