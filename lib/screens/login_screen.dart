import 'package:battle_master/screens/home_screen.dart';
import 'package:battle_master/screens/register_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 🌟 NAYA IMPORT

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> { 
  final _emailController = TextEditingController(); 
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Please fill all fields"), backgroundColor: Colors.orange));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 🌟 SECURITY CHECK: Check if user is temporarily blocked 🌟
      final prefs = await SharedPreferences.getInstance();
      final lockKey = 'lockout_$email';
      final attemptsKey = 'attempts_$email';

      final lockoutTime = prefs.getInt(lockKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      if (lockoutTime > now) {
        // User is currently blocked
        final remainingMillis = lockoutTime - now;
        final remainingHours = (remainingMillis / (1000 * 60 * 60)).ceil();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("⛔ Account temporarily blocked due to multiple failed attempts. Try again in $remainingHours hours."),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ));
          setState(() => _isLoading = false);
        }
        return; // Login process yahin rok do
      } else if (lockoutTime > 0) {
        // Block time khatam ho gaya hai, purana data clear karo
        await prefs.remove(lockKey);
        await prefs.remove(attemptsKey);
      }

      // 🌟 ATTEMPT LOGIN 🌟
      final authResponse = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // Agar login successful ho gaya, toh galat attempts ka data clear kar do
      if (authResponse.user != null && mounted) {
        await prefs.remove(attemptsKey);
        await prefs.remove(lockKey);

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Login Successful!"), backgroundColor: Colors.green));
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
      }
      
    } on AuthException catch (e) {
      String errorMessage = "❌ Login failed. Please try again.";
      
      // 🌟 FRIENDLY ERROR HANDLING & BLOCKING LOGIC 🌟
      if (e.message.toLowerCase().contains("invalid login credentials")) {
        final prefs = await SharedPreferences.getInstance();
        final attemptsKey = 'attempts_$email';
        final lockKey = 'lockout_$email';

        int attempts = (prefs.getInt(attemptsKey) ?? 0) + 1;
        await prefs.setInt(attemptsKey, attempts);

        if (attempts >= 5) {
          // 5 baar galat password = 5 ghante (5 * 60 * 60 * 1000 ms) ke liye block
          final lockUntil = DateTime.now().add(const Duration(hours: 5)).millisecondsSinceEpoch;
          await prefs.setInt(lockKey, lockUntil);
          errorMessage = "⛔ 5 Failed attempts! Login blocked for 5 hours for security reasons.";
        } else {
          int left = 5 - attempts;
          errorMessage = "❌ Incorrect Email or Password. $left attempts left.";
        }
      } else if (e.message.toLowerCase().contains("email not confirmed")) {
        errorMessage = "⚠️ Please verify your email first before logging in.";
      } else {
         // Koi aur Supabase error hua to
         errorMessage = "❌ ${e.message}";
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.redAccent,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("❌ An unexpected error occurred!"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a202c),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Welcome Back",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(blurRadius: 10.0, color: const Color(0xFFfacc15).withOpacity(0.5))
                    ]
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Login with your email account", 
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 40),

                _buildInput(_emailController, "Email Address", Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                _buildInput(_passwordController, "Password", Icons.lock_outline, isPassword: true),
                const SizedBox(height: 25),

                _isLoading
                    ? const CircularProgressIndicator(color: Color(0xFFfacc15))
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFfacc15),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _login,
                          child: const Text(
                            "Login",
                            style: TextStyle(color: Color(0xFF1a202c), fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                const SizedBox(height: 20),

                RichText(
                  text: TextSpan(
                    text: "Don't have an account? ",
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                    children: <TextSpan>[
                      TextSpan(
                        text: 'Register here',
                        style: const TextStyle(color: Color(0xFFfacc15), fontWeight: FontWeight.bold),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
                          },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String hint, IconData icon, {bool isPassword = false, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.white70, size: 20),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white54),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFfacc15), width: 2),
          ),
        ),
      ),
    );
  }
}