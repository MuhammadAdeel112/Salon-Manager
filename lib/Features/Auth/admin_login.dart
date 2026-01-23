import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Dashboard/admin_dashboard.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false; // Password toggle ke liye

  @override
  void initState() {
    super.initState();
    _forceSignOut();
  }

  void _forceSignOut() async {
    await FirebaseAuth.instance.signOut();
  }

  void _handleLogin() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      _showError("Email and Password are required");
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (userCredential.user != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdminDashboard()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Login failed: ${e.message}";
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        errorMessage = "Incorrect email or password.";
      } else if (e.code == 'network-request-failed') {
        errorMessage = "No internet connection.";
      }
      _showError(errorMessage);
    } catch (e) {
      _showError("An unexpected error occurred.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        )
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD), // Light modern background
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black)
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // --- Header Section ---
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.admin_panel_settings_rounded, size: 60, color: Colors.indigo),
              ),
              const SizedBox(height: 24),
              const Text(
                "Welcome Back",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              const Text(
                "Enter your credentials to access admin panel",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 40),

              // --- Email Field ---
              _buildTextField(
                controller: _emailController,
                label: "Email Address",
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 18),

              // --- Password Field ---
              _buildTextField(
                controller: _passwordController,
                label: "Password",
                icon: Icons.lock_outline,
                isPassword: true,
                obscureText: !_isPasswordVisible,
                togglePassword: () {
                  setState(() => _isPasswordVisible = !_isPasswordVisible);
                },
              ),
              const SizedBox(height: 35),

              // --- Login Button ---
              _isLoading
                  ? const CircularProgressIndicator(color: Colors.indigo)
                  : SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shadowColor: Colors.indigo.withOpacity(0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _handleLogin,
                  child: const Text(
                    "LOG IN",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              const Text(
                "Authorized Access Only",
                style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Widget for Fields ---
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? togglePassword,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
          prefixIcon: Icon(icon, color: Colors.indigo, size: 22),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility, color: Colors.grey, size: 20),
            onPressed: togglePassword,
          )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }
}