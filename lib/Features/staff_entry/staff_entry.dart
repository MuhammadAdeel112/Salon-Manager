import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'entry_provider.dart';

class StaffEntryScreen extends StatefulWidget {
  const StaffEntryScreen({super.key});

  @override
  _StaffEntryScreenState createState() => _StaffEntryScreenState();
}

class _StaffEntryScreenState extends State<StaffEntryScreen>
    with SingleTickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
  String _searchText = "";
  bool _showPackages = false;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _expAmountController = TextEditingController();
  final TextEditingController _expNoteController = TextEditingController();

  late AnimationController _pulseController;

  final Color kGoldLight   = const Color(0xFFF8E9B0);
  final Color kGoldPrimary = const Color(0xFFD4AF37);
  final Color kGoldDark    = const Color(0xFFAA8C2C);
  final Color kCharcoal    = const Color(0xFF1F1F1F);
  final Color kWhite       = Colors.white;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _searchController.dispose();
    _expAmountController.dispose();
    _expNoteController.dispose();
    super.dispose();
  }

  void _showOtherServiceDialog(EntryProvider provider) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: kWhite,
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
                  borderSide: BorderSide(color: kGoldPrimary, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: kGoldLight),
                ),
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
                  borderSide: BorderSide(color: kGoldPrimary, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: kGoldLight),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: kCharcoal)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kGoldPrimary,
              foregroundColor: kWhite,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty && priceCtrl.text.trim().isNotEmpty) {
                provider.addService({
                  "name": nameCtrl.text.trim(),
                  "price": double.tryParse(priceCtrl.text) ?? 0.0,
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
      'isPackage': false, // Normal service entry
      'packageName': null,
    };

    FirebaseFirestore.instance
        .collection('transactions')
        .add(entryData)
        .catchError((e) => debugPrint("Background sync error: $e"));

    provider.resetEntry();
    setState(() => _showPackages = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("✅ Entry Saved!", style: TextStyle(color: kWhite)),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  Future<void> _submitExpense(EntryProvider provider) async {
    if (_expAmountController.text.trim().isEmpty) return;
    final amount = double.tryParse(_expAmountController.text) ?? 0;

    FirebaseFirestore.instance.collection('expenses').add({
      'amount': amount,
      'description': _expNoteController.text.trim(),
      'dateOnly': DateFormat('yyyy-MM-dd').format(_selectedDate),
      'timestamp': FieldValue.serverTimestamp(),
    }).catchError((e) => debugPrint("Expense sync error: $e"));

    _expAmountController.clear();
    _expNoteController.clear();
    provider.toggleMode();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("✅ Expense Saved!", style: TextStyle(color: kWhite)),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ));
    }
  }

  // ════════════════════════════════════════════════════
  // ✅ NEW: Package Staff Selection Popup Trigger
  // ════════════════════════════════════════════════════
  void _showPackageStaffSelectionDialog({
    required String packageName,
    required List services,
    required double originalPrice,
    required double discountedPrice,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _MultiStaffPackageDialog(
        packageName: packageName,
        services: services,
        originalPrice: originalPrice,
        discountedPrice: discountedPrice,
        selectedDate: _selectedDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EntryProvider>(context);
    final double sw = MediaQuery.of(context).size.width;
    final double sh = MediaQuery.of(context).size.height;
    final bool isTablet = sw >= 600;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3), Color(0xFFFFCA28), Color(0xFFFFB74D)],
              stops: [0.0, 0.3, 0.6, 1.0],
            ),
          ),
          child: SafeArea(
            top: true,
            bottom: false,
            child: Column(
              children: [
                _buildTopSummarySection(context, provider, sw, isTablet),
                Expanded(child: _buildBottomCatalog(provider, sw, sh, isTablet)),
              ],
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        // FAB sirf Normal Services ke liye rahega
        floatingActionButton: provider.isExpenseMode
            ? null
            : (provider.selectedServicesList.isNotEmpty && provider.selectedStaff != null
            ? ScaleTransition(
          scale: Tween<double>(begin: 0.95, end: 1.05).animate(_pulseController),
          child: FloatingActionButton.extended(
            onPressed: () => _submitTransaction(provider),
            backgroundColor: kCharcoal,
            elevation: 12,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            label: Padding(
              padding: EdgeInsets.symmetric(horizontal: isTablet ? 12 : 8),
              child: Text(
                "SAVE ENTRY  •  Rs ${provider.totalAmount.toStringAsFixed(0)}",
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: kGoldPrimary,
                    fontSize: isTablet ? 15 : 12),
              ),
            ),
            icon: Icon(Icons.save_rounded, color: kGoldPrimary, size: isTablet ? 28 : 22),
          ),
        )
            : null),
      ),
    );
  }

  Widget _buildTopSummarySection(
      BuildContext context, EntryProvider provider, double sw, bool isTablet) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.only(
        top: topPadding + (isTablet ? 16 : 10),
        left: isTablet ? 24 : 16,
        right: isTablet ? 24 : 16,
        bottom: isTablet ? 36 : 20,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                        color: kWhite.withOpacity(0.25), shape: BoxShape.circle),
                    child: CircleAvatar(
                      radius: isTablet ? 28 : 20,
                      backgroundColor: kWhite,
                      backgroundImage: const AssetImage('assets/headlogo.jpeg'),
                    ),
                  ),
                  SizedBox(width: isTablet ? 14 : 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEEE, dd MMM').format(_selectedDate).toUpperCase(),
                        style: TextStyle(
                            color: kWhite.withOpacity(0.85),
                            fontSize: isTablet ? 13 : 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1),
                      ),
                      Text(
                        "Counter Entry",
                        style: TextStyle(
                            color: kWhite,
                            fontSize: isTablet ? 26 : 19,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                            shadows: [Shadow(color: kCharcoal.withOpacity(0.3), blurRadius: 6)]),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                    color: kWhite.withOpacity(0.18), borderRadius: BorderRadius.circular(14)),
                child: IconButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2024),
                      lastDate: DateTime.now(),
                      builder: (context, child) => Theme(
                        data: ThemeData.light()
                            .copyWith(colorScheme: ColorScheme.light(primary: kGoldPrimary)),
                        child: child!,
                      ),
                    );
                    if (picked != null) setState(() => _selectedDate = picked);
                  },
                  icon: Icon(Icons.calendar_month_rounded,
                      color: kWhite, size: isTablet ? 26 : 22),
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 28 : 16),
          _buildLiveReceiptCard(provider, isTablet),
        ],
      ),
    );
  }

  Widget _buildLiveReceiptCard(EntryProvider provider, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 14),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: kGoldDark.withOpacity(0.12), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: kGoldPrimary, width: 2.5)),
                child: CircleAvatar(
                  radius: isTablet ? 26 : 20,
                  backgroundColor: kGoldLight,
                  backgroundImage: provider.cachedStaffBytes != null
                      ? MemoryImage(provider.cachedStaffBytes!)
                      : null,
                  child: provider.cachedStaffBytes == null
                      ? Icon(Icons.person_rounded, color: kGoldDark, size: isTablet ? 32 : 24)
                      : null,
                ),
              ),
              SizedBox(width: isTablet ? 16 : 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("STAFF MEMBER",
                        style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: isTablet ? 10 : 8,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2)),
                    Text(
                      provider.selectedStaff ?? "Select Staff",
                      style: TextStyle(
                          fontSize: isTablet ? 17 : 13,
                          fontWeight: FontWeight.w800,
                          color: kCharcoal),
                    ),
                  ],
                ),
              ),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 400),
                style: TextStyle(
                    fontSize: isTablet ? 26 : 18,
                    fontWeight: FontWeight.w900,
                    color: kGoldDark),
                child: Text("Rs ${provider.totalAmount.toStringAsFixed(0)}"),
              ),
            ],
          ),
          if (provider.selectedServicesList.isNotEmpty) ...[
            const Divider(height: 28, thickness: 1, color: Color(0xFFF0E6C8)),
            SizedBox(
              height: isTablet ? 36 : 30,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: provider.selectedServicesList.length,
                itemBuilder: (context, index) {
                  final s = provider.selectedServicesList[index];
                  final String name = s['name'] ?? "Unknown";
                  final double price = s['price'] ?? 0.0;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Chip(
                      backgroundColor: kGoldLight.withOpacity(0.7),
                      padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 12 : 6, vertical: 2),
                      label: Text(
                        "$name • Rs ${price.round()}",
                        style: TextStyle(
                            color: kGoldDark,
                            fontWeight: FontWeight.w700,
                            fontSize: isTablet ? 12 : 10),
                      ),
                      deleteIcon: Icon(Icons.close, size: isTablet ? 18 : 14, color: kGoldDark),
                      onDeleted: () => provider.removeService(index),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomCatalog(
      EntryProvider provider, double sw, double sh, bool isTablet) {
    return ListView(
      padding: EdgeInsets.fromLTRB(isTablet ? 20 : 14, 20, isTablet ? 20 : 14, 100),
      children: [
        Row(
          children: [
            Expanded(
              child: provider.isExpenseMode
                  ? Text("EXPENSE ENTRY",
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: isTablet ? 15 : 13,
                      color: Colors.red.shade700))
                  : _buildSearchField(isTablet),
            ),
            const SizedBox(width: 12),
            _buildModeToggleButton(provider, isTablet),
          ],
        ),
        const SizedBox(height: 20),
        provider.isExpenseMode
            ? _buildExpenseForm(provider, isTablet)
            : _buildServiceSelectionArea(provider, sw, isTablet),
      ],
    );
  }

  Widget _buildModeToggleButton(EntryProvider provider, bool isTablet) {
    return GestureDetector(
      onTap: () => provider.toggleMode(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        padding: EdgeInsets.all(isTablet ? 14 : 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: provider.isExpenseMode
                ? [Colors.red.shade700, Colors.red.shade500]
                : [kCharcoal, kCharcoal.withOpacity(0.9)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: (provider.isExpenseMode ? Colors.red : kGoldDark).withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6)),
          ],
        ),
        child: Icon(
          provider.isExpenseMode ? Icons.content_cut_rounded : Icons.receipt_long_rounded,
          color: kWhite,
          size: isTablet ? 26 : 22,
        ),
      ),
    );
  }

  Widget _buildExpenseForm(EntryProvider provider, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 16),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.red.withOpacity(0.10), blurRadius: 24, offset: const Offset(0, 12)),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _expAmountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: "Expense Amount (PKR)",
              labelStyle: TextStyle(color: kGoldDark),
              prefixIcon: Icon(Icons.money_off_csred_rounded, color: Colors.red.shade700),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _expNoteController,
            decoration: InputDecoration(
              labelText: "Description / Note",
              labelStyle: TextStyle(color: kGoldDark),
              prefixIcon: Icon(Icons.note_alt_rounded, color: kGoldDark),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: isTablet ? 58 : 50,
            child: ElevatedButton.icon(
              onPressed: () => _submitExpense(provider),
              icon: const Icon(Icons.save_rounded, color: Colors.white),
              label: Text("SAVE EXPENSE",
                  style: TextStyle(fontSize: isTablet ? 16 : 14, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: kWhite,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceSelectionArea(EntryProvider provider, double sw, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("1. SELECT STAFF MEMBER",
            style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: isTablet ? 14 : 12,
                color: kCharcoal,
                letterSpacing: 0.4)),
        const SizedBox(height: 12),
        _buildHorizontalStaffList(provider, sw, isTablet),
        const SizedBox(height: 28),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("2. CHOOSE SERVICES",
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: isTablet ? 14 : 12,
                    color: kCharcoal,
                    letterSpacing: 0.4)),
            _buildToggleSwitch(isTablet),
          ],
        ),
        const SizedBox(height: 14),

        _showPackages
            ? _buildPackagesGrid(provider, sw, isTablet)
            : _buildServiceGrid(provider, sw, isTablet),
      ],
    );
  }

  Widget _buildToggleSwitch(bool isTablet) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: kGoldDark.withOpacity(0.10), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _togglePill("Services", !_showPackages, isTablet),
          _togglePill("Packages", _showPackages, isTablet),
        ],
      ),
    );
  }

  Widget _togglePill(String label, bool isSelected, bool isTablet) {
    return GestureDetector(
      onTap: () => setState(() => _showPackages = label == "Packages"),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 18 : 14, vertical: isTablet ? 8 : 6),
        decoration: BoxDecoration(
          color: isSelected ? kCharcoal : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: isTablet ? 13 : 11,
            fontWeight: FontWeight.w700,
            color: isSelected ? kGoldPrimary : kCharcoal.withOpacity(0.38),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceGrid(EntryProvider provider, double sw, bool isTablet) {
    final int columns = sw >= 600 ? 5 : (sw >= 400 ? 4 : 3);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('services').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        var filtered = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return (data['name'] ?? "")
              .toString()
              .toLowerCase()
              .contains(_searchText.toLowerCase());
        }).toList();

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 100, top: 4),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: isTablet ? 10 : 8,
            mainAxisSpacing: isTablet ? 10 : 8,
            childAspectRatio: isTablet ? 1.0 : 0.88,
          ),
          itemCount: filtered.length + 1,
          itemBuilder: (context, index) {
            if (index == filtered.length) {
              return GestureDetector(
                onTap: () => _showOtherServiceDialog(provider),
                child: Container(
                  decoration: BoxDecoration(
                    color: kWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kGoldPrimary.withOpacity(0.35), width: 1.5),
                    boxShadow: [
                      BoxShadow(color: kGoldDark.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: isTablet ? 38 : 32,
                        height: isTablet ? 38 : 32,
                        decoration: BoxDecoration(color: kGoldLight, shape: BoxShape.circle),
                        child: Icon(Icons.add_rounded, color: kGoldDark, size: isTablet ? 22 : 18),
                      ),
                      SizedBox(height: isTablet ? 7 : 5),
                      Text("Custom", style: TextStyle(color: kGoldDark, fontWeight: FontWeight.w700, fontSize: isTablet ? 12 : 10)),
                    ],
                  ),
                ),
              );
            }

            final data = filtered[index].data() as Map<String, dynamic>;
            final String name = data['name'] ?? "N/A";
            final String price = data['price']?.toString() ?? "0";

            return GestureDetector(
              onTap: () => provider.addService({"name": name, "price": double.tryParse(price) ?? 0.0}),
              child: Container(
                decoration: BoxDecoration(
                  color: kWhite,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: kGoldDark.withOpacity(0.07), blurRadius: 8, offset: const Offset(0, 3)),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: isTablet ? 8 : 5),
                      child: Text(name, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, fontSize: isTablet ? 13 : 11, color: kCharcoal, height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ),
                    SizedBox(height: isTablet ? 8 : 5),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: isTablet ? 10 : 7, vertical: isTablet ? 4 : 3),
                      decoration: BoxDecoration(color: kGoldLight, borderRadius: BorderRadius.circular(20)),
                      child: Text("Rs $price", style: TextStyle(color: kGoldDark, fontWeight: FontWeight.w800, fontSize: isTablet ? 12 : 10)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ════════════════════════════════════════════════════
  // ✅ UPDATED PACKAGE GRID (Ab Popup khulega)
  // ════════════════════════════════════════════════════
  Widget _buildPackagesGrid(EntryProvider provider, double sw, bool isTablet) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('packages').where('isActive', isEqualTo: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(24)),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.inventory_2_outlined, size: 44, color: kGoldPrimary.withOpacity(0.35)),
                  const SizedBox(height: 12),
                  Text("No packages available", style: TextStyle(color: kCharcoal.withOpacity(0.4), fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          );
        }

        final packages = snapshot.data!.docs;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 100, top: 4),
          itemCount: packages.length,
          itemBuilder: (context, index) {
            final data = packages[index].data() as Map<String, dynamic>;
            final String pkgId = packages[index].id;
            final String name = data['name'] ?? "";
            final double originalPrice = (data['originalPrice'] ?? 0).toDouble();
            final double discountedPrice = (data['discountedPrice'] ?? 0).toDouble();
            final List services = List.from(data['services'] ?? []);

            final int discountPct = originalPrice > 0
                ? (((originalPrice - discountedPrice) / originalPrice) * 100).round()
                : 0;

            return GestureDetector(
              // ✅ CHANGE: Ab popup call hoga
              onTap: () => _showPackageStaffSelectionDialog(
                packageName: name,
                services: services,
                originalPrice: originalPrice,
                discountedPrice: discountedPrice,
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kWhite,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: kGoldPrimary.withOpacity(0.3), width: 1.8),
                  boxShadow: [
                    BoxShadow(color: kGoldDark.withOpacity(0.07), blurRadius: 8, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: isTablet ? 52 : 44,
                      height: isTablet ? 52 : 44,
                      decoration: BoxDecoration(color: const Color(0xFFF3F3F3), borderRadius: BorderRadius.circular(14)),
                      child: Icon(Icons.inventory_2_rounded, color: kCharcoal.withOpacity(0.35), size: isTablet ? 24 : 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: TextStyle(fontSize: isTablet ? 15 : 13, fontWeight: FontWeight.w800, color: kCharcoal)),
                          const SizedBox(height: 5),
                          Wrap(
                            spacing: 5,
                            runSpacing: 4,
                            children: services.take(3).map((s) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: kCharcoal.withOpacity(0.06), borderRadius: BorderRadius.circular(20)),
                                child: Text(s.toString(), style: TextStyle(fontSize: isTablet ? 10 : 9, color: kCharcoal.withOpacity(0.55), fontWeight: FontWeight.w600)),
                              );
                            }).toList(),
                          ),
                          if (services.length > 3)
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text("+${services.length - 3} more", style: TextStyle(fontSize: 9, color: kGoldDark, fontWeight: FontWeight.w700)),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (discountPct > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(20)),
                            child: Text("$discountPct% OFF", style: TextStyle(fontSize: 9, color: Colors.green.shade700, fontWeight: FontWeight.w800)),
                          ),
                        const SizedBox(height: 4),
                        if (originalPrice > 0)
                          Text("Rs ${originalPrice.toStringAsFixed(0)}", style: TextStyle(fontSize: isTablet ? 11 : 10, decoration: TextDecoration.lineThrough, color: Colors.grey.shade400, fontWeight: FontWeight.w500)),
                        Text("Rs ${discountedPrice.toStringAsFixed(0)}", style: TextStyle(fontSize: isTablet ? 17 : 15, fontWeight: FontWeight.w900, color: kGoldDark)),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHorizontalStaffList(EntryProvider provider, double sw, bool isTablet) {
    final double listHeight = isTablet ? 160 : sw * 0.32;
    final double avatarRadius = isTablet ? 50 : sw * 0.09;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('employees').where('status', isEqualTo: 'Active').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return SizedBox(height: listHeight);
        final docs = snapshot.data!.docs;

        return SizedBox(
          height: listHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              String name = data['name'] ?? "Unknown";

              Uint8List? bytes;
              try {
                bytes = provider.getOrDecodeImage(name, data['image']);
              } catch (e) {
                debugPrint("Image decode error for $name: $e");
                bytes = null;
              }

              bool selected = provider.selectedStaff == name;

              return GestureDetector(
                onTap: () => provider.selectStaff(name, bytes),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: EdgeInsets.only(right: isTablet ? 20 : 14),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: selected ? LinearGradient(colors: [kGoldPrimary, kGoldDark]) : null,
                          boxShadow: selected ? [BoxShadow(color: kGoldPrimary.withOpacity(0.6), blurRadius: 16, spreadRadius: 4)] : null,
                        ),
                        child: CircleAvatar(
                          radius: avatarRadius,
                          backgroundColor: kWhite,
                          backgroundImage: bytes != null ? MemoryImage(bytes) : null,
                          child: bytes == null ? Icon(Icons.person, color: kGoldDark, size: avatarRadius * 1.1) : null,
                        ),
                      ),
                      SizedBox(height: isTablet ? 12 : 6),
                      Text(name, style: TextStyle(fontSize: isTablet ? 14 : 11, fontWeight: selected ? FontWeight.w900 : FontWeight.w700, color: selected ? kGoldDark : kCharcoal)),
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

  Widget _buildSearchField(bool isTablet) {
    return Container(
      height: isTablet ? 50 : 44,
      decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(20), border: Border.all(color: kGoldLight), boxShadow: [BoxShadow(color: kGoldDark.withOpacity(0.06), blurRadius: 10)]),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchText = val),
        decoration: InputDecoration(
          hintText: "Search services...",
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: isTablet ? 14 : 12),
          prefixIcon: Icon(Icons.search_rounded, color: kGoldDark, size: isTablet ? 24 : 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ✅ MULTI-STAFF PACKAGE SELECTION POPUP
// ═══════════════════════════════════════════════════════════════
class _MultiStaffPackageDialog extends StatefulWidget {
  final String packageName;
  final List services;
  final double originalPrice;
  final double discountedPrice;
  final DateTime selectedDate;

  const _MultiStaffPackageDialog({
    required this.packageName,
    required this.services,
    required this.originalPrice,
    required this.discountedPrice,
    required this.selectedDate,
  });

  @override
  State<_MultiStaffPackageDialog> createState() => _MultiStaffPackageDialogState();
}

class _MultiStaffPackageDialogState extends State<_MultiStaffPackageDialog> {
  final Set<String> _selectedStaffNames = {};
  bool _isSaving = false;
  final Map<String, Uint8List> _imageCache = {};

  // Local image decoder for popup
  Uint8List? _getOrDecodeImage(String name, String? base64Str) {
    if (base64Str == null) return null;
    if (!_imageCache.containsKey(name)) {
      try { _imageCache[name] = base64Decode(base64Str); } catch (e) { return null; }
    }
    return _imageCache[name];
  }

  Future<void> _confirmAndSave() async {
    if (_selectedStaffNames.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("⚠️ Kam az kam 1 staff select karo"),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Package price ko services mein divide karna
      double perServicePrice = widget.services.isNotEmpty ? widget.discountedPrice / widget.services.length : 0;

      List<Map<String, dynamic>> servicesData = widget.services.map((s) => {
        'name': s.toString(),
        'price': perServicePrice,
        'isPackageService': true,
      }).toList();

      // Har selected staff ke liye alag transaction save karna
      for (String staffName in _selectedStaffNames) {
        await FirebaseFirestore.instance.collection('transactions').add({
          'staffName': staffName,
          'services': servicesData,
          'totalPrice': widget.discountedPrice,
          'status': "Unapproved",
          'timestamp': Timestamp.fromDate(widget.selectedDate),
          'dateOnly': DateFormat('yyyy-MM-dd').format(widget.selectedDate),
          'time': DateFormat('hh:mm a').format(DateTime.now()),
          'isPackage': true,
          'packageName': widget.packageName,
        });
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("✅ ${_selectedStaffNames.length} Staff ke liye '${widget.packageName}' Save ho gaya!"),
          backgroundColor: Colors.green.shade700,
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxHeight: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFFF8E9B0).withOpacity(0.6), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.inventory_2_rounded, color: Color(0xFFAA8C2C), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Assign Package", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1F1F1F))),
                      Text(widget.packageName, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Text("Rs ${widget.discountedPrice.toStringAsFixed(0)}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFFAA8C2C))),
              ],
            ),
            const Divider(height: 24),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Select Staff Members:", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1F1F1F))),
            ),
            const SizedBox(height: 16),

            // Staff Grid
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('employees').where('status', isEqualTo: 'Active').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final docs = snapshot.data!.docs;

                return Flexible(
                  child: GridView.builder(
                    shrinkWrap: true,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      var data = docs[index].data() as Map<String, dynamic>;
                      String name = data['name'] ?? "Unknown";
                      Uint8List? bytes = _getOrDecodeImage(name, data['image']);
                      bool isSelected = _selectedStaffNames.contains(name);

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedStaffNames.remove(name);
                            } else {
                              _selectedStaffNames.add(name);
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFF8E9B0).withOpacity(0.5) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isSelected ? const Color(0xFFD4AF37) : Colors.grey.withOpacity(0.2), width: 1.5),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: isSelected ? const Color(0xFFD4AF37) : Colors.transparent, width: 2),
                                ),
                                child: CircleAvatar(
                                  radius: 26,
                                  backgroundColor: Colors.grey.shade100,
                                  backgroundImage: bytes != null ? MemoryImage(bytes) : null,
                                  child: bytes == null ? const Icon(Icons.person, color: Color(0xFFAA8C2C), size: 24) : null,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(name, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600, color: isSelected ? const Color(0xFFAA8C2C) : const Color(0xFF1F1F1F)), maxLines: 1, overflow: TextOverflow.ellipsis),
                              if (isSelected) const Icon(Icons.check_circle_rounded, color: Color(0xFFD4AF37), size: 16),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // Confirm Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _confirmAndSave,
                icon: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.check_circle_rounded, color: Colors.white),
                label: Text(
                  _isSaving ? "Saving..." : "Confirm & Save (${_selectedStaffNames.length} Entries)",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedStaffNames.isEmpty ? Colors.grey : const Color(0xFF1F1F1F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}