import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StaffProvider with ChangeNotifier {
  // Local status map taake switch foran toggle ho
  final Map<String, bool> _localStatus = {};

  bool getIsActive(String docId, String serverStatus) {
    return _localStatus[docId] ?? (serverStatus == 'Active');
  }

  // --- NEW: Handle Employee Data Save/Update ---
  // Ye function "Both" logic ko handle karega
  Future<void> saveEmployee({
    String? docId,
    required String name,
    required String type,
    required double salary,
    required double commission,
    required String image,
  }) async {
    final data = {
      'name': name,
      'type': type,
      'base_salary': salary, // Alag field for Salary
      'commission_percentage': commission, // Alag field for %
      'image': image,
    };

    if (docId == null) {
      // Naya banda add ho raha hai
      data['status'] = 'Active';
      data['createdAt'] = FieldValue.serverTimestamp();
      await FirebaseFirestore.instance.collection('employees').add(data);
    } else {
      // Purana banda update ho raha hai
      await FirebaseFirestore.instance.collection('employees').doc(docId).update(data);
    }
    notifyListeners();
  }

  // --- Status Toggle Logic (No change in old logic) ---
  Future<void> toggleStatus(String docId, bool newValue) async {
    _localStatus[docId] = newValue;
    notifyListeners();

    try {
      await FirebaseFirestore.instance
          .collection('employees')
          .doc(docId)
          .update({'status': newValue ? 'Active' : 'Inactive'});
    } catch (e) {
      _localStatus[docId] = !newValue;
      notifyListeners();
    }
  }
}