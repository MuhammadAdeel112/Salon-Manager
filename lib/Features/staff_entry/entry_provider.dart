import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class EntryProvider extends ChangeNotifier {
  String? _selectedStaff;
  Uint8List? _cachedStaffBytes;
  final List<Map<String, dynamic>> _selectedServicesList = [];

  // Naya: Expense Mode handle karne ke liye variable
  bool _isExpenseMode = false;

  // Performance ke liye image cache
  final Map<String, Uint8List> _imageCache = {};

  // --- Getters ---
  String? get selectedStaff => _selectedStaff;
  Uint8List? get cachedStaffBytes => _cachedStaffBytes;
  List<Map<String, dynamic>> get selectedServicesList => _selectedServicesList;
  bool get isExpenseMode => _isExpenseMode;

  double get totalAmount => _selectedServicesList.fold(0, (sum, item) => sum + item['price']);

  // --- Methods ---

  // Mode badalne ke liye (Service se Expense aur Expense se Service)
  void toggleMode() {
    _isExpenseMode = !_isExpenseMode;
    notifyListeners();
  }

  // Image decoding logic with caching
  Uint8List? getOrDecodeImage(String name, String? base64Str) {
    if (base64Str == null) return null;
    if (!_imageCache.containsKey(name)) {
      _imageCache[name] = base64Decode(base64Str);
    }
    return _imageCache[name];
  }

  // Staff select karne ke liye
  void selectStaff(String name, Uint8List? bytes) {
    _selectedStaff = name;
    _cachedStaffBytes = bytes;
    notifyListeners();
  }

  // Service add karne ke liye
  void addService(Map<String, dynamic> service) {
    _selectedServicesList.add(service);
    notifyListeners();
  }

  // Service remove karne ke liye
  void removeService(int index) {
    _selectedServicesList.removeAt(index);
    notifyListeners();
  }

  // Poora data reset karne ke liye (Save ke baad ya Clear button par)
  void resetEntry() {
    _selectedStaff = null;
    _cachedStaffBytes = null;
    _selectedServicesList.clear();
    _isExpenseMode = false;
    notifyListeners();
  }
}