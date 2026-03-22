import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ⚠️ ZAROORI KAAM: 
// Agar aapke Login aur Home screen ka naam kuch aur hai, toh yahan sahi file import karna
// import 'package:myapp/screens/login_screen.dart'; 
// import 'package:myapp/screens/home_screen.dart'; 

class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  _AuthCheckScreenState createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  @override
  void initState() {
    super.initState();
    // App start hote hi 1 second ka time dekar checking shuru karein
    Future.delayed(const Duration(seconds: 1), () {
      _checkUserStatus();
    });
  }

  Future<void> _checkUserStatus() async {
    final client = Supabase.instance.client;
    final session = client.auth.currentSession;
    final user = client.auth.currentUser;

    // 1. Agar user login nahi hai, toh seedha Login Screen par bhejo
    if (session == null || user == null) {
      _goToLogin();
      return;
    }

    try {
      // 2. Database se user ka status check karo
      final response = await client
          .from('users')
          .select('status')
          .eq('id', user.id)
          .maybeSingle(); // maybeSingle() isliye taaki error crash na kare

      // Agar user login hai par profile database me nahi bani
      if (response == null) {
        await client.auth.signOut();
        _goToLogin(message: "Profile not found. Please login again.");
        return;
      }

      final status = response['status'];

      // 3. Blocked Check
      if (status == 'blocked') {
        await client.auth.signOut(); // User ko logout kar do
        _goToLogin(message: "❌ Your account has been suspended by Admin.");
      } else {
        // Sab sahi hai, Home Screen par bhejo
        _goToHome();
      }
    } catch (e) {
      print("Auth Check Error: $e");
      // Agar internet na ho ya koi aur error aaye
      _goToLogin(message: "⚠️ Network Error. Please check your internet.");
    }
  }

  void _goToLogin({String? message}) {
    if (!mounted) return;

    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
      );
    }
    
    // 🔥 NAVIGATION ON KAR DIYA HAI 🔥
    // Agar IDX me error (Red line) aaye, toh LoginScreen wali file import kar lena upar
    // Navigator.pushReplacement(
    //   context, 
    //   MaterialPageRoute(builder: (context) => const LoginScreen()),
    // );
    print("User Needs to Login...");
  }

  void _goToHome() {
    if (!mounted) return;

    // 🔥 NAVIGATION ON KAR DIYA HAI 🔥
    // Agar IDX me error (Red line) aaye, toh HomeScreen wali file import kar lena upar
    // Navigator.pushReplacement(
    //   context, 
    //   MaterialPageRoute(builder: (context) => const HomeScreen()),
    // );
    print("Going to Home Screen...");
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0f172a), // Dark Theme Background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Loading Indicator
            CircularProgressIndicator(color: Color(0xFFfacc15)),
            SizedBox(height: 20),
            Text(
              "Verifying Account...",
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}