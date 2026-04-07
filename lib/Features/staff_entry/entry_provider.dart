import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class EntryProvider extends ChangeNotifier {
  String? _selectedStaff;
  Uint8List? _cachedStaffBytes;
  final List<Map<String, dynamic>> _selectedServicesList = [];

  // Expense Mode
  bool _isExpenseMode = false;

  // Package Mode
  bool _isPackageEntry = false;
  String? _selectedPackageName;
  String? _selectedPackageId;

  // Performance ke liye image cache
  final Map<String, Uint8List> _imageCache = {};

  // --- Getters ---
  String? get selectedStaff => _selectedStaff;
  Uint8List? get cachedStaffBytes => _cachedStaffBytes;
  List<Map<String, dynamic>> get selectedServicesList => _selectedServicesList;
  bool get isExpenseMode => _isExpenseMode;
  bool get isPackageEntry => _isPackageEntry;
  String? get selectedPackageName => _selectedPackageName;
  String? get selectedPackageId => _selectedPackageId;

  // Total amount calculate karta hai (Services aur Packages dono ke liye)
  double get totalAmount =>
      _selectedServicesList.fold(0, (sum, item) => sum + (item['price'] ?? 0.0));

  // --- Methods ---

  // Expense/Service mode toggle
  void toggleMode() {
    _isExpenseMode = !_isExpenseMode;
    notifyListeners();
  }

  // Image decoding with caching
  Uint8List? getOrDecodeImage(String name, String? base64Str) {
    if (base64Str == null) return null;
    if (!_imageCache.containsKey(name)) {
      _imageCache[name] = base64Decode(base64Str);
    }
    return _imageCache[name];
  }

  // Staff select karna
  void selectStaff(String name, Uint8List? bytes) {
    _selectedStaff = name;
    _cachedStaffBytes = bytes;
    notifyListeners();
  }

  // Normal Service add karna
  void addService(Map<String, dynamic> service) {
    _selectedServicesList.add(service);
    notifyListeners();
  }

  // Service remove karna
  void removeService(int index) {
    _selectedServicesList.removeAt(index);
    notifyListeners();
  }

  // Package select karna — LOGIC UPDATED
  void selectPackage({
    required String packageId,
    required String packageName,
    required List<Map<String, dynamic>> services,
    required double discountedPrice,
  }) {
    _isPackageEntry = true;
    _selectedPackageId = packageId;
    _selectedPackageName = packageName;

    _selectedServicesList.clear();

    // Naya Logic: Kyunki individual original prices ka pata nahi,
    // Toh total discounted price ko equally divide kar dete hain
    // taake UI chips mein har service ki kam price show ho sake.
    if (services.isNotEmpty) {
      double perServicePrice = discountedPrice / services.length;

      for (var service in services) {
        _selectedServicesList.add({
          'name': service['name'] ?? '',
          'price': perServicePrice, // Yahan divided (kam) price jaegi
          'isPackageService': true,
        });
      }
    }

    notifyListeners();
  }

  // Package clear karna (agar user manually services mode par aaye)
  void clearPackage() {
    _isPackageEntry = false;
    _selectedPackageId = null;
    _selectedPackageName = null;
    _selectedServicesList.clear();
    notifyListeners();
  }

  // Full reset
  void resetEntry() {
    _selectedStaff = null;
    _cachedStaffBytes = null;
    _selectedServicesList.clear();
    _isExpenseMode = false;
    _isPackageEntry = false;
    _selectedPackageName = null;
    _selectedPackageId = null;
    notifyListeners();
  }
}