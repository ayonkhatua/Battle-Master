import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // 🔥 1. dotenv package import kiya

// Yahan humne AuthCheckScreen ko import kiya hai
import 'package:battle_master/screens/auth_check_screen.dart'; 

Future<void> main() async { // 🔥 2. void ko Future<void> kiya
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 3. Supabase initialize karne se pehle .env file ko load karein
  await dotenv.load(fileName: ".env");

  // 🔥 4. Hardcoded keys hata kar .env file se variables fetch kiye
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Battle Master',
      debugShowCheckedModeBanner: false, 
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1e3c72)), 
        useMaterial3: true,
      ),
      // Ab app khulte hi pehle AuthCheck chalega
      home: const AuthCheckScreen(), 
    );
  }
}