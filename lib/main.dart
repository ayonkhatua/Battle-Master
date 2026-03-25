import 'package:battle_master/screens/maintenance_screen.dart';
// 🔥 Yahan LoginScreen hata kar AuthCheckScreen import kiya hai
import 'package:battle_master/screens/auth_check_screen.dart'; 
import 'package:battle_master/screens/update_screen.dart';
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

  // Fetch the initial app config state before running the app
  bool isMaintenanceOn = false;
  bool isUpdateAvailable = false;
  String appLink = '';

  try {
    final response = await Supabase.instance.client
        .from('app_config')
        .select()
        .eq('id', 1)
        .maybeSingle();
        
    if (response != null) {
      isMaintenanceOn = response['is_maintenance_on'] ?? false;
      isUpdateAvailable = response['is_update_available'] ?? false;
      appLink = response['app_link'] ?? '';
    }
  } catch (e) {
    debugPrint("Error fetching app config: $e");
  }

  // Determine Initial Screen based on priority
  Widget initialScreen = const AuthCheckScreen();
  if (isUpdateAvailable) {
    initialScreen = UpdateScreen(appLink: appLink);
  } else if (isMaintenanceOn) {
    initialScreen = const MaintenanceScreen();
  }

  // Realtime Database Listener
  Supabase.instance.client
      .channel('public:app_config')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'app_config',
        callback: (payload) {
          final config = payload.newRecord;
          if (config.isEmpty) return;

          final newMaintenanceStatus = config['is_maintenance_on'] ?? false;
          final newUpdateStatus = config['is_update_available'] ?? false;
          final link = config['app_link'] ?? '';

          // Priority 1: Force Update
          if (newUpdateStatus) {
            navigatorKey.currentState?.pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => UpdateScreen(appLink: link)),
              (route) => false,
            );
          } 
          // Priority 2: Maintenance Mode
          else if (newMaintenanceStatus) {
            navigatorKey.currentState?.pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const MaintenanceScreen()),
              (route) => false,
            );
          } 
          // Priority 3: Normal Status (All clear)
          else {
            navigatorKey.currentState?.pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const AuthCheckScreen()),
              (route) => false,
            );
          }
        },
      )
      .subscribe();

  runApp(MyApp(initialScreen: initialScreen));
}

class MyApp extends StatelessWidget {
  final Widget initialScreen;
  const MyApp({super.key, required this.initialScreen});

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
      home: initialScreen,
      debugShowCheckedModeBanner: false,
    );
  }
}