import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:salon_manager/features/dashboard/admin_provider.dart';
import 'package:salon_manager/features/employee/view/employee_detail_provider.dart';
import 'features/auth/admin_login.dart';
import 'features/dashboard/employee/staff_provider.dart';
import 'features/staff_entry/entry_provider.dart';
import 'features/staff_entry/staff_entry.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EntryProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => EmployeeDetailsProvider()),
        ChangeNotifierProvider(create: (_) => StaffProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const SalonApp();
  }
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
        primaryColor: const Color(0xFFD4AF37),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD4AF37),
          primary: const Color(0xFFD4AF37),
        ),
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
        body: TabBarView(
          physics: const NeverScrollableScrollPhysics(),
          children: [
            const StaffEntryScreen(),
            const AdminLoginPage(),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
          ),
          child: const TabBar(
            labelColor: Color(0xFFD4AF37),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFFD4AF37),
            tabs: [
              Tab(icon: Icon(Icons.group_add), text: "Staff Entry"),
              Tab(icon: Icon(Icons.admin_panel_settings), text: "Admin Panel"),
            ],
          ),
        ),
      ),
    );
  }
}