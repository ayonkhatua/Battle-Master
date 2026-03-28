import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:battle_master/screens/results_screen.dart'; // 🌟 YAHAN NAYI FILE IMPORT KI HAI 🌟

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
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFfacc15)))
          : _completedTournaments.isEmpty
              ? const Center(child: Text("No completed matches found.", style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
                  itemCount: _completedTournaments.length,
                  itemBuilder: (context, index) {
                    return _buildCompactCompletedCard(_completedTournaments[index]);
                  },
                ),
    );
  }

  // ==========================================
  // 🚀 COMPACT COMPLETED CARD (Consistent UI)
  // ==========================================
  Widget _buildCompactCompletedCard(Map<String, dynamic> t) {
    bool isWinner = t['amIWinner'] ?? false;
    
    String timeString = t['end_time'] ?? t['time'] ?? '';
    DateTime localTime = timeString.isNotEmpty ? DateTime.parse(timeString).toLocal() : DateTime.now();
    String formattedDate = DateFormat('dd/MM/yyyy').format(localTime);
    String formattedTimeStr = DateFormat('hh:mm a').format(localTime);

    return GestureDetector(
      onTap: () {
        // 🌟 UPDATED: Ab RulesScreen nahi, sidha ResultsScreen khulegi 🌟
        Navigator.push(
          context, 
          MaterialPageRoute(builder: (_) => ResultsScreen(tournamentId: t['id']))
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          color: Colors.white, // White Card for contrast
          borderRadius: BorderRadius.circular(12),
          border: isWinner ? Border.all(color: Colors.amber, width: 1.5) : null,
          boxShadow: [
            BoxShadow(
              color: isWinner ? Colors.amber.withOpacity(0.3) : Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            // --- TOP BADGES & TITLE ---
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          // Team Type Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFfca5a5), // Light Red
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              t['type']?.toString().toUpperCase() ?? 'SOLO',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Map Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6ee7b7), // Light Green
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              t['map']?.toString().toUpperCase() ?? 'BERMUDA',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      // Winner Trophy Icon
                      if (isWinner)
                        const Icon(Icons.emoji_events, color: Colors.amber, size: 24),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Title
                  Row(
                    children: [
                      const Icon(Icons.sports_esports, color: Color(0xFF374151), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "${t['title']} - Match #${t['id']}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1f2937),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const Divider(height: 1, color: Color(0xFFe5e7eb)),

            // --- MIDDLE STATS ---
            IntrinsicHeight(
              child: Row(
                children: [
                  // Date & Time
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        children: [
                          Text(formattedDate, style: const TextStyle(color: Color(0xFF4b5563), fontSize: 13, fontWeight: FontWeight.w600)),
                          Text(formattedTimeStr, style: const TextStyle(color: Color(0xFF9ca3af), fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                  const VerticalDivider(width: 1, color: Color(0xFFe5e7eb)),
                  
                  // My Result (Kills & Winnings)
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        children: [
                          const Text("MY RESULT", style: TextStyle(color: Color(0xFF4b5563), fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("🔫 ${t['myKills']}", style: const TextStyle(color: Color(0xFF1f2937), fontSize: 13, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 12),
                              Text("🪙 ${t['myWinnings']}", style: const TextStyle(color: Color(0xFF10b981), fontSize: 14, fontWeight: FontWeight.bold)), // Green color for money
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const VerticalDivider(width: 1, color: Color(0xFFe5e7eb)),
                  
                  // Match Winner Name
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                      child: Column(
                        children: [
                          const Text("WINNER", style: TextStyle(color: Color(0xFFf59e0b), fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            t['winner']?.toString().isNotEmpty == true ? t['winner'] : '-', 
                            style: const TextStyle(color: Color(0xFF1f2937), fontSize: 12, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const Divider(height: 1, color: Color(0xFFe5e7eb)),

            // --- BOTTOM COMPLETED STATUS BAR ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFf8fafc), // Very light gray bg for bottom bar
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "● MATCH COMPLETED", 
                    style: TextStyle(color: Color(0xFF10b981), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5) // Green text
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1e293b),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text("VIEW RESULTS ❯", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}