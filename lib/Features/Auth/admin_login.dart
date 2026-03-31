import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Dashboard/admin_dashboard.dart';
import 'forget_password.dart';

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

  // Add FocusNodes
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  // Golden/Amber palette
  static const Color kGold = Color(0xFFFFC107);
  static const Color kGoldDark = Color(0xFFFFA000);
  static const Color kGoldLight = Color(0xFFFFECB3);
  static const Color kTextDark = Color(0xFF212121);

  void _handleLogin() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter email and password")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdminDashboard()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid credentials. Try again.")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF8E1),
              Color(0xFFFFECB3),
              Color(0xFFFFCA28),
              Color(0xFFFFB74D),
            ],
            stops: [0.0, 0.3, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              child: Container(
                padding: const EdgeInsets.fromLTRB(32, 40, 32, 36),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.42),
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(color: Colors.white.withOpacity(0.55), width: 1.8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.10),
                      blurRadius: 30,
                      spreadRadius: 2,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: kGold.withOpacity(0.25),
                        shape: BoxShape.circle,
                        border: Border.all(color: kGold, width: 2.5),
                      ),
                      child: const Icon(
                        Icons.lock_outline,
                        color: kGoldDark,
                        size: 42,
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      "Admin Portal",
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: kTextDark),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Authentication Required",
                      style: TextStyle(fontSize: 15, color: Colors.grey.shade800, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 40),

                    // Email
                    _buildTextField(
                      controller: _emailController,
                      focusNode: _emailFocus,
                      hint: "Email Address",
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 20),

                    // Password
                    _buildTextField(
                      controller: _passwordController,
                      focusNode: _passwordFocus,
                      hint: "Password",
                      icon: Icons.lock_outline,
                      isPassword: true,
                      obscureText: !_isPasswordVisible,
                      toggleVisibility: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                    ),

                    const SizedBox(height: 12),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                          );
                        },
                        child: Text(
                          "Forgot Password?",
                          style: TextStyle(color: kGoldDark, fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kGold,
                          foregroundColor: Colors.black87,
                          elevation: 6,
                          shadowColor: kGoldDark.withOpacity(0.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.black54, strokeWidth: 2.5),
                        )
                            : const Text(
                          "AUTHORIZE ACCESS",
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: 0.8),
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
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    FocusNode? focusNode,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? toggleVisibility,
    TextInputType? keyboardType,
  }) {
    return GestureDetector(  // ← Added GestureDetector to force focus on tap
      onTap: () {
        if (focusNode != null) {
          focusNode.requestFocus();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.75),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white70, width: 1.2),
        ),
        child: TextField(
          focusNode: focusNode,
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: const TextStyle(color: kTextDark, fontSize: 16),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: kGoldDark, size: 24),
            suffixIcon: isPassword
                ? IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: kGoldDark,
              ),
              onPressed: toggleVisibility,
            )
                : null,
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade600),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }
}