import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageServices extends StatelessWidget {
  const ManageServices({super.key});

  // --- GOLDEN PALETTE ---
  final Color kBg = const Color(0xFFFFFDE7);
  final Color kGoldLight = const Color(0xFFF3E5AB);
  final Color kGoldPrimary = const Color(0xFFD4AF37);
  final Color kGoldDark = const Color(0xFFC69C34);
  final Color kCharcoal = const Color(0xFF2C2C2C);
  final Color kWhite = Colors.white;

  void _confirmDelete(BuildContext context, String docId, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text("Delete Service?", style: TextStyle(color: kCharcoal, fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to remove '$name'?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCEL", style: TextStyle(color: Colors.grey))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, elevation: 0),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('services').doc(docId).delete();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("$name deleted", style: const TextStyle(color: Colors.white)),
                  backgroundColor: kCharcoal,
                ),
              );
            },
            child: const Text("DELETE", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: Text("Service Management",
            style: TextStyle(fontWeight: FontWeight.w800, color: kCharcoal, fontSize: 18)),
        backgroundColor: kWhite,
        foregroundColor: kCharcoal,
        elevation: 0.5,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('services').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator(color: kGoldDark));

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];

              // --- FIX: SAFE DATA ACCESS ---
              // Hum data ko Map mein convert kar rahe hain aur check kar rahe hain ke fields exist karti hain ya nahi
              Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

              String sName = (data != null && data.containsKey('name')) ? data['name'] : "Unnamed Service";
              String sStatus = (data != null && data.containsKey('status')) ? data['status'] : "Unknown";
              String sPrice = (data != null && data.containsKey('price')) ? data['price'].toString() : "0";

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: kWhite,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: kGoldDark.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: kGoldLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.auto_fix_high_rounded, color: kGoldDark, size: 24),
                  ),
                  title: Text(sName,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: kCharcoal)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text("Status: $sStatus",
                        style: TextStyle(fontSize: 12, color: kGoldDark, fontWeight: FontWeight.w500)),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: kGoldPrimary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text("PKR $sPrice",
                            style: TextStyle(fontWeight: FontWeight.w800, color: kCharcoal, fontSize: 13)),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
                        onPressed: () => _confirmDelete(context, doc.id, sName),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: kCharcoal,
        onPressed: () => _showAddServiceDialog(context, nameController, priceController),
        label: Text("NEW SERVICE",
            style: TextStyle(fontWeight: FontWeight.bold, color: kGoldPrimary, letterSpacing: 1)),
        icon: Icon(Icons.add, color: kGoldPrimary),
      ),
    );
  }

  void _showAddServiceDialog(BuildContext context, TextEditingController nameController, TextEditingController priceController) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Add New Service", style: TextStyle(fontWeight: FontWeight.bold, color: kCharcoal)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameController,
                decoration: _inputDecoration("Service Name", Icons.edit_note_rounded)
            ),
            const SizedBox(height: 15),
            TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration("Price (PKR)", Icons.payments_outlined)
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCEL", style: TextStyle(color: Colors.grey))
          ),
          SizedBox(
            width: 120,
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kCharcoal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  if (nameController.text.isNotEmpty && priceController.text.isNotEmpty) {
                    await FirebaseFirestore.instance.collection('services').add({
                      'name': nameController.text,
                      'price': double.parse(priceController.text),
                      'status': 'Active'
                    });
                    nameController.clear();
                    priceController.clear();
                    Navigator.pop(context);
                  }
                },
                child: Text("ADD", style: TextStyle(color: kGoldPrimary, fontWeight: FontWeight.bold))
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: kGoldDark),
      prefixIcon: Icon(icon, color: kGoldDark, size: 20),
      filled: true,
      fillColor: const Color(0xFFF9F9F9),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: kGoldPrimary, width: 1.5)),
    );
  }
}