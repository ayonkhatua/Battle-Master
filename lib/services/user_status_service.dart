import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:battle_master/screens/blocked_screen.dart'; 
import 'package:battle_master/screens/auth_check_screen.dart';

class UserStatusService {
  static RealtimeChannel? _statusChannel;
  static String? _lastKnownStatus; // 🌟 ADDED: Loop se bachne ka safeguard

  static void startListening(GlobalKey<NavigatorState> navigatorKey) {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;

    if (userId == null) return;

    // 🔥 1. Sabse pehle current status check karo
    client.from('users').select('status').eq('id', userId).maybeSingle().then((response) {
      if (response != null) {
        final currentStatus = response['status'];
        
        // Agar status sach mein blocked hai aur pehle se blocked screen pe nahi hain
        if (currentStatus == 'blocked' && _lastKnownStatus != 'blocked') {
          _lastKnownStatus = 'blocked';
          navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const BlockedScreen()),
            (route) => false,
          );
        } else {
          _lastKnownStatus = currentStatus; // Jo bhi status hai usko yaad rakho
        }
      }
    }).catchError((e) {
      debugPrint("Error checking initial status: $e");
    });

    if (_statusChannel != null) {
      client.removeChannel(_statusChannel!);
    }

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
            
            // 🌟 MAGIC LOGIC: Agar naya status purane jaisa hi hai, toh kuch mat karo (Loop Preventer)
            if (newStatus == _lastKnownStatus) return;
            
            _lastKnownStatus = newStatus; // Update last known status

            if (newStatus == 'blocked') {
              navigatorKey.currentState?.pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const BlockedScreen()),
                (route) => false,
              );
            } else if (newStatus == 'active') {
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