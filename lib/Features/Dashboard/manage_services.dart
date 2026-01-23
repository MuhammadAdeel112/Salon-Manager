import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageServices extends StatelessWidget {
  const ManageServices({super.key});

  // Confirmation Dialog Function
  void _confirmDelete(BuildContext context, String docId, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Service?"),
        content: Text("Are you sure you want to remove '$name' from the list?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCEL")
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('services').doc(docId).delete();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("$name deleted"), backgroundColor: Colors.red),
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
    final nameController = TextEditingController();
    final priceController = TextEditingController();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Service Prices", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('services').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var service = snapshot.data!.docs[index];
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  leading: const Icon(Icons.content_cut, color: Colors.teal),
                  title: Text(service['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Status: ${service['status']}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("PKR ${service['price']}",
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () => _confirmDelete(context, service.id, service['name']),
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
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              title: const Text("Add New Service"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: "Service Name", border: OutlineInputBorder())
                  ),
                  const SizedBox(height: 15),
                  TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Price (PKR)", border: OutlineInputBorder())
                  ),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("CANCEL")
                ),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
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
                    child: const Text("ADD SERVICE", style: TextStyle(color: Colors.white))
                ),
              ],
            ),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}