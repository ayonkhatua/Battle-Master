
import 'package:flutter/material.dart';

class GameLobbyScreen extends StatelessWidget {
  final String gameTitle;

  const GameLobbyScreen({super.key, required this.gameTitle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(gameTitle),
        backgroundColor: const Color(0xFF1f2937),
      ),
      body: Center(
        child: Text(
          'Lobby for $gameTitle Coming Soon!',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
      backgroundColor: const Color(0xFF111827),
    );
  }
}
