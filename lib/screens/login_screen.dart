import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:ui'; // Glassmorphism ke liye

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  late AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    // Background gradient animation ke liye
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgController.dispose();
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text;

    if (identifier.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("⚠️ Please fill all fields")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      AuthResponse res;
      
      // LOGIC: Check kar rahe hain ki user ne Email dala hai ya Mobile number
      if (identifier.contains('@')) {
        res = await Supabase.instance.client.auth.signInWithPassword(
          email: identifier,
          password: password,
        );
      } else {
        // Agar '@' nahi hai, toh hum maan rahe hain ki wo mobile number hai
        res = await Supabase.instance.client.auth.signInWithPassword(
          phone: identifier,
          password: password,
        );
      }

      if (res.user != null) {
        // Login Success!
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ Login Successful!")));
        // TODO: Navigate to Home Screen
        // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen()));
      }
    } on AuthException catch (e) {
      // Supabase khud "Incorrect password" ya "User not found" ka error dega
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("❌ ${e.message}"),
        backgroundColor: Colors.redAccent,
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Something went wrong!")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Animated Background Gradient
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFe0f7fa), Color(0xFFfff3e0), Color(0xFFf3e5f5), Color(0xFFffe0b2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    transform: GradientRotation(_bgController.value * 2 * 3.14), // Smooth rotation
                  ),
                ),
              );
            },
          ),

          // 2. Glassmorphism Login Card
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    width: 360,
                    padding: EdgeInsets.symmetric(vertical: 50, horizontal: 35),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15)
                      ]
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Gradient Title using ShaderMask
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [Color(0xFFff8a00), Color(0xFFe52e71), Color(0xFF9b5de5)],
                          ).createShader(bounds),
                          child: Text(
                            "Login",
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                        SizedBox(height: 30),

                        // Inputs
                        _buildInput(_identifierController, "Email or Mobile", FontAwesomeIcons.envelope),
                        SizedBox(height: 12),
                        _buildInput(_passwordController, "Password", FontAwesomeIcons.lock, isPassword: true),
                        SizedBox(height: 25),

                        // Gradient Button
                        _isLoading 
                          ? CircularProgressIndicator(color: Color(0xFFe52e71))
                          : Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                gradient: LinearGradient(
                                  colors: [Color(0xFFff8a00), Color(0xFFe52e71), Color(0xFF9b5de5)],
                                ),
                                boxShadow: [
                                  BoxShadow(color: Color(0xFFe52e71).withOpacity(0.4), blurRadius: 20, offset: Offset(0, 5))
                                ]
                              ),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                ),
                                onPressed: _login,
                                child: Text("Login", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                              ),
                            ),
                        
                        SizedBox(height: 20),
                        
                        // Register Link
                        GestureDetector(
                          onTap: () {
                            // TODO: Navigator.push to Register Screen
                          },
                          child: Text(
                            "Don't have an account? Register",
                            style: TextStyle(
                              fontSize: 14, 
                              fontWeight: FontWeight.bold, 
                              color: Color(0xFF9b5de5) // Base color for link
                            ),
                          ),
                        )
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

  // Custom Input Builder (Same as your HTML structure)
  Widget _buildInput(TextEditingController controller, String hint, IconData icon, {bool isPassword = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: TextStyle(color: Colors.black87),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.black54),
          prefixIcon: Icon(icon, color: Color(0xFFff8a00), size: 18),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}