import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'staff_provider.dart';

class ManageEmployees extends StatefulWidget {
  const ManageEmployees({super.key});

  @override
  State<ManageEmployees> createState() => _ManageEmployeesState();
}

class _ManageEmployeesState extends State<ManageEmployees> {
  final _nameController = TextEditingController();
  final _salaryController = TextEditingController();
  final _commissionController = TextEditingController();

  String _empType = "Commission";
  String? _base64Image;
  final ImagePicker _picker = ImagePicker();

  final Color kBg = const Color(0xFFFFFDE7);
  final Color kGoldLight = const Color(0xFFF3E5AB);
  final Color kGoldPrimary = const Color(0xFFD4AF37);
  final Color kGoldDark = const Color(0xFFC69C34);
  final Color kCharcoal = const Color(0xFF2C2C2C);

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 30);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() => _base64Image = base64Encode(bytes));
    }
  }

  void _processEmployee({String? docId}) {
    if (_nameController.text.isNotEmpty) {
      // --- FIXED: Using standardized field names for AdminDashboard ---
      context.read<StaffProvider>().saveEmployee(
        docId: docId,
        name: _nameController.text.trim(),
        type: _empType,
        salary: double.tryParse(_salaryController.text) ?? 0.0,
        commission: double.tryParse(_commissionController.text) ?? 0.0,
        image: _base64Image ?? "",
      );

      Navigator.pop(context);
      _clearForm();
    }
  }

  void _clearForm() {
    _nameController.clear();
    _salaryController.clear();
    _commissionController.clear();
    setState(() {
      _base64Image = null;
      _empType = "Commission";
    });
  }

  void _confirmDelete(String docId, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text("Delete Employee?", style: TextStyle(color: kCharcoal, fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to remove '$name'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("CANCEL", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, elevation: 0),
            onPressed: () {
              FirebaseFirestore.instance.collection('employees').doc(docId).delete();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("$name deleted successfully"), backgroundColor: Colors.redAccent)
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
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: Text("Staff Management", style: TextStyle(fontWeight: FontWeight.w800, color: kCharcoal, fontSize: 20)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('employees').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator(color: kGoldDark));

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var emp = snapshot.data!.docs[index];
              var data = emp.data() as Map<String, dynamic>;

              // --- FIXED: Data display logic aligned with Dashboard ---
              double salary = (data['salary'] ?? data['base_salary'] ?? 0).toDouble();
              double commission = (data['commission'] ?? data['commission_percentage'] ?? 0).toDouble();
              String type = data['type'] ?? "Commission";

              String? empImage = data['image'];
              String serverStatus = data['status'] ?? 'Active';

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: kGoldDark.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 50, height: 50,
                        decoration: BoxDecoration(color: kGoldLight, shape: BoxShape.circle),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: (empImage != null && empImage.isNotEmpty)
                              ? Image.memory(base64Decode(empImage), fit: BoxFit.cover, gaplessPlayback: true)
                              : Icon(Icons.person, color: kGoldDark),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: InkWell(
                          onTap: () => _showAddDialog(docId: emp.id, existingData: data),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data['name'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kCharcoal)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(color: kGoldPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                    child: Text(type, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: kGoldDark)),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      type == "Both" ? "${salary.toStringAsFixed(0)} + ${commission.toStringAsFixed(0)}%"
                                          : type == "Fixed Salary" ? "${salary.toStringAsFixed(0)} PKR"
                                          : "${commission.toStringAsFixed(0)}%",
                                      style: TextStyle(fontSize: 11, color: kGoldDark, fontWeight: FontWeight.w500, overflow: TextOverflow.ellipsis),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Column(
                        children: [
                          Consumer<StaffProvider>(
                            builder: (context, provider, child) {
                              bool active = provider.getIsActive(emp.id, serverStatus);
                              return Transform.scale(
                                scale: 0.8,
                                child: Switch(
                                  activeColor: kGoldPrimary,
                                  value: active,
                                  onChanged: (val) => provider.toggleStatus(emp.id, val),
                                ),
                              );
                            },
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent, size: 20),
                                onPressed: () => _showAddDialog(docId: emp.id, existingData: data),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                onPressed: () => _confirmDelete(emp.id, data['name']),
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
        backgroundColor: kCharcoal,
        onPressed: () => _showAddDialog(),
        label: Text("ADD STAFF", style: TextStyle(fontWeight: FontWeight.bold, color: kGoldPrimary)),
        icon: Icon(Icons.add, color: kGoldPrimary),
      ),
    );
  }

  void _showAddDialog({String? docId, Map<String, dynamic>? existingData}) {
    if (existingData != null) {
      _nameController.text = existingData['name'] ?? "";
      // Load both old and new field names for compatibility
      _salaryController.text = (existingData['salary'] ?? existingData['base_salary'] ?? "").toString();
      _commissionController.text = (existingData['commission'] ?? existingData['commission_percentage'] ?? "").toString();
      _empType = existingData['type'] ?? "Commission";
      _base64Image = existingData['image'];
    } else {
      _clearForm();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, left: 24, right: 24, top: 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
                    const SizedBox(height: 20),
                    Text(docId == null ? "Add New Staff Member" : "Edit Staff Member",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kCharcoal)),
                    const SizedBox(height: 20),
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: kGoldLight,
                            backgroundImage: _base64Image != null && _base64Image!.isNotEmpty ? MemoryImage(base64Decode(_base64Image!)) : null,
                            child: (_base64Image == null || _base64Image!.isEmpty) ? Icon(Icons.person, size: 40, color: kGoldDark) : null,
                          ),
                          Positioned(
                            bottom: 0, right: 0,
                            child: GestureDetector(
                              onTap: () async {
                                await _pickImage();
                                setModalState(() {});
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(color: kCharcoal, shape: BoxShape.circle),
                                child: Icon(Icons.camera_alt, color: kGoldPrimary, size: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    _buildTextField(_nameController, "Full Name", Icons.person_outline),
                    const SizedBox(height: 16),
                    DropdownButtonFormField(
                      value: _empType,
                      items: ["Commission", "Fixed Salary", "Both"].map((e) => DropdownMenuItem(value: e, child: Text(e, style: TextStyle(color: kCharcoal)))).toList(),
                      onChanged: (val) {
                        setModalState(() => _empType = val.toString());
                      },
                      decoration: _inputDecoration("Payment Type", Icons.payments_outlined),
                    ),
                    const SizedBox(height: 16),

                    if (_empType == "Fixed Salary" || _empType == "Both")
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildTextField(_salaryController, "Fixed Salary (PKR)", Icons.money, isNumber: true),
                      ),

                    if (_empType == "Commission" || _empType == "Both")
                      _buildTextField(_commissionController, "Commission (%)", Icons.analytics_outlined, isNumber: true),

                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity, height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: kCharcoal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        onPressed: () => _processEmployee(docId: docId),
                        child: Text(docId == null ? "SAVE STAFF" : "UPDATE STAFF",
                            style: TextStyle(color: kGoldPrimary, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: _inputDecoration(label, icon),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: kGoldDark, fontSize: 14),
      prefixIcon: Icon(icon, color: kGoldDark, size: 20),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kGoldPrimary, width: 1.5)),
      filled: true,
      fillColor: const Color(0xFFF9F9F9),
    );
  }
}