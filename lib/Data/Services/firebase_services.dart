import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction_model.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Transaction save karne ka function
  Future<void> addTransaction(SalonTransaction transaction) async {
    try {
      await _db.collection('transactions').add(transaction.toMap());
    } catch (e) {
      print("Error saving transaction: $e");
      rethrow;
    }
  }

  // Aaj ki transactions uthane ka function (Real-time Stream)
  Stream<QuerySnapshot> getTodayTransactions() {
    return _db.collection('transactions')
        .orderBy('date', descending: true)
        .snapshots();
  }
}