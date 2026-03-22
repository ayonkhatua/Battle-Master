import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Clipboard (copy text) use karne ke liye
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myapp/screens/participants_screen.dart'; // Apna sahi path dalna

class RulesScreen extends StatefulWidget {
  final int tournamentId;

  const RulesScreen({super.key, required this.tournamentId});

  @override
  _RulesScreenState createState() => _RulesScreenState();
}

class _RulesScreenState extends State<RulesScreen> {
  bool _isLoading = true;
  bool _hasJoined = false;
  String _roomId = '';
  String _roomPass = '';

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      // 1. Check if user has joined the tournament
      final joinedResponse = await Supabase.instance.client
          .from('user_tournaments')
          .select('id')
          .eq('user_id', user.id)
          .eq('tournament_id', widget.tournamentId);

      // 2. Fetch tournament room details
      final tResponse = await Supabase.instance.client
          .from('tournaments')
          .select('room_id, room_password')
          .eq('id', widget.tournamentId)
          .single();

      setState(() {
        _hasJoined = (joinedResponse as List).isNotEmpty;
        _roomId = tResponse['room_id']?.toString() ?? '';
        _roomPass = tResponse['room_password']?.toString() ?? '';
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching rules/room info: $e");
      setState(() => _isLoading = false);
    }
  }

  // Text copy karne ka function
  void _copyToClipboard(String text, String type) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("✅ $type Copied: $text"),
        backgroundColor: const Color(0xFF065f46),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Room Details ka Popup Dialog
  void _showRoomDetails() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1f2937),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text("Room Details", style: TextStyle(color: Color(0xFFfacc15), fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Room ID Row
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFF374151), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("ID: $_roomId", style: const TextStyle(color: Colors.white, fontSize: 16)),
                    GestureDetector(
                      onTap: () => _copyToClipboard(_roomId, "Room ID"),
                      child: const Icon(Icons.copy, color: Color(0xFF22c55e), size: 20),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Room Password Row
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFF374151), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Pass: $_roomPass", style: const TextStyle(color: Colors.white, fontSize: 16)),
                    GestureDetector(
                      onTap: () => _copyToClipboard(_roomPass, "Password"),
                      child: const Icon(Icons.copy, color: Color(0xFF22c55e), size: 20),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CLOSE", style: TextStyle(color: Colors.white70)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool roomSet = _roomId.isNotEmpty && _roomPass.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF111827), // Dark Theme
      appBar: AppBar(
        backgroundColor: const Color(0xFF1f2937),
        title: const Text("Tournament Rules", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFfacc15)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Text("Tournament Rules", style: TextStyle(color: Color(0xFFfacc15), fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),

                  // Rules Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1f2937),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 5)],
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("👉 Yaha tum apne rules likh paoge (customizable).", style: TextStyle(color: Colors.white, fontSize: 15, height: 1.5)),
                        SizedBox(height: 10),
                        Text("👉 Jaise cheating not allowed, late entry not allowed, etc.", style: TextStyle(color: Colors.white, fontSize: 15, height: 1.5)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Load Participants Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFdc2626), // Red color
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ParticipantsScreen(tournamentId: widget.tournamentId),
                          ),
                        );
                      },
                      child: const Text("Load Participants", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Room Details Logic
                  if (_hasJoined) ...[
                    if (roomSet) ...[
                      // Condition 1: Joined & Room is Ready
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563eb), // Blue color
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: _showRoomDetails,
                          child: const Text("Room Details", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ] else ...[
                      // Condition 2: Joined but Room NOT Ready
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6b7280), // Disabled Grey
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: null, // Disabled
                          child: const Text("Room Details", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text("⚠ Room not created yet. Please wait for admin", style: TextStyle(color: Color(0xFFf87171), fontSize: 13)),
                    ]
                  ] else ...[
                    // Condition 3: Not Joined
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6b7280), // Disabled Grey
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: null, // Disabled
                        child: const Text("Room Details", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text("⚠ Please join the tournament first", style: TextStyle(color: Color(0xFFf87171), fontSize: 13)),
                  ],
                ],
              ),
            ),
    );
  }
}