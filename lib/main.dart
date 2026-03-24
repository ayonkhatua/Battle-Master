import 'package:battle_master/screens/maintenance_screen.dart';
// 🔥 Yahan LoginScreen hata kar AuthCheckScreen import kiya hai
import 'package:battle_master/screens/auth_check_screen.dart'; 
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:battle_master/services/user_status_service.dart';

// Global navigator key to access the navigator from anywhere
final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file
  await dotenv.load(fileName: ".env");

  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // 🔥 User ka login status monitor karo for instant block logic
  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    final AuthChangeEvent event = data.event;
    if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.initialSession) {
      // Jaise hi user login ho ya app start ho aur user logged in ho, block listener start kar do
      UserStatusService.startListening(navigatorKey);
    }
  });

  // Fetch the initial maintenance state before running the app
  bool isMaintenanceOn = false;
  try {
    final response = await Supabase.instance.client
        .from('app_config')
        .select('is_maintenance_on')
        .eq('id', 1)
        .single();
    isMaintenanceOn = response['is_maintenance_on'] ?? false;
  } catch (e) {
    debugPrint("Error fetching maintenance status: $e");
    isMaintenanceOn = false;
  }

  // A local variable to track the current status and prevent redundant navigations
  bool currentStatus = isMaintenanceOn;

  //
  // FINAL CORRECT IMPLEMENTATION FOR supabase_flutter v2.x
  // This uses the modern, stream-based approach which is the correct way.
  //
  Supabase.instance.client
      .from('app_config')
      .stream(primaryKey: ['id'])
      .eq('id', 1)
      .listen((List<Map<String, dynamic>> data) {
    if (data.isNotEmpty) {
      final newRecord = data.first;
      final newStatus = newRecord['is_maintenance_on'] as bool? ?? false;

      // Only navigate if the status has actually changed
      if (newStatus != currentStatus) {
        currentStatus = newStatus; // Update the local status

        if (newStatus == true) {
          navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const MaintenanceScreen()),
            (route) => false,
          );
        } else {
          // 🔥 YAHAN UPDATE HUA HAI: Ab ye sidha Login par nahi, AuthCheck par jayega
          navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const AuthCheckScreen()),
            (route) => false,
          );
        }
      }
    }
  });

  runApp(MyApp(isMaintenanceOn: isMaintenanceOn));
}

class MyApp extends StatelessWidget {
  final bool isMaintenanceOn;
  const MyApp({super.key, required this.isMaintenanceOn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Battle Master',
      theme: ThemeData(
        primarySwatch: Colors.yellow,
        scaffoldBackgroundColor: const Color(0xFF111827),
        fontFamily: 'Roboto',
      ),
      navigatorKey: navigatorKey, 
      // 🔥 YAHAN BHI UPDATE HUA HAI: Default home ab AuthCheckScreen hai
      home: isMaintenanceOn ? const MaintenanceScreen() : const AuthCheckScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}