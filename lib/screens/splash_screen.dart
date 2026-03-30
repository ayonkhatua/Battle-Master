import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

// 🌟 Apne actual files ke import yahan daal lena
//  import 'package:battle_master/screens/login_screen.dart';
//  import 'package:battle_master/screens/home_screen.dart'; // Ya jo bhi aapke main dashboard ka naam ho

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required Widget nextScreen});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // 🌟 Setup Smooth Zoom & Fade Animation
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500), // 1.5 seconds ki animation
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutExpo);
    _controller.forward();

    // 🌟 Check Login Status
    _checkUserSession();
  }

  Future<void> _checkUserSession() async {
    // Splash screen ko kam se kam 3 second dikhane ke liye delay
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      // User is logged in -> Go to Main App / Dashboard
      /* Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()), 
      );
      */
      debugPrint("User logged in. Going to Home...");
    } else {
      // User is NOT logged in -> Go to Login Screen
      /*
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
      */
      debugPrint("User not logged in. Going to Login...");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1120), // 🌟 Deep Dark Esports Theme
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 🌟 Animated Glowing Logo
            ScaleTransition(
              scale: _animation,
              child: Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1E293B),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withOpacity(0.6), // Blue Glow
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                // Agar aapke paas apna Logo Image hai, toh Icon ki jagah Image.asset('assets/logo.png') laga lena
                child: const Icon(Icons.sports_esports_rounded, size: 80, color: Color(0xFF3B82F6)),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // 🌟 Animated App Title
            FadeTransition(
              opacity: _animation,
              child: const Text(
                "BATTLE MASTER",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.5,
                ),
              ),
            ),
            
            const SizedBox(height: 10),
            
            // 🌟 Tagline
            FadeTransition(
              opacity: _animation,
              child: const Text(
                "PLAY • COMPETE • EARN",
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4.0,
                ),
              ),
            ),
          ],
        ),
      ),
      
      // 🌟 Bottom Loading Indicator
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 40.0),
        child: FadeTransition(
          opacity: _animation,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(color: Colors.blueAccent, strokeWidth: 2.5),
              ),
              SizedBox(width: 12),
              Text("Loading your battlefield...", style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}