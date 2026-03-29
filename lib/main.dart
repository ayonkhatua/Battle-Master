import 'package:battle_master/screens/maintenance_screen.dart';
import 'package:battle_master/screens/auth_check_screen.dart'; 
import 'package:battle_master/screens/update_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:battle_master/services/user_status_service.dart';

// 🌟 FIREBASE IMPORTS 🌟
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // ADDED THIS

// Global navigator key to access the navigator from anywhere
final navigatorKey = GlobalKey<NavigatorState>();

// 🌟 ADDED: Background Message Handler 🌟
// Ye function app band hone par bhi notification receive karne me help karta hai
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file
  await dotenv.load(fileName: ".env");

  // 🌟 FIREBASE INITIALIZE 🌟
  try {
    await Firebase.initializeApp();
    debugPrint("✅ Firebase Initialized Successfully");

    // 🌟 ADDED: FCM Setup & Permissions 🌟
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Android 13+ ke liye notification permission maangna zaroori hai
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('User granted permission: ${settings.authorizationStatus}');

    // Background listener set karna
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Jab app open ho (Foreground) tab notification handle karna
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground Message Received: ${message.notification?.title}');
      // Agar aap chahte ho ki app open hone par bhi upar se banner aaye, 
      // toh yahan flutter_local_notifications plugin ka use karna padega (baad me kar lenge agar zaroorat hui)
    });

  } catch (e) {
    debugPrint("❌ Firebase Initialization Error: $e");
  }

  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // User ka login status monitor karo for instant block logic
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