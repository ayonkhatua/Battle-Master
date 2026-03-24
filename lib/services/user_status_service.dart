import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:battle_master/screens/blocked_screen.dart'; // Apna path verify kar lena

class UserStatusService {
  static RealtimeChannel? _statusChannel;

  static void startListening(GlobalKey<NavigatorState> navigatorKey) {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;

    if (userId == null) return;

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
              // User block hote hi usko logout karo taaki API calls fail ho jayein
              await client.auth.signOut();

              // Global Navigator Key ka use karke kisi bhi screen se BlockedScreen par bhej do (Pichle saare route clear karke)
              navigatorKey.currentState?.pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const BlockedScreen()),
                (route) => false,
              );
            }
          },
        )
        .subscribe();
  }
}