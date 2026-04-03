import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    // 1. Request Permission (User ko popup dikhega "Allow Notifications?")
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ User granted notification permission');
    } else {
      debugPrint('⚠️ User declined notification permission');
      return; // Agar permission nahi di, toh aage mat badho
    }

    // 2. Get the FCM Token
    try {
      String? token = await _fcm.getToken();
      if (token != null) {
        debugPrint("🔥 My FCM Token: $token");
        await _saveTokenToSupabase(token);
      }
    } catch (e) {
      debugPrint("❌ Error getting FCM token: $e");
    }

    // 3. Listen for Token Refresh (Agar token expire hoke naya ban jaye)
    _fcm.onTokenRefresh.listen((newToken) {
      debugPrint("🔄 FCM Token Refreshed: $newToken");
      _saveTokenToSupabase(newToken);
    });

    // 4. Handle Foreground Messages (Jab user app chala raha ho tab notification aaye)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📩 Got a message whilst in the foreground!');
      if (message.notification != null) {
        debugPrint('🔔 Notification Title: ${message.notification?.title}');
        debugPrint('🔔 Notification Body: ${message.notification?.body}');
        // Note: Yahan tum chaho toh in-app Snackbar ya Local Notification show kar sakte ho.
      }
    });
  }

  // 🌟 Helper Function: Token ko Supabase me save karne ke liye 🌟
  static Future<void> _saveTokenToSupabase(String token) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      
      if (userId != null) {
        await Supabase.instance.client
            .from('users')
            .update({'fcm_token': token})
            .eq('id', userId);
        debugPrint("✅ Token saved to Supabase for user: $userId");
      } else {
        debugPrint("⚠️ User not logged in, skipping token save.");
      }
    } catch (e) {
      debugPrint("❌ Error saving token to Supabase: $e");
    }
  }

  static void showLocalNotification({required String title, required String body}) {}
}