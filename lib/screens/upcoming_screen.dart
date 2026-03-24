import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:battle_master/screens/rules_screen.dart'; // Apna rules screen ka path check kar lena

class UpcomingScreen extends StatefulWidget {
  const UpcomingScreen({super.key});

  @override
  _UpcomingScreenState createState() => _UpcomingScreenState();
}

class _UpcomingScreenState extends State<UpcomingScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _tournaments = [];

  @override
  void initState() {
    super.initState();
    _fetchUpcomingTournaments();
  }

  Future<void> _fetchUpcomingTournaments() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      // 1. Pehle pata karo user ne kin tournaments mein hissa liya hai
      final myJoins = await Supabase.instance.client
          .from('user_tournaments')
          .select('tournament_id')
          .eq('user_id', user.id);

      // Duplicate IDs ko hatane ke liye Set ka use kiya hai
      List<int> joinedTids = myJoins.map<int>((e) => e['tournament_id'] as int).toSet().toList();

      if (joinedTids.isEmpty) {
        setState(() => _isLoading = false);
        return; // Agar koi tournament join nahi kiya toh aage query mat chalao
      }

      // 2. Ab un tournaments ka data fetch karo jinka time abhi aage ka hai (Upcoming)
      final now = DateTime.now().toIso8601String();
      
      final response = await Supabase.instance.client
          .from('tournaments')
          .select('*') // Yahan se bhi nested count hata diya gaya hai
          .inFilter('id', joinedTids) // Sirf joined tournaments
          .gt('time', now) // Sirf future wale (Upcoming)
          .order('time', ascending: true);

      // Data formatting for slots and progress (PHP ka logic)
      List<Map<String, dynamic>> formattedList = [];
      for (var row in response as List<dynamic>) {
        int slots = row['slots'] ?? 0;
        String type = (row['type'] ?? '').toString().toLowerCase();
        
        int squadSize = 1;
        if (type == 'duo') squadSize = 2;
        if (type == 'squad') squadSize = 4;

        int totalSlots = slots * squadSize;
        
        // Seedha tournaments table ke 'filled' column ko use karenge
        int filled = row['filled'] ?? 0;

        double progress = totalSlots > 0 ? (filled / totalSlots) : 0;
        int spotsLeft = totalSlots - filled;

        formattedList.add({
          ...row,
          'totalSlots': totalSlots,
          'filled': filled,
          'progress': progress,
          'spotsLeft': spotsLeft,
        });
      }

      setState(() {
        _tournaments = formattedList;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching upcoming tournaments: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f172a), // Dark theme background
      appBar: AppBar(
        backgroundColor: const Color(0xFF1e293b),
        title: const Text(
          "My Upcoming Tournaments",
          style: TextStyle(color: Color(0xFFf8fafc), fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0ea5e9)))
          : _tournaments.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "You haven’t joined any upcoming tournaments yet.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF94a3b8), fontSize: 16),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _tournaments.length,
                  itemBuilder: (context, index) {
                    final t = _tournaments[index];
                    
                    String formattedTime = '';
                    if (t['time'] != null) {
                      formattedTime = DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.parse(t['time']));
                    }

                    return GestureDetector(
                      onTap: () {
                        // User match par click karega toh usko Rules/Room ID screen par bhejenge
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => RulesScreen(tournamentId: t['id'])),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white, // White Card
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "#${t['id']} - ${t['title']}",
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              "Starts: $formattedTime",
                              style: const TextStyle(fontSize: 14, color: Color(0xFF6b7280)),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Details Grid
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildGridItem("Prize", "💰 ${t['prize_pool']}"),
                                _buildGridItem("Per Kill", "💰 ${t['per_kill']}"),
                                _buildGridItem("Entry", "💰 ${t['entry_fee']}"),
                              ],
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Extra Details Grid
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildGridItem("Type", t['type'] ?? '-'),
                                _buildGridItem("Version", t['version'] ?? '-'),
                                _buildGridItem("Map", t['map'] ?? '-'),
                              ],
                            ),

                            const SizedBox(height: 18),

                            // Slots & Progress Bar (Cyan Gradient)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "${t['spotsLeft']} Spots Left",
                                  style: const TextStyle(fontSize: 14, color: Color(0xFF111827), fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  "${t['filled']}/${t['totalSlots']}",
                                  style: const TextStyle(fontSize: 14, color: Color(0xFF111827), fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 10,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFFe5e7eb),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: t['progress'] > 1.0 ? 1.0 : t['progress'], // Safety check
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF06b6d4), Color(0xFF0ea5e9)],
                                    ),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildGridItem(String title, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 13, color: Color(0xFF9ca3af), fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 15, color: Color(0xFF374151), fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}