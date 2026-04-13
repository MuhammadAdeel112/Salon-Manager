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
    this.customRange,
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
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: TextStyle(color: Colors.red)));
          }

          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator(color: kGoldDark));
          }

          var filtered = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>?;

            // Safe check: agar data null ho ya dateOnly missing ho to skip
            if (data == null || !data.containsKey('dateOnly') || data['dateOnly'] == null) {
              return false;
            }

            String docDate = (data['dateOnly'] as String).trim();

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

              // Safe access
              String description = data['description']?.toString() ?? "No Detail";
              String dateOnly = data['dateOnly']?.toString() ?? "N/A";
              double amount = (data['amount'] as num?)?.toDouble() ?? 0.0;

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
                color: Colors.white,
                shadowColor: kGoldDark.withValues(alpha: 0.1),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: kGoldLight,
                    child: Icon(Icons.money_off, color: kGoldDark),
                  ),
                  title: Text(description, style: TextStyle(fontWeight: FontWeight.bold, color: kCharcoal)),
                  subtitle: Text(dateOnly, style: TextStyle(color: kGoldDark)),
                  trailing: Text(
                    "Rs ${amount.toStringAsFixed(0)}",
                    style: TextStyle(color: kCharcoal, fontWeight: FontWeight.bold, fontSize: 16),
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