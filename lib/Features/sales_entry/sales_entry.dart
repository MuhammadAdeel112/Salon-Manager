import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class StaffEntryScreen extends StatefulWidget {
  @override
  _StaffEntryScreenState createState() => _StaffEntryScreenState();
}

class _StaffEntryScreenState extends State<StaffEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedStaff;
  DateTime _selectedDate = DateTime.now();

  List<Map<String, dynamic>> _selectedServicesList = [];
  Map<String, double> _servicePrices = {};
  String? _currentService;

  final TextEditingController _otherServiceNameController = TextEditingController();
  final TextEditingController _otherServicePriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  void _fetchServices() async {
    var snapshot = await FirebaseFirestore.instance.collection('services').get();
    Map<String, double> fetchedServices = {};
    for (var doc in snapshot.docs) {
      fetchedServices[doc['name']] = (doc['price'] as num).toDouble();
    }
    if (!fetchedServices.containsKey("Other")) {
      fetchedServices["Other"] = 0.0;
    }
    setState(() => _servicePrices = fetchedServices);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.indigo, onPrimary: Colors.white, onSurface: Colors.black),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) setState(() => _selectedDate = picked);
  }

  double get _totalAmount => _selectedServicesList.fold(0, (sum, item) => sum + item['price']);

  void _submitData() async {
    if (_selectedStaff == null || _selectedServicesList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select Staff and at least one Service"), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('transactions').add({
        'staffName': _selectedStaff,
        'services': _selectedServicesList,
        'totalPrice': _totalAmount,
        'status': "Unapproved",
        'timestamp': Timestamp.fromDate(_selectedDate),
        'dateOnly': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'time': DateFormat('hh:mm a').format(DateTime.now()), // Time add kiya asaan filter ke liye
      });

      setState(() {
        _selectedStaff = null;
        _selectedServicesList = [];
        _selectedDate = DateTime.now();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Entry Saved Successfully"), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("New Staff Entry", style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // STEP 1: Date & Staff
            Row(
              children: [
                Expanded(child: _buildSectionTitle("Select Date")),
                Expanded(child: _buildSectionTitle("Select Staff")),
              ],
            ),
            Row(
              children: [
                Expanded(child: _buildDateSelector()),
                const SizedBox(width: 12),
                Expanded(child: _buildStaffDropdown()),
              ],
            ),

            const SizedBox(height: 20),
            _buildSectionTitle("Select Services"),
            _buildServiceSelector(),

            _buildSelectedServicesChips(),

            if (_selectedServicesList.isNotEmpty) _buildTotalAmountDisplay(),

            const SizedBox(height: 30),

            // ACTION BUTTONS
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  shadowColor: Colors.black.withOpacity(0.3),
                ),
                onPressed: _submitData,
                child: const Text("SAVE TRANSACTION", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => _showExpenseModal(context),
                icon: const Icon(Icons.receipt_long_rounded, color: Colors.redAccent),
                label: const Text("ADD SHOP EXPENSE", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              ),
            ),

            const SizedBox(height: 35),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionTitle("Recent History"),
                const Text("Last 5 entries", style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
            _buildRecentTransactions(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildSectionTitle(String title) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54, letterSpacing: 0.5)));

  Widget _buildDateSelector() {
    return InkWell(
      onTap: () => _selectDate(context),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
        child: Row(children: [
          const Icon(Icons.calendar_today_rounded, color: Colors.indigo, size: 18),
          const SizedBox(width: 10),
          Text(DateFormat('dd MMM').format(_selectedDate), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ]),
      ),
    );
  }

  Widget _buildStaffDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('employees').where('status', isEqualTo: 'Active').snapshots(),
        builder: (context, snapshot) {
          return DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedStaff,
              hint: const Text("Staff", style: TextStyle(fontSize: 14)),
              items: snapshot.data?.docs.map((s) => DropdownMenuItem(value: s['name'].toString(), child: Text(s['name'], style: const TextStyle(fontSize: 14)))).toList() ?? [],
              onChanged: (val) => setState(() => _selectedStaff = val),
            ),
          );
        },
      ),
    );
  }

  Widget _buildServiceSelector() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _currentService,
                hint: const Text("Pick a Service"),
                items: _servicePrices.keys.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (val) {
                  setState(() => _currentService = val);
                  if (val == "Other") _showOtherServiceModal();
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _addServiceToList,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.indigo, borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedServicesChips() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _selectedServicesList.map((s) => Chip(
          backgroundColor: Colors.indigo.withOpacity(0.08),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          label: Text("${s['name']} - Rs ${s['price']}", style: const TextStyle(color: Colors.indigo, fontSize: 12, fontWeight: FontWeight.w600)),
          onDeleted: () => setState(() => _selectedServicesList.remove(s)),
          deleteIcon: const Icon(Icons.cancel, size: 16, color: Colors.indigo),
        )).toList(),
      ),
    );
  }

  Widget _buildTotalAmountDisplay() {
    return Container(
      margin: const EdgeInsets.only(top: 25),
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.indigo.shade700, Colors.indigo.shade500]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.indigo.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          const Text("Total Bill Amount", style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 5),
          Text("PKR ${_totalAmount.toStringAsFixed(0)}", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('transactions').orderBy('timestamp', descending: true).limit(5).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: LinearProgressIndicator());
        return Column(
          children: snapshot.data!.docs.map((doc) {
            var data = doc.data() as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade100)),
              child: ListTile(
                dense: true,
                leading: CircleAvatar(backgroundColor: Colors.grey.shade100, child: const Icon(Icons.person_outline, size: 18, color: Colors.indigo)),
                title: Text(data['staffName'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(data['dateOnly'] ?? "", style: const TextStyle(fontSize: 10)),
                trailing: Text("Rs ${data['totalPrice']}", style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.green)),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // --- MODALS (Other Service & Expense) ---

  void _showOtherServiceModal() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Custom Work", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _otherServiceNameController, decoration: _inputDeco("Work Name", Icons.edit)),
            const SizedBox(height: 12),
            TextField(controller: _otherServicePriceController, keyboardType: TextInputType.number, decoration: _inputDeco("Price", Icons.payments)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () {
              if (_otherServiceNameController.text.isNotEmpty && _otherServicePriceController.text.isNotEmpty) {
                setState(() {
                  _selectedServicesList.add({"name": _otherServiceNameController.text.trim(), "price": double.parse(_otherServicePriceController.text)});
                  _currentService = null;
                  _otherServiceNameController.clear(); _otherServicePriceController.clear();
                });
                Navigator.pop(context);
              }
            },
            child: const Text("ADD SERVICE", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showExpenseModal(BuildContext context) {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController noteController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, top: 20, left: 24, right: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            const Text("Shop Expense (Kharcha)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent)),
            const SizedBox(height: 25),
            TextField(controller: amountController, keyboardType: TextInputType.number, decoration: _inputDeco("Amount (PKR)", Icons.money_off)),
            const SizedBox(height: 15),
            TextField(controller: noteController, decoration: _inputDeco("Detail / Note", Icons.note_add)),
            const SizedBox(height: 25),
            SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                    onPressed: () async {
                      if (amountController.text.isNotEmpty) {
                        await FirebaseFirestore.instance.collection('expenses').add({
                          'amount': double.parse(amountController.text),
                          'description': noteController.text,
                          'dateOnly': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                          'timestamp': FieldValue.serverTimestamp(),
                        });
                        Navigator.pop(context);
                      }
                    },
                    child: const Text("SAVE EXPENSE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                )
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label, prefixIcon: Icon(icon, size: 20),
      filled: true, fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
    );
  }

  void _addServiceToList() {
    if (_currentService == "Other") { _showOtherServiceModal(); }
    else if (_currentService != null) {
      setState(() {
        _selectedServicesList.add({"name": _currentService, "price": _servicePrices[_currentService]});
        _currentService = null;
      });
    }
  }
}