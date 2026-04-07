import 'package:battle_master/screens/login_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';

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
  final _referralCodeController = TextEditingController(); 
  
  bool _isLoading = false;

  Future<void> _register() async {
    if (_passwordController.text != _cpasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("❌ Passwords don't match!")));
      return;
    }
    
    final username = _usernameController.text.trim();
    final mobile = _mobileController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final referralCode = _referralCodeController.text.trim().toUpperCase(); 

    if (username.isEmpty || mobile.isEmpty || email.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Please fill all mandatory fields!")));
        return;
    }

    setState(() => _isLoading = true);
    
    final supabase = Supabase.instance.client;

    try {
      // 🌟 PRE-CHECK 1: Check if Referral Code is Valid 🌟
      String? validReferrerId;
      if (referralCode.isNotEmpty) {
        // 🔥 FIX: Error handling ko improve kiya hai aur strictly eq match kiya hai
        try {
           final referCheck = await supabase
              .from('users')
              .select('id')
              .eq('fcode', referralCode)
              .limit(1)
              .maybeSingle();

          if (referCheck == null) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("❌ Invalid Referral Code! Please check again."), backgroundColor: Colors.red));
            setState(() => _isLoading = false);
            return;
          }
          validReferrerId = referCheck['id'];
        } catch (e) {
          debugPrint("Referral Code Fetch Error: $e");
          // Agar RLS ki wajah se error aata hai (permission denied), toh hum usko handle karenge.
          // Abhi ke liye hum ise fail maanenge.
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("❌ Invalid Referral Code or Server Error."), backgroundColor: Colors.red));
          setState(() => _isLoading = false);
          return;
        }
      }

      // 🌟 PRE-CHECK 2: Duplicate Check (Username, Mobile, Email) 🌟
      try {
        final existingCheck = await supabase
            .from('users')
            .select('username, mobile, email')
            .or('username.eq.$username,mobile.eq.$mobile,email.eq.$email');

        if (existingCheck.isNotEmpty) {
          bool isUsernameTaken = existingCheck.any((u) => u['username'] == username);
          bool isMobileTaken = existingCheck.any((u) => u['mobile'] == mobile);
          bool isEmailTaken = existingCheck.any((u) => u['email'] == email);

          if (isUsernameTaken) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("❌ Username is already taken! Try another."), backgroundColor: Colors.red));
          } else if (isMobileTaken) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("❌ Mobile number is already registered! Please login."), backgroundColor: Colors.red));
          } else if (isEmailTaken) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("❌ Email is already registered! Please login."), backgroundColor: Colors.red));
          }
          
          setState(() => _isLoading = false);
          return; 
        }
      } catch (e) {
         debugPrint("Duplicate Check Error: $e");
         // Agar existing check fail ho jaye, toh use aage badhne denge taaki auth error khud handle kar le.
      }

      // 🌟 REGISTRATION PROCEED 🌟
      final authResponse = await supabase.auth.signUp(
        email: email,
        password: password,
      );
      
      if (authResponse.user != null) {
        final user = authResponse.user!;
        
        String ownReferCode = "USR${Random().nextInt(90000) + 10000}";
        
        // 🌟 DATABASE INSERT 🌟
        await supabase.from('users').insert({
          'id': user.id,
          'username': username,
          'mobile': mobile,
          'email': email,
          'fcode': ownReferCode, 
          'referred_by': referralCode.isNotEmpty ? referralCode : null,
        });

        // Transaction log abhi frontend se nahi karte, kyunki Supabase Trigger (give_welcome_bonus)
        // ye kaam khud handle kar lega! Pichle trigger me maine transactions me entry ka code de diya tha.

        if (mounted) {
          String successMsg = "✅ Registration Successful! Please check your email for verification.";
          if (validReferrerId != null) {
             successMsg = "✅ Registration Successful! Referral code applied. Check email to verify.";
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(successMsg), backgroundColor: Colors.green),
          );
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
        }
      }
    } on AuthException catch (e) {
      if (e.message.contains("User already registered") || e.message.contains("already registered")) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("❌ Email is already registered! Please login."), backgroundColor: Colors.red));
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Auth Error: ${e.message}"), backgroundColor: Colors.red));
      }
    } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("⚠️ An unexpected error occurred: $e"), backgroundColor: Colors.orange));
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
                  "Join the Battle",
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
                  "Create your new account",
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 40),

                _buildInput(_usernameController, "Username", Icons.person_outline),
                _buildInput(_mobileController, "Mobile Number", Icons.phone_android_outlined),
                _buildInput(_emailController, "Email Address", Icons.email_outlined),
                _buildInput(_passwordController, "Password", Icons.lock_outline, isPassword: true),
                _buildInput(_cpasswordController, "Confirm Password", Icons.lock_outline, isPassword: true),
                _buildInput(_referralCodeController, "Referral Code (Optional)", Icons.group_add_outlined),
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
                          onPressed: _register,
                          child: const Text(
                            "Register",
                            style: TextStyle(color: Color(0xFF1a202c), fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                const SizedBox(height: 20),

                RichText(
                  text: TextSpan(
                    text: "Already have an account? ",
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                    children: <TextSpan>[
                      TextSpan(
                        text: 'Login here',
                        style: const TextStyle(color: Color(0xFFfacc15), fontWeight: FontWeight.bold),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
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

  Widget _buildInput(TextEditingController controller, String hint, IconData icon, {bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
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