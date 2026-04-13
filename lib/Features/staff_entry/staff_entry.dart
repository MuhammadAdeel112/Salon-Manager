import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'packages_catalog.dart';
import 'receipt_printer.dart';
import 'services_catalog.dart';
import 'entry_provider.dart';

class StaffEntryScreen extends StatefulWidget {
  const StaffEntryScreen({super.key});

  @override
  State<StaffEntryScreen> createState() => _StaffEntryScreenState();
}

class _StaffEntryScreenState extends State<StaffEntryScreen>
    with SingleTickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
  String _searchText = "";
  bool _showPackages = false;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _expAmountController = TextEditingController();
  final TextEditingController _expNoteController = TextEditingController();
  final TextEditingController _clientNameController = TextEditingController(); // ← NEW

  late AnimationController _pulseController;

  final Color kGoldLight = const Color(0xFFF8E9B0);
  final Color kGoldPrimary = const Color(0xFFD4AF37);
  final Color kGoldDark = const Color(0xFFAA8C2C);
  final Color kCharcoal = const Color(0xFF1F1F1F);
  final Color kWhite = Colors.white;

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
    _clientNameController.dispose(); // ← NEW
    super.dispose();
  }

  // ==================== SUBMIT TRANSACTION ====================
  Future<void> _submitTransaction(EntryProvider provider) async {
    if (provider.selectedStaff == null || provider.selectedServicesList.isEmpty) return;

    await FirebaseFirestore.instance.collection('transactions').add({
      'staffName': provider.selectedStaff,
      'clientName': _clientNameController.text.trim().isNotEmpty
          ? _clientNameController.text.trim()
          : null,                                      // ← NEW
      'services': List.from(provider.selectedServicesList),
      'totalPrice': provider.totalAmount,
      'status': "Unapproved",
      'timestamp': Timestamp.fromDate(_selectedDate),
      'dateOnly': DateFormat('yyyy-MM-dd').format(_selectedDate),
      'time': DateFormat('hh:mm a').format(DateTime.now()),
      'isPackage': false,
      'packageName': null,
    });

    // ✅ receipt_printer.dart se print
    await ReceiptPrinter.printReceipt(
      staffName: provider.selectedStaff!,
      clientName: _clientNameController.text.trim().isNotEmpty
          ? _clientNameController.text.trim()
          : null,                                      // ← NEW (optional)
      services: provider.selectedServicesList,
      totalAmount: provider.totalAmount,
      date: _selectedDate,
    );

    provider.resetEntry();
    _clientNameController.clear();                     // ← NEW
    setState(() => _showPackages = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("✅ Entry Saved & Printed!", style: TextStyle(color: kWhite)),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  // ==================== SUBMIT EXPENSE (No Change) ====================
  Future<void> _submitExpense(EntryProvider provider) async {
    if (_expAmountController.text.trim().isEmpty) return;

    try {
      await FirebaseFirestore.instance.collection('expenses').add({
        'amount': double.tryParse(_expAmountController.text) ?? 0,
        'description': _expNoteController.text.trim(),
        'dateOnly': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Expense sync error: $e");
    }

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

  // ==================== BUILD ====================
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
                style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.8, color: kGoldPrimary, fontSize: isTablet ? 15 : 12),
              ),
            ),
            icon: Icon(Icons.save_rounded, color: kGoldPrimary, size: isTablet ? 28 : 22),
          ),
        )
            : null),
      ),
    );
  }

  // ==================== TOP SECTION & LIVE RECEIPT CARD (No Change) ====================
  Widget _buildTopSummarySection(BuildContext context, EntryProvider provider, double sw, bool isTablet) {
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
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(color: kWhite.withValues(alpha: 0.25), shape: BoxShape.circle),
                  child: CircleAvatar(
                    radius: isTablet ? 28 : 20,
                    backgroundColor: kWhite,
                    backgroundImage: const AssetImage('assets/headlogo.jpeg'),
                  ),
                ),
                SizedBox(width: isTablet ? 14 : 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    DateFormat('EEEE, dd MMM').format(_selectedDate).toUpperCase(),
                    style: TextStyle(color: kWhite.withValues(alpha: 0.85), fontSize: isTablet ? 13 : 10, fontWeight: FontWeight.w600, letterSpacing: 1),
                  ),
                  Text("Counter Entry",
                      style: TextStyle(
                          color: kWhite, fontSize: isTablet ? 26 : 19, fontWeight: FontWeight.w900, letterSpacing: 0.6,
                          shadows: [Shadow(color: kCharcoal.withValues(alpha: 0.3), blurRadius: 6)])),
                ]),
              ]),
              Container(
                decoration: BoxDecoration(color: kWhite.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(14)),
                child: IconButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2024),
                      lastDate: DateTime.now(),
                      builder: (context, child) => Theme(
                          data: ThemeData.light().copyWith(colorScheme: ColorScheme.light(primary: kGoldPrimary)),
                          child: child!),
                    );
                    if (picked != null) setState(() => _selectedDate = picked);
                  },
                  icon: Icon(Icons.calendar_month_rounded, color: kWhite, size: isTablet ? 26 : 22),
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
        boxShadow: [BoxShadow(color: kGoldDark.withValues(alpha: 0.12), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Container(
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: kGoldPrimary, width: 2.5)),
              child: CircleAvatar(
                radius: isTablet ? 26 : 20,
                backgroundColor: kGoldLight,
                backgroundImage: provider.cachedStaffBytes != null ? MemoryImage(provider.cachedStaffBytes!) : null,
                child: provider.cachedStaffBytes == null ? Icon(Icons.person_rounded, color: kGoldDark, size: isTablet ? 32 : 24) : null,
              ),
            ),
            SizedBox(width: isTablet ? 16 : 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("STAFF MEMBER", style: TextStyle(color: Colors.grey.shade500, fontSize: isTablet ? 10 : 8, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
              Text(provider.selectedStaff ?? "Select Staff", style: TextStyle(fontSize: isTablet ? 17 : 13, fontWeight: FontWeight.w800, color: kCharcoal)),
            ])),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 400),
              style: TextStyle(fontSize: isTablet ? 26 : 18, fontWeight: FontWeight.w900, color: kGoldDark),
              child: Text("Rs ${provider.totalAmount.toStringAsFixed(0)}"),
            ),
          ]),
          if (provider.selectedServicesList.isNotEmpty) ...[
            const Divider(height: 28, thickness: 1, color: Color(0xFFF0E6C8)),
            SizedBox(
              height: isTablet ? 36 : 30,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: provider.selectedServicesList.length,
                itemBuilder: (context, index) {
                  final s = provider.selectedServicesList[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Chip(
                      backgroundColor: kGoldLight.withValues(alpha: 0.7),
                      padding: EdgeInsets.symmetric(horizontal: isTablet ? 12 : 6, vertical: 2),
                      label: Text("${s['name']} • Rs ${(s['price'] as double).round()}",
                          style: TextStyle(color: kGoldDark, fontWeight: FontWeight.w700, fontSize: isTablet ? 12 : 10)),
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

  // ==================== BOTTOM CATALOG ====================
  Widget _buildBottomCatalog(EntryProvider provider, double sw, double sh, bool isTablet) {
    return ListView(
      padding: EdgeInsets.fromLTRB(isTablet ? 20 : 14, 20, isTablet ? 20 : 14, 100),
      children: [
        Row(children: [
          Expanded(
              child: provider.isExpenseMode
                  ? Text("EXPENSE ENTRY", style: TextStyle(fontWeight: FontWeight.w900, fontSize: isTablet ? 15 : 13, color: Colors.red.shade700))
                  : _buildSearchField(isTablet)),
          const SizedBox(width: 12),
          _buildModeToggleButton(provider, isTablet),
        ]),
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
              colors: provider.isExpenseMode ? [Colors.red.shade700, Colors.red.shade500] : [kCharcoal, kCharcoal.withValues(alpha: 0.9)]),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: (provider.isExpenseMode ? Colors.red : kGoldDark).withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 6))],
        ),
        child: Icon(provider.isExpenseMode ? Icons.content_cut_rounded : Icons.receipt_long_rounded, color: kWhite, size: isTablet ? 26 : 22),
      ),
    );
  }

  Widget _buildExpenseForm(EntryProvider provider, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 16),
      decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: Colors.red.withValues(alpha: 0.10), blurRadius: 24, offset: const Offset(0, 12))]),
      child: Column(children: [
        TextField(
            controller: _expAmountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
                labelText: "Expense Amount (PKR)",
                labelStyle: TextStyle(color: kGoldDark),
                prefixIcon: Icon(Icons.money_off_csred_rounded, color: Colors.red.shade700),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.grey.shade50)),
        const SizedBox(height: 16),
        TextField(
            controller: _expNoteController,
            decoration: InputDecoration(
                labelText: "Description / Note",
                labelStyle: TextStyle(color: kGoldDark),
                prefixIcon: Icon(Icons.note_alt_rounded, color: kGoldDark),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.grey.shade50)),
        const SizedBox(height: 24),
        SizedBox(
            width: double.infinity,
            height: isTablet ? 58 : 50,
            child: ElevatedButton.icon(
                onPressed: () => _submitExpense(provider),
                icon: const Icon(Icons.save_rounded, color: Colors.white),
                label: Text("SAVE EXPENSE", style: TextStyle(fontSize: isTablet ? 16 : 14, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: kWhite,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 6))),
      ]),
    );
  }

  // ==================== SERVICE SELECTION AREA (Only This Part Changed) ====================
  Widget _buildServiceSelectionArea(EntryProvider provider, double sw, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("1. SELECT STAFF MEMBER",
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: isTablet ? 14 : 12, color: kCharcoal, letterSpacing: 0.4)),
        const SizedBox(height: 12),
        _buildHorizontalStaffList(provider, sw, isTablet),

        // ==================== CLIENT NAME FIELD (New) ====================
        const SizedBox(height: 24),
        Text("CLIENT NAME (OPTIONAL)",
            style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: isTablet ? 14 : 12,
                color: kCharcoal,
                letterSpacing: 0.4)),
        const SizedBox(height: 10),

        Container(
          height: isTablet ? 52 : 48,
          decoration: BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kGoldLight),
            boxShadow: [BoxShadow(color: kGoldDark.withValues(alpha: 0.06), blurRadius: 10)],
          ),
          child: TextField(
            controller: _clientNameController,
            decoration: InputDecoration(
              hintText: "Enter client name...",
              hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: isTablet ? 14 : 13),
              prefixIcon: Icon(Icons.person_outline_rounded, color: kGoldDark),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        // =================================================================

        const SizedBox(height: 28),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text("2. CHOOSE SERVICES",
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: isTablet ? 14 : 12, color: kCharcoal, letterSpacing: 0.4)),
          _buildToggleSwitch(isTablet),
        ]),
        const SizedBox(height: 14),

        _showPackages
            ? PackagesCatalog(selectedDate: _selectedDate, isTablet: isTablet)
            : ServicesCatalog(provider: provider, sw: sw, isTablet: isTablet, searchText: _searchText),
      ],
    );
  }

  // ==================== Remaining Functions (Unchanged) ====================
  Widget _buildToggleSwitch(bool isTablet) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: kGoldDark.withValues(alpha: 0.10), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        _togglePill("Services", !_showPackages, isTablet),
        _togglePill("Packages", _showPackages, isTablet),
      ]),
    );
  }

  Widget _togglePill(String label, bool isSelected, bool isTablet) {
    return GestureDetector(
      onTap: () => setState(() => _showPackages = label == "Packages"),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(horizontal: isTablet ? 18 : 14, vertical: isTablet ? 8 : 6),
        decoration: BoxDecoration(color: isSelected ? kCharcoal : Colors.transparent, borderRadius: BorderRadius.circular(26)),
        child: Text(label,
            style: TextStyle(fontSize: isTablet ? 13 : 11, fontWeight: FontWeight.w700, color: isSelected ? kGoldPrimary : kCharcoal.withValues(alpha: 0.38))),
      ),
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
              try { bytes = provider.getOrDecodeImage(name, data['image']); } catch (_) { bytes = null; }
              bool selected = provider.selectedStaff == name;

              return GestureDetector(
                onTap: () => provider.selectStaff(name, bytes),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: EdgeInsets.only(right: isTablet ? 20 : 14),
                  child: Column(children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: selected ? LinearGradient(colors: [kGoldPrimary, kGoldDark]) : null,
                          boxShadow: selected ? [BoxShadow(color: kGoldPrimary.withValues(alpha: 0.6), blurRadius: 16, spreadRadius: 4)] : null),
                      child: CircleAvatar(
                          radius: avatarRadius,
                          backgroundColor: kWhite,
                          backgroundImage: bytes != null ? MemoryImage(bytes) : null,
                          child: bytes == null ? Icon(Icons.person, color: kGoldDark, size: avatarRadius * 1.1) : null),
                    ),
                    SizedBox(height: isTablet ? 12 : 6),
                    Text(name,
                        style: TextStyle(
                            fontSize: isTablet ? 14 : 11,
                            fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                            color: selected ? kGoldDark : kCharcoal)),
                  ]),
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
      decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kGoldLight),
          boxShadow: [BoxShadow(color: kGoldDark.withValues(alpha: 0.06), blurRadius: 10)]),
      child: TextField(
          controller: _searchController,
          onChanged: (val) => setState(() => _searchText = val),
          decoration: InputDecoration(
              hintText: "Search services...",
              hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: isTablet ? 14 : 12),
              prefixIcon: Icon(Icons.search_rounded, color: kGoldDark, size: isTablet ? 24 : 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14))),
    );
  }
}