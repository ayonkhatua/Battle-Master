import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

// 🌟 Dono files import karni padengi kyunki Splash khud decide karega login status
import 'package:battle_master/screens/login_screen.dart';
import 'package:battle_master/screens/home_screen.dart';

class SplashScreen extends StatefulWidget {
  // Ye wo screen hai jo main.dart ne bheji hai (UpdateScreen ya MaintenanceScreen agar zaroorat hui toh)
  // Agar ye null nahi hai, toh seedha wahi jana hai, warna Home/Login check karna hai.
  final Widget? nextScreen; 

  const SplashScreen({super.key, this.nextScreen});

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

    // 🌟 Check Login Status after animation starts
    _checkUserSession();
  }

  Future<void> _checkUserSession() async {
    // Splash screen ko kam se kam 3 second dikhane ke liye delay (Animation dikhne ke liye)
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // 1. Agar koi specific override (Update ya Maintenance) aayi hai main.dart se, toh seedha uspar jao
    if (widget.nextScreen != null && widget.nextScreen.toString() != "AuthCheckScreen") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => widget.nextScreen!),
      );
      return;
    }

    // 2. Agar koi override nahi hai, toh normal Login Status check karo
    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      // 🌟 User pehle se login hai -> Home Screen bhej do
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()), 
      );
    } else {
      // 🌟 User naya hai ya log out hai -> Login Screen bhej do
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
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