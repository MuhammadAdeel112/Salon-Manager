import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'Receipt printer.dart';

// ═══════════════════════════════════════════════════════════════
// 📦 PACKAGES CATALOG WIDGET
// Import: import 'packages_catalog.dart';
// Use: PackagesCatalog(selectedDate: _selectedDate, isTablet: isTablet)
// ═══════════════════════════════════════════════════════════════

class PackagesCatalog extends StatelessWidget {
  final DateTime selectedDate;
  final bool isTablet;

  const PackagesCatalog({
    super.key,
    required this.selectedDate,
    required this.isTablet,
  });

  final Color kGoldLight = const Color(0xFFF8E9B0);
  final Color kGoldPrimary = const Color(0xFFD4AF37);
  final Color kGoldDark = const Color(0xFFAA8C2C);
  final Color kCharcoal = const Color(0xFF1F1F1F);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('packages')
          .where('isActive', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
            child: Center(child: Column(children: [
              Icon(Icons.inventory_2_outlined, size: 44, color: kGoldPrimary.withOpacity(0.35)),
              const SizedBox(height: 12),
              Text("No packages available", style: TextStyle(color: kCharcoal.withOpacity(0.4), fontSize: 13, fontWeight: FontWeight.w600)),
            ])),
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
            final String name = data['name'] ?? "";
            final double originalPrice = (data['originalPrice'] ?? 0).toDouble();
            final double discountedPrice = (data['discountedPrice'] ?? 0).toDouble();
            final List services = List.from(data['services'] ?? []);
            final int discountPct = originalPrice > 0
                ? (((originalPrice - discountedPrice) / originalPrice) * 100).round()
                : 0;

            return GestureDetector(
              onTap: () => showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => _MultiStaffPackageDialog(
                  packageName: name,
                  services: services,
                  originalPrice: originalPrice,
                  discountedPrice: discountedPrice,
                  selectedDate: selectedDate,
                ),
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: kGoldPrimary.withOpacity(0.3), width: 1.8),
                    boxShadow: [BoxShadow(color: kGoldDark.withOpacity(0.07), blurRadius: 8, offset: const Offset(0, 4))]),
                child: Row(children: [
                  Container(
                      width: isTablet ? 52 : 44,
                      height: isTablet ? 52 : 44,
                      decoration: BoxDecoration(color: const Color(0xFFF3F3F3), borderRadius: BorderRadius.circular(14)),
                      child: Icon(Icons.inventory_2_rounded, color: kCharcoal.withOpacity(0.35), size: isTablet ? 24 : 20)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(name, style: TextStyle(fontSize: isTablet ? 15 : 13, fontWeight: FontWeight.w800, color: kCharcoal)),
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 5,
                        runSpacing: 4,
                        children: services.take(3).map((s) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: kCharcoal.withOpacity(0.06), borderRadius: BorderRadius.circular(20)),
                          child: Text(s.toString(), style: TextStyle(fontSize: isTablet ? 10 : 9, color: kCharcoal.withOpacity(0.55), fontWeight: FontWeight.w600)),
                        )).toList(),
                      ),
                      if (services.length > 3)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text("+${services.length - 3} more", style: TextStyle(fontSize: 9, color: kGoldDark, fontWeight: FontWeight.w700)),
                        ),
                    ]),
                  ),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    if (discountPct > 0)
                      Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(20)),
                          child: Text("$discountPct% OFF", style: TextStyle(fontSize: 9, color: Colors.green.shade700, fontWeight: FontWeight.w800))),
                    const SizedBox(height: 4),
                    if (originalPrice > 0)
                      Text("Rs ${originalPrice.toStringAsFixed(0)}",
                          style: TextStyle(fontSize: isTablet ? 11 : 10, decoration: TextDecoration.lineThrough, color: Colors.grey.shade400, fontWeight: FontWeight.w500)),
                    Text("Rs ${discountedPrice.toStringAsFixed(0)}",
                        style: TextStyle(fontSize: isTablet ? 17 : 15, fontWeight: FontWeight.w900, color: kGoldDark)),
                  ]),
                ]),
              ),
            );
          },
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ✅ MULTI STAFF PACKAGE DIALOG (packages file mein hi hai)
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
  final Map<String, String> _serviceToStaffMap = {};
  bool _isLoadingEmployees = true;
  bool _isSaving = false;
  List<Map<String, dynamic>> _allEmployees = [];
  final Map<String, Uint8List> _imageCache = {};

  @override
  void initState() {
    super.initState();
    _fetchEmployees();
  }

  void _fetchEmployees() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('employees')
          .where('status', isEqualTo: 'Active')
          .get();
      setState(() {
        _allEmployees = snapshot.docs.map((doc) => {
          'id': doc.id,
          'name': doc['name'] ?? '',
          'image': doc['image'],
        }).toList();
        _isLoadingEmployees = false;
      });
    } catch (e) {
      setState(() => _isLoadingEmployees = false);
    }
  }

  Uint8List? _getOrDecodeImage(String name, String? base64Str) {
    if (base64Str == null) return null;
    if (!_imageCache.containsKey(name)) {
      try { _imageCache[name] = base64Decode(base64Str); } catch (_) { return null; }
    }
    return _imageCache[name];
  }

  Future<void> _confirmAndSave() async {
    if (_serviceToStaffMap.length != widget.services.length) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⚠️ Har service ke liye staff select karo"), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isSaving = true);

    try {
      double perServicePrice = widget.services.isNotEmpty ? widget.discountedPrice / widget.services.length : 0;

      Map<String, List<Map<String, dynamic>>> groupedByEmployee = {};
      _serviceToStaffMap.forEach((serviceName, staffName) {
        groupedByEmployee.putIfAbsent(staffName, () => []);
        groupedByEmployee[staffName]!.add({'name': serviceName, 'price': perServicePrice, 'isPackageService': true});
      });

      WriteBatch batch = FirebaseFirestore.instance.batch();
      groupedByEmployee.forEach((staffName, assignedServices) {
        double empTotal = assignedServices.fold(0, (sum, s) => sum + (s['price'] ?? 0.0));
        DocumentReference docRef = FirebaseFirestore.instance.collection('transactions').doc();
        batch.set(docRef, {
          'staffName': staffName,
          'services': assignedServices,
          'totalPrice': empTotal,
          'status': "Unapproved",
          'timestamp': Timestamp.fromDate(widget.selectedDate),
          'dateOnly': DateFormat('yyyy-MM-dd').format(widget.selectedDate),
          'time': DateFormat('hh:mm a').format(DateTime.now()),
          'isPackage': true,
          'packageName': widget.packageName,
        });
      });

      await batch.commit();

      // ✅ ReceiptPrinter use kar raha hai (alag file se)
      await ReceiptPrinter.printPackageReceipt(
        packageName: widget.packageName,
        services: widget.services.map((s) => {"name": s.toString(), "price": perServicePrice}).toList(),
        originalPrice: widget.originalPrice,
        discountedPrice: widget.discountedPrice,
        serviceToStaffMap: _serviceToStaffMap,
        date: widget.selectedDate,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("✅ Package split into ${groupedByEmployee.length} entries & Printed!"),
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
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ─── Header ───
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFFF8E9B0).withOpacity(0.6), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.inventory_2_rounded, color: Color(0xFFAA8C2C), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text("Assign Staff per Service", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1F1F1F))),
                  Text(widget.packageName, style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                ])),
                Text("Rs ${widget.discountedPrice.toStringAsFixed(0)}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFFAA8C2C))),
              ]),
            ),
            const Divider(height: 1),

            // ─── Services List ───
            Expanded(
              child: _isLoadingEmployees
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: widget.services.length,
                itemBuilder: (context, index) {
                  final String serviceName = widget.services[index].toString();
                  String? selectedStaffName = _serviceToStaffMap[serviceName];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: selectedStaffName != null ? const Color(0xFFD4AF37) : Colors.grey.shade200,
                          width: 1.2),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(serviceName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                        if (selectedStaffName != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: const Color(0xFFD4AF37).withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                            child: Text(selectedStaffName, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFAA8C2C))),
                          ),
                      ]),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 72,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _allEmployees.length,
                          itemBuilder: (context, empIndex) {
                            final emp = _allEmployees[empIndex];
                            final String empName = emp['name'];
                            final Uint8List? bytes = _getOrDecodeImage(empName, emp['image']);
                            final bool isSelected = selectedStaffName == empName;

                            return GestureDetector(
                              onTap: () => setState(() => _serviceToStaffMap[serviceName] = empName),
                              child: Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Column(children: [
                                  Container(
                                    decoration: isSelected
                                        ? BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFD4AF37), width: 2.5))
                                        : null,
                                    child: CircleAvatar(
                                      radius: 24,
                                      backgroundColor: Colors.grey.shade200,
                                      backgroundImage: bytes != null ? MemoryImage(bytes) : null,
                                      child: bytes == null ? const Icon(Icons.person, color: Color(0xFFAA8C2C), size: 26) : null,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  SizedBox(
                                    width: 52,
                                    child: Text(empName,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                                            color: isSelected ? const Color(0xFFAA8C2C) : Colors.grey.shade700),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                ]),
                              ),
                            );
                          },
                        ),
                      ),
                    ]),
                  );
                },
              ),
            ),

            // ─── Confirm Button ───
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _confirmAndSave,
                  icon: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.check_circle_rounded, color: Colors.white),
                  label: Text(_isSaving ? "Saving..." : "Confirm & Split Entries",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _serviceToStaffMap.length != widget.services.length ? Colors.grey : const Color(0xFF1F1F1F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}