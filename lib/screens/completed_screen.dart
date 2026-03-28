import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:battle_master/screens/rules_screen.dart'; 

class CompletedScreen extends StatefulWidget {
  const CompletedScreen({super.key});

  @override
  _CompletedScreenState createState() => _CompletedScreenState();
}

class _CompletedScreenState extends State<CompletedScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _completedTournaments = [];

  @override
  void initState() {
    super.initState();
    _fetchCompletedTournaments();
  }

  Future<void> _fetchCompletedTournaments() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30)).toIso8601String();

      final response = await Supabase.instance.client
          .from('tournaments')
          .select('*, game_results!inner(kills, winnings, is_winner)')
          .eq('game_results.user_id', userId)
          .eq('status', 'completed')
          .gte('end_time', thirtyDaysAgo) 
          .order('end_time', ascending: false); 

      // 🌟 MAGIC LOGIC: Map se Grouping to prevent duplicates 🌟
      Map<int, Map<String, dynamic>> uniqueCompleted = {};

      for (var row in response as List<dynamic>) {
        int tId = row['id'];
        
        if (!uniqueCompleted.containsKey(tId)) {
          int totalKills = 0;
          int totalWinnings = 0;
          bool isWinner = false;

          final results = row['game_results'] as List<dynamic>? ?? [];
          for (var r in results) {
            totalKills += (r['kills'] as int?) ?? 0;
            totalWinnings += (r['winnings'] as int?) ?? 0;
            if (r['is_winner'] == true) isWinner = true;
          }

          uniqueCompleted[tId] = {
            ...row as Map<String, dynamic>,
            'myKills': totalKills,
            'myWinnings': totalWinnings,
            'amIWinner': isWinner,
          };
        }
      }

      if (mounted) {
        setState(() {
          _completedTournaments = uniqueCompleted.values.toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching completed tournaments: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f172a), // Dark Theme Background
      appBar: AppBar(
        backgroundColor: const Color(0xFF1e293b),
        title: const Text(
          "🏆 MY COMPLETED MATCHES", 
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFfacc15)))
          : _completedTournaments.isEmpty
              ? const Center(child: Text("No completed matches found.", style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: _completedTournaments.length,
                  itemBuilder: (context, index) {
                    final t = _completedTournaments[index];
                    bool winner = t['amIWinner'] ?? false;
                    
                    String timeString = t['end_time'] ?? t['time'] ?? '';
                    String formattedTime = '';
                    if (timeString.isNotEmpty) {
                      formattedTime = DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.parse(timeString).toLocal());
                    }

                    return GestureDetector(
                      onTap: () {
                        // Future link for Result/Leaderboard Screen
                        Navigator.push(context, MaterialPageRoute(builder: (_) => RulesScreen(tournamentId: t['id'])));
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white, // 🌟 PURE WHITE CARD 🌟
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: winner ? Colors.amber.withOpacity(0.5) : Colors.black12, 
                              blurRadius: 10, 
                              offset: const Offset(0, 4)
                            )
                          ],
                          border: winner ? Border.all(color: Colors.amber, width: 2) : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    "#${t['id']} - ${t['title']}", 
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                                    overflow: TextOverflow.ellipsis,
                                  )
                                ),
                                if (winner) const Icon(Icons.emoji_events, color: Colors.amber, size: 30),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text("Ended: $formattedTime", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                            
                            const SizedBox(height: 15),
                            
                            // Kills & Coins Box
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFf8fafc), 
                                borderRadius: BorderRadius.circular(10), 
                                border: Border.all(color: Colors.black12)
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _completedStat("MY KILLS", "🔫 ${t['myKills']}", Colors.black87),
                                  Container(height: 30, width: 1, color: Colors.grey.shade300),
                                  _completedStat("WINNINGS", "🪙 ${t['myWinnings']}", Colors.green.shade700),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 15),
                            
                            // Extra Details
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _completedStat("Winner", t['winner']?.toString().isNotEmpty == true ? t['winner'] : '-', Colors.black54),
                                _completedStat("Type", t['type']?.toString().toUpperCase() ?? '-', Colors.black54),
                                _completedStat("Map", t['map'] ?? '-', Colors.black54),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _completedStat(String label, String val, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(val, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}