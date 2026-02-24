import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Dashboard/admin_dashboard.dart';
import 'forget_password.dart';
import 'dart:ui';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  // --- GOLDEN PALETTE (Corrected Variables) ---
  final Color kGoldLight = const Color(0xFFF3E5AB);
  final Color kGoldPrimary = const Color(0xFFD4AF37);
  final Color kGoldDark = const Color(0xFFC69C34);
  final Color kGoldDarker = const Color(0xFF8a6e1e);
  final Color kCharcoal = const Color(0xFF2C2C2C);

  void _handleLogin() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      _showError("Empty Fields", "Enter both email and password.");
      return;
    }
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) {
        Navigator.pushReplacement(context, CupertinoPageRoute(builder: (context) => const AdminDashboard()));
      }
    } catch (e) {
      _showError("Login Error", "Invalid credentials. Please try again.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String title, String msg) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(msg),
        actions: [CupertinoDialogAction(child: const Text("OK"), onPressed: () => Navigator.pop(context))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Warm Golden/Creamy Background
      backgroundColor: const Color(0xFFFFFDE7),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFF8E1), // Very light amber
                  Color(0xFFFFECB3), // Light gold
                  Color(0xFFF0F4C3), // Light lime/gold mix
                ],
              ),
            ),
          ),
          // Golden Orbs
          Positioned(
            top: -50,
            right: -50,
            child: _buildOrb(200, kGoldPrimary.withOpacity(0.1)),
          ),
          Positioned(
            bottom: -100,
            left: -50,
            child: _buildOrb(250, kGoldDark.withOpacity(0.05)),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(35),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(35),
                        border: Border.all(color: kGoldPrimary.withOpacity(0.3), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: kGoldDark.withOpacity(0.15),
                            blurRadius: 20,
                            spreadRadius: 5,
                          )
                        ]
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: kGoldLight.withOpacity(0.3),
                            shape: BoxShape.circle,
                            border: Border.all(color: kGoldPrimary.withOpacity(0.2)),
                          ),
                          // Icon color changed to Gold
                          child: Icon(CupertinoIcons.lock_shield_fill, color: kGoldDark, size: 40),
                        ),
                        const SizedBox(height: 25),
                        Text(
                          "Admin Portal",
                          style: TextStyle(color: kCharcoal, fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Authentication Required",
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 40),

                        // Input Fields with Gold Accents
                        _buildGlassField(
                          controller: _emailController,
                          hint: "Email Address",
                          icon: CupertinoIcons.mail_solid,
                        ),
                        const SizedBox(height: 18),
                        _buildGlassField(
                          controller: _passwordController,
                          hint: "Password",
                          icon: CupertinoIcons.padlock_solid,
                          isPassword: true,
                          obscureText: !_isPasswordVisible,
                          toggle: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                        ),

                        // Forgot Password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                CupertinoPageRoute(builder: (context) => const ForgotPasswordScreen()),
                              );
                            },
                            child: Text(
                              "Forgot Password?",
                              style: TextStyle(
                                color: kGoldDark,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // GOLDEN GRADIENT BUTTON
                        GestureDetector(
                          onTap: _isLoading ? null : _handleLogin,
                          child: Container(
                            height: 60,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFEBC972), Color(0xFFC69C34)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(color: kGoldDark.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
                              ],
                            ),
                            child: _isLoading
                                ? const CupertinoActivityIndicator(color: Colors.white)
                                : const Text(
                              "AUTHORIZE ACCESS",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  Widget _buildGlassField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? toggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kGoldPrimary.withOpacity(0.2)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: TextStyle(color: kCharcoal, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: kGoldDark, size: 20),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(obscureText ? CupertinoIcons.eye_slash : CupertinoIcons.eye, color: kGoldDark.withOpacity(0.7), size: 18),
            onPressed: toggle,
          )
              : null,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 20),
        ),
      ),
    );
  }
}