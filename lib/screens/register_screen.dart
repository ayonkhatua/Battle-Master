import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import 'dart:ui'; // Glassmorphism ke liye

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _cpasswordController = TextEditingController();
  
  bool _isLoading = false;

  Future<void> _register() async {
    if (_passwordController.text != _cpasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Passwords don't match")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // PHP wale rand(10000, 99999) ka Dart version
      String referCode = "USR${Random().nextInt(90000) + 10000}";

      // Supabase Signup (Ye Email aur Mobile ki duplicate entry khud rok lega)
      final res = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        data: {
          'username': _usernameController.text.trim(),
          'mobile': _mobileController.text.trim(),
          'refer_code': referCode,
        },
      );

      if (res.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ Registration Successful!")));
        // TODO: Yahan se Login Screen par bhej dena
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("⚠️ Registration failed: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1e3c72), Color(0xFF2a5298)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  width: 350,
                  padding: EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      Text("Create Account", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
                      SizedBox(height: 20),
                      _buildInput(_usernameController, "👤 Username"),
                      _buildInput(_mobileController, "📱 Mobile Number"),
                      _buildInput(_emailController, "✉️ Email"),
                      _buildInput(_passwordController, "🔒 Password", isPassword: true),
                      _buildInput(_cpasswordController, "🔒 Confirm Password", isPassword: true),
                      SizedBox(height: 10),
                      _isLoading 
                        ? CircularProgressIndicator(color: Color(0xFFFFD700))
                        : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFFFD700),
                                padding: EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: _register,
                              child: Text("Register", style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String hint, {bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white70),
          filled: true,
          fillColor: Colors.white.withOpacity(0.15),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}