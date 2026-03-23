
import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: const Color(0xFF1f2937),
      ),
      body: const Center(
        child: Text(
          'Notification Center Coming Soon!',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
      backgroundColor: const Color(0xFF111827),
    );
  }
}
