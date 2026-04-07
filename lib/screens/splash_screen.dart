import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'dart:math'; // Particles ke liye

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
  late Animation<double> _logoScale;
  late Animation<double> _textFade;
  
  // Particles ke liye lists
  final List<Particle> particles = [];
  final random = Random();

  @override
  void initState() {
    super.initState();

    // 🌟 Complex Animation Setup
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000), 
      vsync: this,
    );

    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.7, curve: Curves.bounceOut)),
    );
    
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.5, 1.0, curve: Curves.easeIn)),
    );

    _controller.forward();
    
    // 🌟 Particles Initialize
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (int i = 0; i < 50; i++) {
        particles.add(Particle(
          x: random.nextDouble() * MediaQuery.of(context).size.width,
          y: random.nextDouble() * MediaQuery.of(context).size.height,
          size: random.nextDouble() * 2 + 1,
          speed: random.nextDouble() * 0.5 + 0.1,
        ));
      }
      Timer.periodic(const Duration(milliseconds: 16), (timer) {
        if (!mounted) { timer.cancel(); return; }
        _moveParticles();
      });
    });

    // 🌟 Check Login Status after animation starts
    _checkUserSession();
  }

  void _moveParticles() {
    setState(() {
      final size = MediaQuery.of(context).size;
      for (var p in particles) {
        p.y -= p.speed;
        if (p.y < -10) {
          p.y = size.height + 10;
          p.x = random.nextDouble() * size.width;
        }
      }
    });
  }

  Future<void> _checkUserSession() async {
    // Splash screen ko kam se kam 3.5 second dikhane ke liye delay (Complex Animation ke liye)
    await Future.delayed(const Duration(milliseconds: 3500));

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
      backgroundColor: const Color(0xFF070B14), // 🌟 Even Darker Theme
      body: Stack(
        children: [
          // 🌟 Layer 1: Floating Particles
          ...particles.map((p) => Positioned(
            left: p.x,
            top: p.y,
            child: Container(
              width: p.size,
              height: p.size,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            ),
          )),
          
          // 🌟 Layer 2: Core Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 🌟 Animated Logo with Deep Depth
                ScaleTransition(
                  scale: _logoScale,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Glow Background
                      Container(
                        width: 170,
                        height: 170,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3B82F6).withOpacity(0.4),
                              blurRadius: 70,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                      ),
                      // Metallic Border
                      Container(
                        width: 146,
                        height: 146,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF1E293B),
                          border: Border.all(color: Colors.white24, width: 2),
                        ),
                      ),
                      // 🌟 Logo PNG
                      ClipOval(
                        child: Image.asset(
                          'assets/images/logo.png', // Tumhara exact logo path
                          height: 140,
                          width: 140,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 140, width: 140, color: const Color(0xFF1E293B),
                            child: const Icon(Icons.sports_esports, size: 70, color: Color(0xFF3B82F6)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 50),
                
                // 🌟 Neon Glowing Title (Stacked Text for Neon Effect)
                FadeTransition(
                  opacity: _textFade,
                  child: Stack(
                    children: [
                      // Text Glow layer
                      Text(
                        "BATTLE MASTER",
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4.0,
                          foreground: Paint()
                            ..style = PaintingStyle.stroke
                            ..strokeWidth = 4
                            ..color = const Color(0xFF3B82F6).withOpacity(0.4),
                        ),
                      ),
                      // Main Text Layer
                      const Text(
                        "BATTLE MASTER",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4.0,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 15),
                
                // 🌟 Sleek Tagline
                FadeTransition(
                  opacity: _textFade,
                  child: const Text(
                    "PLAY • COMPETE • EARN",
                    style: TextStyle(
                      color: Color(0xFF94A3B8), // Muted light blue/grey
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 5.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      
      // 🌟 Bottom Fixed HUD Element (Stylized Loader)
      bottomNavigationBar: Container(
        height: 100,
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white10, width: 1)),
        ),
        padding: const EdgeInsets.only(bottom: 20.0),
        child: FadeTransition(
          opacity: _textFade,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                height: 32,
                width: 32,
                child: CircularProgressIndicator(
                  color: Color(0xFF3B82F6),
                  strokeWidth: 4,
                  backgroundColor: Colors.white10, // Dim track for style
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "CONNECTING TO BATTLEFIELD...",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 🌟 Particle Model Class
class Particle {
  double x;
  double y;
  double size;
  double speed;

  Particle({required this.x, required this.y, required this.size, required this.speed});
}