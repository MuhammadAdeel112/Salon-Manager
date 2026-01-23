import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageEmployees extends StatefulWidget {
  const ManageEmployees({super.key});

  @override
  State<ManageEmployees> createState() => _ManageEmployeesState();
}

class _ManageEmployeesState extends State<ManageEmployees> {
  final _nameController = TextEditingController();
  final _valueController = TextEditingController();
  String _empType = "Commission";

  void _addEmployee() async {
    if (_nameController.text.isNotEmpty && _valueController.text.isNotEmpty) {
      await FirebaseFirestore.instance.collection('employees').add({
        'name': _nameController.text,
        'type': _empType,
        // FIX: Yahan 'value' ki jagah 'commission' kar diya hai taake Dashboard calculate kar sake
        'commission': double.parse(_valueController.text),
        'status': 'Active',
        'createdAt': DateTime.now(),
      });
      _nameController.clear();
      _valueController.clear();
      Navigator.pop(context);
    }
  }

  // Confirmation Dialog for Delete
  void _confirmDelete(String docId, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Employee?"),
        content: Text("Are you sure you want to remove '$name' from the list? This record will be deleted."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('employees').doc(docId).delete();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("$name removed"), backgroundColor: Colors.red),
              );
            },
            child: const Text("DELETE", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Staff Management", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('employees').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var emp = snapshot.data!.docs[index];
              var data = emp.data() as Map<String, dynamic>;

              // Dono fields ko check kar raha hai taake purana aur naya data dono nazar aayein
              double commissionValue = (data['commission'] ?? data['value'] ?? 0).toDouble();

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text(data['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${data['type']}: $commissionValue${data['type'] == 'Commission' ? '%' : ' PKR'}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        activeColor: Colors.green,
                        value: data['status'] == 'Active',
                        onChanged: (val) {
                          FirebaseFirestore.instance.collection('employees').doc(emp.id).update({'status': val ? 'Active' : 'Inactive'});
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () => _confirmDelete(emp.id, data['name']),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        onPressed: () => _showAddDialog(),
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }

  void _showAddDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Add New Employee", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Full Name", border: OutlineInputBorder())),
            const SizedBox(height: 15),
            DropdownButtonFormField(
              value: _empType,
              items: ["Commission", "Fixed Salary"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => setState(() => _empType = val.toString()),
              decoration: const InputDecoration(labelText: "Payment Type", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),
            TextField(
                controller: _valueController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Commission % or Monthly Salary", border: OutlineInputBorder(), prefixIcon: Icon(Icons.payments_outlined))
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  onPressed: _addEmployee,
                  child: const Text("SAVE EMPLOYEE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}