import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// TODO: Apne Login aur Home screen ko yahan import karna
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
    // App start hote hi checking shuru kardo
    _checkUserStatus();
  }

  Future<void> _checkUserStatus() async {
    // 1. Check if session exists (PHP ka isset($_SESSION['user_id']))
    final session = Supabase.instance.client.auth.currentSession;
    final user = Supabase.instance.client.auth.currentUser;

    if (session == null || user == null) {
      // User login nahi hai
      _goToLogin();
      return;
    }

    try {
      // 2. Fetch status from 'users' table (PHP ka SELECT status query)
      final response = await Supabase.instance.client
          .from('users')
          .select('status')
          .eq('id', user.id)
          .single();

      final status = response['status'];

      // 3. Blocked Check (PHP ka $user['status'] == 'blocked')
      if (status == 'blocked') {
        // Logout karna (PHP ka session_destroy())
        await Supabase.instance.client.auth.signOut();
        _goToLogin(message: "❌ Your account has been suspended by Admin.");
      } else {
        // Sab sahi hai, Home Screen par bhejo
        _goToHome();
      }
    } catch (e) {
      print("Auth Check Error: $e");
      // Agar error aaye (jaise net na ho ya user delete ho gaya ho), toh logout kar do
      await Supabase.instance.client.auth.signOut();
      _goToLogin(message: "⚠️ Session expired. Please login again.");
    }
  }

  void _goToLogin({String? message}) {
    if (mounted) {
      if (message != null) {
        // Error message dikhane ke liye
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
        );
      }
      // TODO: Uncomment this to navigate to Login
      // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
    }
  }

  void _goToHome() {
    if (mounted) {
      // TODO: Uncomment this to navigate to Home
      // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0f172a), // Dark theme
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ek mast sa loading indicator
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