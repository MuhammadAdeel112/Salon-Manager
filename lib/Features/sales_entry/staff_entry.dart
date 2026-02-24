import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'entry_provider.dart';

class StaffEntryScreen extends StatefulWidget {
  const StaffEntryScreen({super.key});

  @override
  _StaffEntryScreenState createState() => _StaffEntryScreenState();
}

class _StaffEntryScreenState extends State<StaffEntryScreen> {
  DateTime _selectedDate = DateTime.now();
  String _searchText = "";

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _expAmountController = TextEditingController();
  final TextEditingController _expNoteController = TextEditingController();

  // --- NEW GOLDEN PALETTE ---
  final Color kGoldLight = const Color(0xFFF3E5AB);
  final Color kGoldPrimary = const Color(0xFFD4AF37);
  final Color kGoldDark = const Color(0xFFAA8C2C);
  final Color kCharcoal = const Color(0xFF2C2C2C);
  final Color kWhite = Colors.white;

  @override
  void dispose() {
    _searchController.dispose();
    _expAmountController.dispose();
    _expNoteController.dispose();
    super.dispose();
  }

  void _showOtherServiceDialog(EntryProvider provider) {
    final TextEditingController nameCtrl = TextEditingController();
    final TextEditingController priceCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Custom Service", style: TextStyle(color: kCharcoal, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: "Service Name",
                hintText: "e.g. Extra Polish",
                labelStyle: TextStyle(color: kGoldDark),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: kGoldPrimary)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Price (Rs)",
                hintText: "0.00",
                labelStyle: TextStyle(color: kGoldDark),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: kGoldPrimary)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.red))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kGoldPrimary, elevation: 0),
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && priceCtrl.text.isNotEmpty) {
                provider.addService({
                  "name": nameCtrl.text,
                  "price": double.tryParse(priceCtrl.text) ?? 0.0
                });
                Navigator.pop(context);
              }
            },
            child: Text("Add", style: TextStyle(color: kWhite)),
          ),
        ],
      ),
    );
  }

  Future<void> _submitTransaction(EntryProvider provider) async {
    if (provider.selectedStaff == null || provider.selectedServicesList.isEmpty) return;

    final entryData = {
      'staffName': provider.selectedStaff,
      'services': List.from(provider.selectedServicesList),
      'totalPrice': provider.totalAmount,
      'status': "Unapproved",
      'timestamp': Timestamp.fromDate(_selectedDate),
      'dateOnly': DateFormat('yyyy-MM-dd').format(_selectedDate),
      'time': DateFormat('hh:mm a').format(DateTime.now()),
    };

    try {
      await FirebaseFirestore.instance.collection('transactions').add(entryData);
      provider.resetEntry();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Entry Saved!", style: TextStyle(color: kWhite)),
              backgroundColor: kCharcoal,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
          ),
        );
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  Future<void> _submitExpense(EntryProvider provider) async {
    if (_expAmountController.text.isEmpty) return;
    final amount = double.tryParse(_expAmountController.text) ?? 0;
    try {
      await FirebaseFirestore.instance.collection('expenses').add({
        'amount': amount,
        'description': _expNoteController.text,
        'dateOnly': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'timestamp': FieldValue.serverTimestamp(),
      });
      _expAmountController.clear();
      _expNoteController.clear();
      provider.toggleMode();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Expense Saved!", style: TextStyle(color: kWhite)),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
          ),
        );
      }
    } catch (e) {
      debugPrint("Expense Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EntryProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: Column(
        children: [
          _buildTopSummarySection(provider),
          Expanded(
            child: Container(
              color: const Color(0xFFF8F9FB),
              child: _buildBottomCatalog(provider),
            ),
          ),
        ],
      ),
      floatingActionButton: provider.isExpenseMode
          ? null
          : (provider.selectedServicesList.isNotEmpty && provider.selectedStaff != null
          ? FloatingActionButton.extended(
          onPressed: () => _submitTransaction(provider),
          backgroundColor: kCharcoal,
          label: Text("FINALIZE & SAVE", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, color: kGoldPrimary)),
          icon: Icon(Icons.check_circle_outline, color: kGoldPrimary))
          : null),
    );
  }

  Widget _buildTopSummarySection(EntryProvider provider) {
    return Container(
      padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 30),
      width: double.infinity,
      decoration: BoxDecoration(
        // --- UPDATED: BOTTOM CORNERS ROUNDED LIKE THE SCREENSHOT ---
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(35),
            bottomRight: Radius.circular(35),
          ),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEBC972), Color(0xFFC69C34)],
          ),
          boxShadow: [
            BoxShadow(
                color: kGoldDark.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10)
            )
          ]
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(color: kWhite.withOpacity(0.2), shape: BoxShape.circle),
                    child: CircleAvatar(
                      radius: 25,
                      backgroundColor: kWhite,
                      backgroundImage: const AssetImage('assets/headlogo.jpeg'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(DateFormat('EEEE, dd MMM').format(_selectedDate).toUpperCase(),
                          style: TextStyle(color: kWhite.withOpacity(0.8), fontSize: 13, letterSpacing: 0.5, fontWeight: FontWeight.w600)),
                      Text("Counter Entry",
                          style: TextStyle(color: kWhite, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                    ],
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(color: kWhite.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                child: IconButton(onPressed: () async {
                  final DateTime? picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2024), lastDate: DateTime.now());
                  if (picked != null) setState(() => _selectedDate = picked);
                }, icon: Icon(Icons.calendar_today_rounded, color: kWhite, size: 20)),
              ),
            ],
          ),
          const SizedBox(height: 25),
          _buildLiveReceiptCard(provider),
        ],
      ),
    );
  }

  Widget _buildLiveReceiptCard(EntryProvider provider) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))]),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: kGoldLight,
                backgroundImage: provider.cachedStaffBytes != null ? MemoryImage(provider.cachedStaffBytes!) : null,
                child: provider.cachedStaffBytes == null ? Icon(Icons.person, color: kGoldDark) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("SERVICE STAFF", style: TextStyle(color: Colors.grey.shade400, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1)),
                  Text(provider.selectedStaff ?? "Selection Required", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kCharcoal)),
                ]),
              ),
              Text("Rs ${provider.totalAmount.toStringAsFixed(0)}", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: kGoldDark)),
            ],
          ),
          if (provider.selectedServicesList.isNotEmpty) ...[
            const Divider(height: 25, thickness: 0.5),
            SizedBox(
              height: 32,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: provider.selectedServicesList.length,
                itemBuilder: (context, index) {
                  final s = provider.selectedServicesList[index];
                  String displayName = s is Map && s.containsKey('name') ? s['name'] : "N/A";
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: kGoldLight, borderRadius: BorderRadius.circular(10)),
                    child: Row(children: [
                      Text(displayName, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kGoldDark)),
                      const SizedBox(width: 6),
                      GestureDetector(onTap: () => provider.removeService(index), child: Icon(Icons.cancel, size: 14, color: kGoldDark)),
                    ]),
                  );
                },
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildBottomCatalog(EntryProvider provider) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(children: [
          Expanded(child: provider.isExpenseMode ? const Text("EXPENSE DETAILS", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.redAccent)) : _buildSearchField()),
          const SizedBox(width: 12),
          _buildModeToggleButton(provider),
        ]),
        const SizedBox(height: 20),
        provider.isExpenseMode ? _buildExpenseForm(provider) : _buildServiceSelectionArea(provider),
      ],
    );
  }

  Widget _buildModeToggleButton(EntryProvider provider) {
    return GestureDetector(
      onTap: () => provider.toggleMode(),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: provider.isExpenseMode ? Colors.redAccent : kCharcoal,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5, offset: Offset(0,2))]
        ),
        child: Icon(provider.isExpenseMode ? Icons.content_cut_rounded : Icons.receipt_long_rounded, color: provider.isExpenseMode ? kWhite : kGoldPrimary, size: 20),
      ),
    );
  }

  Widget _buildExpenseForm(EntryProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.08), blurRadius: 20)]),
      child: Column(
        children: [
          TextField(controller: _expAmountController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "Amount (Rs)", labelStyle: TextStyle(color: kGoldDark), focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: kGoldPrimary)))),
          const SizedBox(height: 15),
          TextField(controller: _expNoteController, decoration: InputDecoration(labelText: "Detail", labelStyle: TextStyle(color: kGoldDark), focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: kGoldPrimary)))),
          const SizedBox(height: 25),
          SizedBox(width: double.infinity, height: 55, child: ElevatedButton(onPressed: () => _submitExpense(provider), style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent), child: const Text("SAVE EXPENSE", style: TextStyle(color: Colors.white)))),
        ],
      ),
    );
  }

  Widget _buildServiceSelectionArea(EntryProvider provider) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text("1. ASSIGN STAFF", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: kCharcoal.withOpacity(0.4))),
      const SizedBox(height: 10),
      _buildHorizontalStaffList(provider),
      const SizedBox(height: 25),
      Text("2. SELECT SERVICES", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: kCharcoal.withOpacity(0.4))),
      const SizedBox(height: 10),
      _buildServiceGrid(provider),
    ]);
  }

  Widget _buildHorizontalStaffList(EntryProvider provider) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('employees').where('status', isEqualTo: 'Active').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 100);
        return SizedBox(
          height: 105,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

              String name = data.containsKey('name') ? data['name'] : "Unknown";
              var bytes = provider.getOrDecodeImage(name, data['image']);
              bool isSelected = provider.selectedStaff == name;

              return GestureDetector(
                onTap: () => provider.selectStaff(name, bytes),
                child: Padding(
                  padding: const EdgeInsets.only(right: 15),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: isSelected ? kGoldPrimary : Colors.transparent, width: 2),
                            color: isSelected ? kGoldLight.withOpacity(0.3) : Colors.transparent
                        ),
                        child: CircleAvatar(
                            radius: 35,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: bytes != null ? MemoryImage(bytes) : null,
                            child: bytes == null ? const Icon(Icons.person) : null
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: 70,
                        child: Text(
                          name,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? kGoldDark : kCharcoal
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildServiceGrid(EntryProvider provider) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('services').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        var filteredDocs = snapshot.data!.docs.where((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          if (!data.containsKey('name')) return false;
          return data['name'].toString().toLowerCase().contains(_searchText.toLowerCase());
        }).toList();

        return GridView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 80),
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 0.8),
          itemCount: filteredDocs.length + 1,
          itemBuilder: (context, index) {
            if (index == filteredDocs.length) {
              return InkWell(
                onTap: () => _showOtherServiceDialog(provider),
                child: Container(
                  decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withOpacity(0.3))
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.add_circle_outline, color: Colors.orange.shade700, size: 20),
                    Text("Other", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.orange.shade700)),
                  ]),
                ),
              );
            }

            var doc = filteredDocs[index];
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            String sName = data.containsKey('name') ? data['name'] : "N/A";
            String sPrice = data.containsKey('price') ? data['price'].toString() : "0";

            return InkWell(
              onTap: () => provider.addService({"name": sName, "price": double.tryParse(sPrice) ?? 0.0}),
              child: Container(
                decoration: BoxDecoration(
                    color: kWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade100),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 2)]
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(sName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9, color: kCharcoal), textAlign: TextAlign.center, maxLines: 1),
                    const SizedBox(height: 2),
                    Text("Rs $sPrice", style: TextStyle(color: kGoldDark, fontSize: 9, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 45,
      decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade100)),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchText = val),
        decoration: InputDecoration(
            hintText: "Search...",
            prefixIcon: Icon(Icons.search, size: 18, color: kGoldDark),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10)
        ),
      ),
    );
  }
}