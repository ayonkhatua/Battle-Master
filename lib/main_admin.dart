import 'package:battle_master/admin/screens/admin_login_screen.dart';
import 'package:flutter/material.dart';

// Admin panel ke liye alag entry point.
// Is file ko run karne par sirf Admin Login screen khulegi.
void main() {
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Battle Master - Admin Panel',
      theme: ThemeData(
        primarySwatch: Colors.red,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.red),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[800],
            foregroundColor: Colors.white,
          ),
        ),
      ),
      home: const AdminLoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
