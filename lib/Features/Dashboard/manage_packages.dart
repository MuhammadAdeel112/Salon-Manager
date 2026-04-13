import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManagePackages extends StatelessWidget {
  const ManagePackages({super.key});

  static const Color kBg = Color(0xFFFDFAF3);
  static const Color kGoldLight = Color(0xFFF8E9B0);
  static const Color kGoldPrimary = Color(0xFFD4AF37);
  static const Color kGoldDark = Color(0xFFAA8C2C);
  static const Color kCharcoal = Color(0xFF1F1F1F);
  static const Color kWhite = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Manage Packages",
          style: TextStyle(
              color: kCharcoal, fontSize: 15, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: kGoldDark),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_rounded, color: kGoldDark),
            onPressed: () => _showPackageDialog(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('packages')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: kGoldDark));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inventory_2_outlined,
                      size: 64, color: kGoldPrimary.withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  Text("No packages yet",
                      style: TextStyle(
                          color: kCharcoal.withValues(alpha: 0.5),
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text("Tap + to add a package",
                      style: TextStyle(
                          color: kCharcoal.withValues(alpha: 0.35), fontSize: 13)),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final String docId = docs[index].id;
              final String name = data['name'] ?? "";
              final double originalPrice =
              (data['originalPrice'] ?? 0).toDouble();
              final double discountedPrice =
              (data['discountedPrice'] ?? 0).toDouble();
              final List services = List.from(data['services'] ?? []);
              final bool isActive = data['isActive'] ?? true;

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: kWhite,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: isActive
                          ? kGoldPrimary.withValues(alpha: 0.3)
                          : Colors.grey.withValues(alpha: 0.2),
                      width: 1.2),
                  boxShadow: [
                    BoxShadow(
                        color: kGoldDark.withValues(alpha: 0.07),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: kGoldLight.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.inventory_2_rounded,
                                color: kGoldDark, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name,
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: kCharcoal)),
                                Text(
                                    "${services.length} service${services.length != 1 ? 's' : ''} included",
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: kCharcoal.withValues(alpha: 0.5))),
                              ],
                            ),
                          ),
                          Switch(
                            value: isActive,
                            activeThumbColor: kGoldPrimary,
                            onChanged: (val) {
                              FirebaseFirestore.instance
                                  .collection('packages')
                                  .doc(docId)
                                  .update({'isActive': val});
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: services.map((s) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: kGoldLight.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(s.toString(),
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: kGoldDark,
                                    fontWeight: FontWeight.w600)),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                "Rs ${originalPrice.toStringAsFixed(0)}",
                                style: TextStyle(
                                    fontSize: 13,
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.grey.shade400),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                "Rs ${discountedPrice.toStringAsFixed(0)}",
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: kGoldDark),
                              ),
                              const SizedBox(width: 8),
                              if (originalPrice > 0 && discountedPrice > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: Colors.green.shade300),
                                  ),
                                  child: Text(
                                    "${((1 - discountedPrice / originalPrice) * 100).toStringAsFixed(0)}% OFF",
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.green.shade700,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_rounded,
                                    color: kGoldDark, size: 20),
                                onPressed: () => _showPackageDialog(context,
                                    docId: docId, existingData: data),
                              ),
                              IconButton(
                                icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: Colors.red,
                                    size: 20),
                                onPressed: () =>
                                    _deletePackage(context, docId, name),
                              ),
                            ],
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPackageDialog(context),
        backgroundColor: kCharcoal,
        icon: const Icon(Icons.add_rounded, color: kGoldPrimary),
        label: const Text("Add Package",
            style: TextStyle(
                color: kGoldPrimary, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showPackageDialog(BuildContext context,
      {String? docId, Map<String, dynamic>? existingData}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          _PackageDialogWidget(docId: docId, existingData: existingData),
    );
  }

  void _deletePackage(BuildContext context, String docId, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Package",
            style: TextStyle(color: Colors.red)),
        content: Text("\"$name\" Do you want to delete the package?",
            style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseFirestore.instance
                  .collection('packages')
                  .doc(docId)
                  .delete();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Package deleted"),
                    backgroundColor: Colors.red));
              }
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Package Dialog — Fixed Size + Scrollable Services
// ══════════════════════════════════════════════════════════════════
class _PackageDialogWidget extends StatefulWidget {
  final String? docId;
  final Map<String, dynamic>? existingData;

