import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart'; // Naya import
import 'package:salon_manager/Features/Dashboard/admin_provider.dart';
import 'package:salon_manager/Features/Employee/view/employee_detail_provider.dart';
import 'package:salon_manager/Features/sales_entry/entry_provider.dart';
import 'Features/Auth/admin_login.dart';
import 'Features/Dashboard/employee/staff_provider.dart';
import 'Features/sales_entry/staff_entry.dart';
 // Provider file ka sahi path den

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    // Step 1: Poori App ko MultiProvider mein wrap kiya
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EntryProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => EmployeeDetailsProvider()),
        ChangeNotifierProvider(create: (_) => StaffProvider()),
        ChangeNotifierProvider(create: (_) => EntryProvider()),
      ],
      child: const SalonApp(),
    ),
  );
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
            physics: const NeverScrollableScrollPhysics(),
            children: [
              // 1. Staff Entry Screen (Ab ye Provider use kar sakti hai)
              const StaffEntryScreen(),

              // 2. Admin Tab
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