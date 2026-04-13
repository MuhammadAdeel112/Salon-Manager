import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'entry_provider.dart';

// ═══════════════════════════════════════════════════════════════
// 🛠️ SERVICES CATALOG WIDGET
// Import: import 'services_catalog.dart';
// Use: ServicesCatalog(provider: provider, sw: sw, isTablet: isTablet, searchText: _searchText)
// ═══════════════════════════════════════════════════════════════

class ServicesCatalog extends StatelessWidget {
  final EntryProvider provider;
  final double sw;
  final bool isTablet;
  final String searchText;

  const ServicesCatalog({
    super.key,
    required this.provider,
    required this.sw,
    required this.isTablet,
    required this.searchText,
  });

  final Color kGoldLight = const Color(0xFFF8E9B0);
  final Color kGoldPrimary = const Color(0xFFD4AF37);
  final Color kGoldDark = const Color(0xFFAA8C2C);
  final Color kCharcoal = const Color(0xFF1F1F1F);

  void _showCustomServiceDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        elevation: 12,
        title: Text("Add Custom Service",
            style: TextStyle(color: kCharcoal, fontWeight: FontWeight.w800, fontSize: 20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: "Service Name",
                hintText: "e.g. Keratin Treatment",
                labelStyle: TextStyle(color: kGoldDark),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: kGoldPrimary, width: 2)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: kGoldLight)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Price (PKR)",
                hintText: "2500",
                labelStyle: TextStyle(color: kGoldDark),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: kGoldPrimary, width: 2)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: kGoldLight)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: TextStyle(color: kCharcoal))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: kGoldPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty && priceCtrl.text.trim().isNotEmpty) {
                provider.addService({
                  "name": nameCtrl.text.trim(),
                  "price": double.tryParse(priceCtrl.text) ?? 0.0
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Add Service"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int columns = sw >= 600 ? 5 : (sw >= 400 ? 4 : 3);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('services').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        var filtered = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return (data['name'] ?? "").toString().toLowerCase().contains(searchText.toLowerCase());
        }).toList();

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 100, top: 4),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: isTablet ? 10 : 8,
              mainAxisSpacing: isTablet ? 10 : 8,
              childAspectRatio: isTablet ? 1.0 : 0.88),
          itemCount: filtered.length + 1,
          itemBuilder: (context, index) {
            // ─── Custom Service Button ───
            if (index == filtered.length) {
              return GestureDetector(
                onTap: () => _showCustomServiceDialog(context),
                child: Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: kGoldPrimary.withValues(alpha: 0.35), width: 1.5),
                      boxShadow: [BoxShadow(color: kGoldDark.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 3))]),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(
                        width: isTablet ? 38 : 32,
                        height: isTablet ? 38 : 32,
                        decoration: BoxDecoration(color: kGoldLight, shape: BoxShape.circle),
                        child: Icon(Icons.add_rounded, color: kGoldDark, size: isTablet ? 22 : 18)),
                    SizedBox(height: isTablet ? 7 : 5),
                    Text("Custom", style: TextStyle(color: kGoldDark, fontWeight: FontWeight.w700, fontSize: isTablet ? 12 : 10)),
                  ]),
                ),
              );
            }

            // ─── Service Card ───
            final data = filtered[index].data() as Map<String, dynamic>;
            final String name = data['name'] ?? "N/A";
            final String price = data['price']?.toString() ?? "0";

            return GestureDetector(
              onTap: () => provider.addService({"name": name, "price": double.tryParse(price) ?? 0.0}),
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: kGoldDark.withValues(alpha: 0.07), blurRadius: 8, offset: const Offset(0, 3))]),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: isTablet ? 8 : 5),
                    child: Text(name,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: isTablet ? 13 : 11, color: kCharcoal, height: 1.2),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ),
                  SizedBox(height: isTablet ? 8 : 5),
                  Container(
                      padding: EdgeInsets.symmetric(horizontal: isTablet ? 10 : 7, vertical: isTablet ? 4 : 3),
                      decoration: BoxDecoration(color: kGoldLight, borderRadius: BorderRadius.circular(20)),
                      child: Text("Rs $price", style: TextStyle(color: kGoldDark, fontWeight: FontWeight.w800, fontSize: isTablet ? 12 : 10))),
                ]),
              ),
            );
          },
        );
      },
    );
  }
}