import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  // --- GOLDEN PALETTE ---
  final Color kGoldLight = const Color(0xFFF3E5AB);
  final Color kGoldPrimary = const Color(0xFFD4AF37);
  final Color kGoldDark = const Color(0xFFC69C34);
  final Color kCharcoal = const Color(0xFF2C2C2C);

  Future<void> _sendResetLink() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please enter your email address"),
          backgroundColor: kCharcoal,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );

      if (!mounted) return;

      // Success Dialog
      showDialog(
        context: context,
        barrierDismissible: false, // User lazmi button dawaye
        builder: (dialogContext) => AlertDialog( // 'dialogContext' use kiya hai taake confusion na ho
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          title: const Icon(Icons.mark_email_read, color: Color(0xFFD4AF37), size: 50),
          content: Text(
            "Password reset link has been sent to your email. Please check your inbox and spam folder.",
            textAlign: TextAlign.center,
            style: TextStyle(color: kCharcoal),
          ),
          actions: [
            Center(
              child: TextButton(
                style: TextButton.styleFrom(
                    foregroundColor: kGoldDark,
                    textStyle: const TextStyle(fontWeight: FontWeight.bold)
                ),
                onPressed: () {
                  // FIX: Pehle dialog band hoga
                  Navigator.pop(dialogContext);
                  // Phir Forgot Password screen band ho kar Login par jayegi
                  if (mounted) {
                    Navigator.pop(context);
                  }
                },
                child: const Text("Back to Login"),
              ),
            ),
          ],
        ),
      );
    } on FirebaseAuthException catch (e) {
      String message = "An error occurred";
      if (e.code == 'user-not-found') message = "No user found with this email.";
      // Added invalid email check for safety
      if (e.code == 'invalid-email') message = "The email address is badly formatted.";

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          )
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDE7),
      // Added SingleChildScrollView taake keyboard khulne par UI crash na ho
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height, // Screen ki poori height lene ke liye
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.arrow_back_ios_new, color: kCharcoal),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "Reset Password",
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kCharcoal),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Forgot Your Password?",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kGoldDark),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Enter your registered email address below. We will send you a secure link to reset your password.",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 40),

                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(color: kCharcoal, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: "Email Address",
                      labelStyle: TextStyle(color: kGoldDark),
                      prefixIcon: Icon(Icons.email_outlined, color: kGoldDark),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.8),
                      contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: kGoldPrimary.withValues(alpha: 0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: kGoldPrimary, width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: kGoldPrimary.withValues(alpha: 0.3)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kGoldPrimary,
                        foregroundColor: Colors.white,
                        elevation: 5,
                        shadowColor: kGoldDark,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      onPressed: _isLoading ? null : _sendResetLink,
                      child: _isLoading
                          ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                      )
                          : const Text("Send Reset Link", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}