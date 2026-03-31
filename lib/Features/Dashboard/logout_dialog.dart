// logout_dialog.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../main.dart';
import 'admin_provider.dart';

class LogoutDialog {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Logout", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to exit the Admin Portal?"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("No", style: TextStyle(fontSize: 16)),
          ),
          TextButton(
            onPressed: () async {
              // Close dialog
              Navigator.pop(dialogContext);

              // Small delay
              await Future.delayed(const Duration(milliseconds: 200));

              // Clean Provider listeners
              if (context.mounted) {
                try {
                  final adminProv = Provider.of<AdminProvider>(context, listen: false);
                  adminProv.disposeListeners();
                } catch (e) {
                  debugPrint("Provider cleanup error: $e");
                }
              }

              // Sign out
              try {
                await FirebaseAuth.instance.signOut();
              } catch (e) {
                debugPrint("SignOut Error: $e");
              }

              // Safe navigation
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const SalonApp()),
                      (route) => false,
                );
              }
            },
            child: const Text(
              "Yes",
              style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}