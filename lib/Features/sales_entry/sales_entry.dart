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
    );
    if (picked != null && picked != _selectedDate) setState(() => _selectedDate = picked);
  }

  double get _totalAmount => _selectedServicesList.fold(0, (sum, item) => sum + item['price']);

  void _submitData() async {
    if (_selectedStaff == null || _selectedServicesList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select Staff and at least one Service")),
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
      });

      setState(() {
        _selectedStaff = null;
        _selectedServicesList = [];
        _selectedDate = DateTime.now();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Entry Saved Successfully"), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  void _showOtherServiceModal() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.stars, color: Colors.indigo), // Changed to Indigo
            const SizedBox(width: 10),
            const Text("Custom Work", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _otherServiceNameController,
              decoration: InputDecoration(
                labelText: "Work Name",
                prefixIcon: const Icon(Icons.edit, color: Colors.indigo),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _otherServicePriceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Price",
                prefixText: "PKR ",
                prefixIcon: const Icon(Icons.payments, color: Colors.green),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _currentService = null);
            },
            child: Text("CANCEL", style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo, // Changed to Indigo
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              if (_otherServiceNameController.text.isNotEmpty && _otherServicePriceController.text.isNotEmpty) {
                setState(() {
                  _selectedServicesList.add({
                    "name": _otherServiceNameController.text.trim(),
                    "price": double.parse(_otherServicePriceController.text),
                  });
                  _currentService = null;
                  _otherServiceNameController.clear();
                  _otherServicePriceController.clear();
                });
                Navigator.pop(context);
              }
            },
            child: const Text("ADD TO LIST", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _addServiceToList() {
    if (_currentService == "Other") {
      _showOtherServiceModal();
    } else if (_currentService != null) {
      setState(() {
        _selectedServicesList.add({
          "name": _currentService,
          "price": _servicePrices[_currentService],
        });
        _currentService = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Dashboard Background
      appBar: AppBar(
        title: const Text("Staff Entry",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("1. Select Date"),
            _buildDateSelector(),
            _buildSectionTitle("2. Select Staff"),
            _buildStaffDropdown(),
            _buildSectionTitle("3. Add Services"),
            _buildServiceSelector(),
            _buildSelectedServicesChips(),
            _buildTotalAmountDisplay(),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black, // Dark/Black theme for Primary Button
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 0
                ),
                onPressed: _submitData,
                child: const Text("Save Full Transaction",
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
              ),
              onPressed: () => _showExpenseModal(context),
              icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
              label: const Text("ADD SHOP EXPENSE (KHARCHA)",
                  style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 30),
            _buildSectionTitle("Recent History"),
            _buildRecentTransactions(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Padding(
      padding: const EdgeInsets.only(top: 15, bottom: 8),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)));

  Widget _buildDateSelector() {
    return InkWell(
      onTap: () => _selectDate(context),
      child: _buildSelectionCard(icon: Icons.calendar_month, child: Padding(padding: const EdgeInsets.symmetric(vertical: 15), child: Text(DateFormat('dd MMMM, yyyy').format(_selectedDate), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.indigo)))),
    );
  }

  Widget _buildStaffDropdown() {
    return _buildSelectionCard(
      icon: Icons.person,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('employees').where('status', isEqualTo: 'Active').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Text("Loading...");
          return DropdownButtonFormField<String>(
            value: _selectedStaff,
            hint: const Text("Choose Staff"),
            decoration: const InputDecoration(border: InputBorder.none),
            items: snapshot.data!.docs.map((s) => DropdownMenuItem(value: s['name'].toString(), child: Text(s['name']))).toList(),
            onChanged: (val) => setState(() => _selectedStaff = val),
          );
        },
      ),
    );
  }

  Widget _buildServiceSelector() {
    return Row(children: [
      Expanded(child: _buildSelectionCard(icon: Icons.content_cut, child: DropdownButton<String>(
          isExpanded: true,
          value: _currentService,
          hint: const Text("Pick Service"),
          underline: const SizedBox(),
          items: _servicePrices.keys.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (val) {
            setState(() => _currentService = val);
            if (val == "Other") _showOtherServiceModal();
          }
      ))),
      const SizedBox(width: 8),
      IconButton(
          icon: const Icon(Icons.add_circle, color: Colors.indigo, size: 45),
          onPressed: _addServiceToList
      ),
    ]);
  }

  Widget _buildSelectedServicesChips() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Wrap(spacing: 8, children: _selectedServicesList.map((s) => Chip(
          backgroundColor: Colors.indigo.withOpacity(0.05),
          side: BorderSide(color: Colors.indigo.withOpacity(0.1)),
          label: Text("${s['name']} (Rs.${s['price']})", style: const TextStyle(color: Colors.indigo, fontSize: 12)),
          onDeleted: () => setState(() => _selectedServicesList.remove(s)),
          deleteIconColor: Colors.redAccent)).toList()),
    );
  }

  Widget _buildTotalAmountDisplay() {
    if (_selectedServicesList.isEmpty) return const SizedBox();
    return Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: Center(child: Column(children: [const Text("Total Amount", style: TextStyle(color: Colors.grey, fontSize: 12)), Text("PKR $_totalAmount", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black))])));
  }

  Widget _buildSelectionCard({required IconData icon, required Widget child}) {
    return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(children: [Icon(icon, color: Colors.indigo, size: 20), const SizedBox(width: 12), Expanded(child: child)]));
  }

  Widget _buildRecentTransactions() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('transactions').orderBy('timestamp', descending: true).limit(5).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();
        return ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: snapshot.data!.docs.length, itemBuilder: (context, index) {
          var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
          return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: ListTile(
                  leading: const CircleAvatar(backgroundColor: Color(0xFFF5F6F9), child: Icon(Icons.person, color: Colors.indigo, size: 20)),
                  title: Text(data['staffName'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text(data['dateOnly'] ?? "", style: const TextStyle(fontSize: 11)),
                  trailing: Text("Rs ${data['totalPrice']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 14))));
        });
      },
    );
  }

  void _showExpenseModal(BuildContext context) {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController noteController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, top: 20, left: 20, right: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: SizedBox(width: 40, child: Divider(thickness: 4))),
            const SizedBox(height: 15),
            const Text("Shop Expense (Kharcha)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent)),
            const SizedBox(height: 20),
            TextField(controller: amountController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "Amount", prefixText: "PKR ", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 15),
            TextField(controller: noteController, decoration: InputDecoration(labelText: "Detail", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 20),
            SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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
}