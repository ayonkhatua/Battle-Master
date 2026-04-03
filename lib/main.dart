import 'package:battle_master/screens/maintenance_screen.dart';
import 'package:battle_master/screens/auth_check_screen.dart'; 
import 'package:battle_master/screens/update_screen.dart';
import 'package:battle_master/screens/splash_screen.dart'; // 🌟 NAYA: Splash Screen Import
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:battle_master/services/user_status_service.dart';
import 'package:battle_master/services/notification_service.dart'; // 🌟 Zaroori: Local Notification Service

// 🌟 FIREBASE IMPORTS 🌟
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Global navigator key to access the navigator from anywhere
final navigatorKey = GlobalKey<NavigatorState>();

// Background Message Handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
  // Firebase usually handles background messages automatically if payload contains 'notification' block.
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file
  await dotenv.load(fileName: ".env");

  // Initialize Supabase first, so NotificationService can use it if needed
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // 🌟 FIREBASE & NOTIFICATIONS INITIALIZE 🌟
  try {
    await Firebase.initializeApp();
    debugPrint("✅ Firebase Initialized Successfully");

    // Init local notifications
    NotificationService.initialize();

    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('User granted permission: ${settings.authorizationStatus}');

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 🌟 FIX: Foreground Message Handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground Message Received: ${message.notification?.title}');
      
      // Agar notification payload aaya hai, toh usey local popup ki tarah show karo
      if (message.notification != null) {
        NotificationService.showLocalNotification(
          title: message.notification!.title ?? "New Notification",
          body: message.notification!.body ?? "",
        );
      }
    });

  } catch (e) {
    debugPrint("❌ Firebase Initialization Error: $e");
  }


  // 🌟 FIX 1: Prevent Multiple Listeners 🌟
  bool isUserStatusListening = false;

  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    final AuthChangeEvent event = data.event;
    if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.initialSession) {
      if (!isUserStatusListening) {
        isUserStatusListening = true;
        UserStatusService.startListening(navigatorKey);
      }
    } else if (event == AuthChangeEvent.signedOut) {
      isUserStatusListening = false; // Logout hone par reset kar do
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

  // 🌟 MAGIC SETUP: Determine Target Screen based on priority
  Widget targetScreen = const AuthCheckScreen();
  if (isUpdateAvailable) {
    targetScreen = UpdateScreen(appLink: appLink);
  } else if (isMaintenanceOn) {
    targetScreen = const MaintenanceScreen();
  }

  bool wasMaintenanceOrUpdate = isMaintenanceOn || isUpdateAvailable;

  // Realtime Database Listener for App Config
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
            wasMaintenanceOrUpdate = true;
            navigatorKey.currentState?.pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => UpdateScreen(appLink: link)),
              (route) => false,
            );
          } 
          // Priority 2: Maintenance Mode
          else if (newMaintenanceStatus) {
            wasMaintenanceOrUpdate = true;
            navigatorKey.currentState?.pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const MaintenanceScreen()),
              (route) => false,
            );
          } 
          // Priority 3: Normal Status (All clear)
          else {
            if (wasMaintenanceOrUpdate) {
              wasMaintenanceOrUpdate = false;
              navigatorKey.currentState?.pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const AuthCheckScreen()),
                (route) => false,
              );
            }
          }
        },
      )
      .subscribe();

  // 🌟 NAYA: Run App with Splash Screen as initial, passing the target
  runApp(MyApp(initialScreen: SplashScreen(nextScreen: targetScreen)));
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
      home: initialScreen, // Ab ye hamesha SplashScreen kholega pehle
      debugShowCheckedModeBanner: false,
    );
  }
}