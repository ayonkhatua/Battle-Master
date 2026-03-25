import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:battle_master/screens/blocked_screen.dart'; // Apna path verify kar lena
import 'package:battle_master/screens/auth_check_screen.dart';

class UserStatusService {
  static RealtimeChannel? _statusChannel;

  static void startListening(GlobalKey<NavigatorState> navigatorKey) {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;

    if (userId == null) return;

    // 🔥 1. Sabse pehle current status check karo (agar user re-login karke bypass karne ki koshish kare)
    client.from('users').select('status').eq('id', userId).maybeSingle().then((response) {
      if (response != null && response['status'] == 'blocked') {
        // Seedha BlockedScreen pe bhejo
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const BlockedScreen()),
          (route) => false,
        );
      }
    }).catchError((e) {
      debugPrint("Error checking initial status: $e");
    });

    // Agar pehle se koi channel chal raha hai (jaise re-login hone par), toh use clear karo
    if (_statusChannel != null) {
      client.removeChannel(_statusChannel!);
    }

    // Supabase Realtime se users table me apna status listen karo
    _statusChannel = client
        .channel('public:users:status_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'users',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: userId,
          ),
          callback: (payload) async {
            final newStatus = payload.newRecord['status'];
            
            if (newStatus == 'blocked') {
              // Global Navigator Key ka use karke BlockedScreen par bhej do
              navigatorKey.currentState?.pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const BlockedScreen()),
                (route) => false,
              );
            } else if (newStatus == 'active') {
              // 🔥 Agar admin wapas unblock kar de, toh user ko auto-restart karke wapas app me bhej do
              navigatorKey.currentState?.pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const AuthCheckScreen()),
                (route) => false,
              );
            }
          },
        )
        .subscribe();
  }
}