  const _PackageDialogWidget({this.docId, this.existingData});

  @override
  State<_PackageDialogWidget> createState() => _PackageDialogWidgetState();
}

class _PackageDialogWidgetState extends State<_PackageDialogWidget> {
  late TextEditingController _nameCtrl;
  late TextEditingController _discountPctCtrl;
  late TextEditingController _packagePriceCtrl;

  bool _isSaving = false;
  bool _isLoadingServices = true;
  bool _isEditingDiscount = false;

  List<Map<String, dynamic>> _allServicesFromDb = [];
  Set<String> _selectedServiceNames = {};
  double _originalPrice = 0;

  bool get _isEdit => widget.docId != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
        text: _isEdit ? widget.existingData!['name'] ?? "" : "");
    _discountPctCtrl = TextEditingController();
    _packagePriceCtrl = TextEditingController(
        text: _isEdit
            ? (widget.existingData!['discountedPrice'] ?? "").toString()
            : "");

    if (_isEdit) {
      List existingServices =
      List.from(widget.existingData!['services'] ?? []);
      _selectedServiceNames =
          existingServices.map((s) => s.toString()).toSet();

      double origPrice =
      (widget.existingData!['originalPrice'] ?? 0).toDouble();
      double discPrice =
      (widget.existingData!['discountedPrice'] ?? 0).toDouble();
      if (origPrice > 0 && discPrice > 0) {
        double pct = ((1 - discPrice / origPrice) * 100);
        _discountPctCtrl.text = pct.toStringAsFixed(0);
      }
    }

    _discountPctCtrl.addListener(_onDiscountPctChanged);
    _packagePriceCtrl.addListener(_onPackagePriceChanged);
    _fetchServicesFromDb();
  }

  Future<void> _fetchServicesFromDb() async {
    try {
      final snapshot =
      await FirebaseFirestore.instance.collection('services').get();
      setState(() {
        _allServicesFromDb = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'name': data['name'] ?? '',
            'price': (data['price'] ?? 0).toDouble(),
          };
        }).toList();
        _isLoadingServices = false;
        _recalculateOriginalPrice();
      });
    } catch (e) {
      setState(() => _isLoadingServices = false);
    }
  }

  void _recalculateOriginalPrice() {
    double total = 0;
    for (var service in _allServicesFromDb) {
      if (_selectedServiceNames.contains(service['name'])) {
        total += (service['price'] as double);
      }
    }
    setState(() => _originalPrice = total);
    if (_discountPctCtrl.text.isNotEmpty) _onDiscountPctChanged();
  }

  void _onDiscountPctChanged() {
    if (_isEditingDiscount) return;
    _isEditingDiscount = true;
    final pct = double.tryParse(_discountPctCtrl.text.trim()) ?? 0;
    if (_originalPrice > 0 && pct > 0 && pct < 100) {
      final pkgPrice = _originalPrice * (1 - pct / 100);
      final newText = pkgPrice.toStringAsFixed(0);
      if (_packagePriceCtrl.text != newText) {
        _packagePriceCtrl.text = newText;
        _packagePriceCtrl.selection = TextSelection.fromPosition(
            TextPosition(offset: _packagePriceCtrl.text.length));
      }
    }
    _isEditingDiscount = false;
  }

  void _onPackagePriceChanged() {
    if (_isEditingDiscount) return;
    _isEditingDiscount = true;
    final pkgPrice = double.tryParse(_packagePriceCtrl.text.trim()) ?? 0;
    if (_originalPrice > 0 && pkgPrice > 0 && pkgPrice < _originalPrice) {
      final pct = ((1 - pkgPrice / _originalPrice) * 100);
      final newText = pct.toStringAsFixed(0);
      if (_discountPctCtrl.text != newText) {
        _discountPctCtrl.text = newText;
        _discountPctCtrl.selection = TextSelection.fromPosition(
            TextPosition(offset: _discountPctCtrl.text.length));
      }
    }
    _isEditingDiscount = false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _discountPctCtrl.dispose();
    _packagePriceCtrl.dispose();
    super.dispose();
  }

  Future<void> _savePackage() async {
    if (_nameCtrl.text.trim().isEmpty ||
        _packagePriceCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Name and package price are required"),
          backgroundColor: Colors.red));
      return;
    }
    if (_selectedServiceNames.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Please select at least one service"),
          backgroundColor: Colors.red));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final Map<String, dynamic> packageData = {
        'name': _nameCtrl.text.trim(),
        'originalPrice': _originalPrice,
        'discountedPrice':
        double.tryParse(_packagePriceCtrl.text.trim()) ?? 0,
        'services': _selectedServiceNames.toList(),
        'isActive': true,
        'createdAt': _isEdit
            ? widget.existingData!['createdAt']
            : Timestamp.now(),
      };

      if (_isEdit) {
        await FirebaseFirestore.instance
            .collection('packages')
            .doc(widget.docId)
            .update(packageData);
      } else {
        await FirebaseFirestore.instance
            .collection('packages')
            .add(packageData);
      }

      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
          Text(_isEdit ? "✅ Package updated!" : "✅ Package added!"),
          backgroundColor: ManagePackages.kGoldDark,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Screen height se dialog height fix karo
    final double screenHeight = MediaQuery.of(context).size.height;

    final double pkgPrice =
        double.tryParse(_packagePriceCtrl.text.trim()) ?? 0;
    final double discountAmt = _originalPrice - pkgPrice;
    final double discountPct = _originalPrice > 0 && pkgPrice > 0
        ? ((1 - pkgPrice / _originalPrice) * 100)
        : 0;

    return Dialog(
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: ManagePackages.kWhite,
      // ✅ Dialog ka max height screen ka 85% — overflow nahi hoga
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Title ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isEdit ? "Edit Package" : "Add New Package",
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: ManagePackages.kCharcoal),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded,
                        color: ManagePackages.kCharcoal, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            const Divider(height: 16),

            // ✅ Scrollable content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Package Name ──
                    TextField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(
                        labelText: "Package Name",
                        labelStyle: const TextStyle(
                            color: ManagePackages.kGoldDark),
                        hintText: "e.g. Grooming Package",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: ManagePackages.kGoldPrimary)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Select Services ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Select Services",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: ManagePackages.kCharcoal)),
                        if (_selectedServiceNames.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: ManagePackages.kGoldLight
                                  .withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "${_selectedServiceNames.length} selected",
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: ManagePackages.kGoldDark,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // ✅ Services scrollable container — max height 160px
                    _isLoadingServices
                        ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(
                              color: ManagePackages.kGoldDark),
                        ))
                        : _allServicesFromDb.isEmpty
                        ? const Text(
                        "No services found. Please add services first",
                        style: TextStyle(
                            fontSize: 12, color: Colors.red))
                        : Container(
                      constraints:
                      const BoxConstraints(maxHeight: 160),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: ManagePackages.kGoldLight),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Scrollbar(
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(10),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _allServicesFromDb
                                .map((service) {
                              final String serviceName =
                              service['name'];
                              final double servicePrice =
                              service['price'];
                              final bool isSelected =
                              _selectedServiceNames
                                  .contains(serviceName);

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedServiceNames
                                          .remove(serviceName);
                                    } else {
                                      _selectedServiceNames
                                          .add(serviceName);
                                    }
                                    _recalculateOriginalPrice();
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(
                                      milliseconds: 200),
                                  padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? ManagePackages.kGoldDark
                                        : ManagePackages.kGoldLight
                                        .withValues(alpha: 0.4),
                                    borderRadius:
                                    BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? ManagePackages.kGoldDark
                                          : ManagePackages
                                          .kGoldPrimary
                                          .withValues(alpha: 0.3),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isSelected) ...[
                                        const Icon(
                                            Icons.check_circle,
                                            color: ManagePackages
                                                .kGoldLight,
                                            size: 13),
                                        const SizedBox(width: 4),
                                      ],
                                      Text(
                                        "$serviceName  •  Rs ${servicePrice.toStringAsFixed(0)}",
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight:
                                          FontWeight.w600,
                                          color: isSelected
                                              ? ManagePackages.kWhite
                                              : ManagePackages
                                              .kCharcoal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Price Calculator ──
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: ManagePackages.kGoldLight.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: ManagePackages.kGoldPrimary
                                .withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Price Calculator",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: ManagePackages.kGoldDark)),
                          const SizedBox(height: 10),

                          // Original Price row
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Original Price",
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: ManagePackages.kCharcoal)),
                              Row(
                                children: [
                                  Text(
                                    "Rs ${_originalPrice.toStringAsFixed(0)}",
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: ManagePackages.kCharcoal),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius:
                                      BorderRadius.circular(6),
                                      border: Border.all(
                                          color: Colors.blue.shade200),
                                    ),
                                    child: Text("Auto",
                                        style: TextStyle(
                                            fontSize: 9,
                                            color: Colors.blue.shade700,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Discount % ↔ Package Price
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _discountPctCtrl,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: ManagePackages.kCharcoal),
                                  decoration: InputDecoration(
                                    labelText: "Discount %",
                                    labelStyle: const TextStyle(
                                        color: ManagePackages.kGoldDark,
                                        fontSize: 11),
                                    suffixText: "%",
                                    border: OutlineInputBorder(
                                        borderRadius:
                                        BorderRadius.circular(10)),
                                    focusedBorder: OutlineInputBorder(
                                        borderRadius:
                                        BorderRadius.circular(10),
                                        borderSide: const BorderSide(
                                            color:
                                            ManagePackages.kGoldPrimary)),
                                    contentPadding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 10),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8),
                                child: Icon(Icons.swap_horiz_rounded,
                                    color: ManagePackages.kGoldDark,
                                    size: 20),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _packagePriceCtrl,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: ManagePackages.kGoldDark),
                                  decoration: InputDecoration(
                                    labelText: "Package Price",
                                    labelStyle: const TextStyle(
                                        color: ManagePackages.kGoldDark,
                                        fontSize: 11),
                                    prefixText: "Rs ",
                                    border: OutlineInputBorder(
                                        borderRadius:
                                        BorderRadius.circular(10)),
                                    focusedBorder: OutlineInputBorder(
                                        borderRadius:
                                        BorderRadius.circular(10),
                                        borderSide: const BorderSide(
                                            color:
                                            ManagePackages.kGoldPrimary)),
                                    contentPadding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 10),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Savings badge
                          if (discountAmt > 0) ...[
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: Colors.green.shade200),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.local_offer_rounded,
                                      color: Colors.green.shade700,
                                      size: 13),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Customer saves Rs ${discountAmt.toStringAsFixed(0)}  (${discountPct.toStringAsFixed(0)}% OFF)",
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.green.shade700,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // ── Actions ──
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                    _isSaving ? null : () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ManagePackages.kGoldPrimary,
                      foregroundColor: ManagePackages.kWhite,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                    onPressed: _isSaving ? null : _savePackage,
                    child: _isSaving
                        ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                        : Text(_isEdit ? "Update" : "Save Package"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}