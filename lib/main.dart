import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'Features/Auth/admin_login.dart';
import 'Features/sales_entry/sales_entry.dart';
import 'features/dashboard/admin_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const SalonApp());
}

class SalonApp extends StatelessWidget {
  const SalonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Salon Manager',
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: Colors.purple,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
      ),
      // Home ko hum simple Scaffold mein rakhenge
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: SafeArea(
          child: TabBarView(
            physics: const NeverScrollableScrollPhysics(), // Swipe band kar diya taake login bypass na ho
            children: [
              // 1. Staff Entry Screen
              StaffEntryScreen(),

              // 2. Admin Tab (Security Fix)
              // StreamBuilder nikaal diya hai. Ab ye tab hamesha Login Page dikhayega.
              // Jab user login kar lega, to Login Page khud usay Dashboard par bhej dega.
              const AdminLoginPage(),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
          ),
          child: const TabBar(
            labelColor: Colors.purple,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.purple,
            tabs: [
              Tab(icon: Icon(Icons.add_shopping_cart), text: "Staff Entry"),
              Tab(icon: Icon(Icons.lock_person), text: "Admin Panel"),
            ],
          ),
        ),
      ),
    );
  }
}