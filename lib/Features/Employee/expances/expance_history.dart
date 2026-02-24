import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseHistoryScreen extends StatelessWidget {
  final String filterType;
  final String todayDate;
  final String currentMonth;
  final DateTimeRange? customRange;

  const ExpenseHistoryScreen({
    super.key,
    required this.filterType,
    required this.todayDate,
    required this.currentMonth,
    this.customRange
  });

  // --- GOLDEN PALETTE ---
  final Color kBg = const Color(0xFFFFFDE7);
  final Color kGoldLight = const Color(0xFFF3E5AB);
  final Color kGoldPrimary = const Color(0xFFD4AF37);
  final Color kGoldDark = const Color(0xFFC69C34);
  final Color kCharcoal = const Color(0xFF2C2C2C);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg, // Golden Background
      appBar: AppBar(
        title: Text("$filterType Expenses", style: TextStyle(fontWeight: FontWeight.bold, color: kCharcoal)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: kCharcoal,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('expenses')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator(color: kGoldDark));

          var filtered = snapshot.data!.docs.where((doc) {
            String docDate = doc['dateOnly'] ?? "";

            if (filterType == "Daily") {
              return docDate == todayDate;
            } else if (filterType == "Monthly") {
              return docDate.startsWith(currentMonth);
            } else if (filterType == "Custom" && customRange != null) {
              try {
                DateTime dt = DateTime.parse(docDate);
                return dt.isAfter(customRange!.start.subtract(const Duration(days: 1))) &&
                    dt.isBefore(customRange!.end.add(const Duration(days: 1)));
              } catch (e) {
                return false;
              }
            }
            return false;
          }).toList();

          if (filtered.isEmpty) {
            return Center(child: Text("No expenses found for this period.", style: TextStyle(color: kCharcoal)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              var data = filtered[index].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
                color: Colors.white,
                shadowColor: kGoldDark.withOpacity(0.1), // Gold Shadow
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: kGoldLight, // Gold background
                    child: Icon(Icons.money_off, color: kGoldDark), // Gold Icon
                  ),
                  title: Text(data['description'] ?? "No Detail",
                      style: TextStyle(fontWeight: FontWeight.bold, color: kCharcoal)),
                  subtitle: Text(data['dateOnly'] ?? "", style: TextStyle(color: kGoldDark)),
                  trailing: Text(
                      "Rs ${data['amount']}",
                      style: TextStyle(color: kCharcoal, fontWeight: FontWeight.bold, fontSize: 16) // Dark Amount
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}