import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:battle_master/screens/results_screen.dart'; 

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
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2)
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
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemCount: _completedTournaments.length,
                  itemBuilder: (context, index) {
                    return _buildCompletedCard(_completedTournaments[index]);
                  },
                ),
    );
  }

  // ==========================================
  // 🚀 BIG IMAGE COMPLETED CARD
  // ==========================================
  Widget _buildCompletedCard(Map<String, dynamic> t) {
    bool isWinner = t['amIWinner'] ?? false;
    
    String timeString = t['end_time'] ?? t['time'] ?? '';
    DateTime localTime = timeString.isNotEmpty ? DateTime.parse(timeString).toLocal() : DateTime.now();
    String formattedDate = DateFormat('dd/MM/yyyy').format(localTime);
    String formattedTimeStr = DateFormat('hh:mm a').format(localTime);

    String type = t['type']?.toString().toUpperCase() ?? 'SOLO';
    String mapName = t['map']?.toString().toUpperCase() ?? 'BERMUDA';
    
    // Default fallback values if not present
    int entryFee = t['entry_fee'] ?? 0;
    int filledSlots = t['filled'] ?? 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context, 
          MaterialPageRoute(builder: (_) => ResultsScreen(tournamentId: t['id']))
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B), // Dark Card Background
          borderRadius: BorderRadius.circular(12),
          border: isWinner ? Border.all(color: Colors.amberAccent, width: 1.5) : Border.all(color: Colors.white.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: isWinner ? Colors.amberAccent.withOpacity(0.1) : Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            // --- 1. TOP IMAGE ---
            ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
              child: t['image_url'] != null && t['image_url'].toString().isNotEmpty
                  ? Image.network(t['image_url'], width: double.infinity, height: 160, fit: BoxFit.cover)
                  : Container(height: 160, color: const Color(0xFF0F172A), child: const Icon(Icons.image, color: Colors.white24, size: 50)),
            ),

            // --- 2. BADGES & TITLE ---
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
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6), // Purple
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(type, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A), // Dark Navy
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.white12)
                            ),
                            child: Text(mapName, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      if (isWinner)
                        const Icon(Icons.emoji_events, color: Colors.amberAccent, size: 24),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.sports_esports, color: Colors.amberAccent, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "${t['title']} - Match #${t['id']}",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const Divider(height: 1, color: Colors.white10),

            // --- 3. MIDDLE STATS (3 Columns) ---
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
                          Text(formattedDate, style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 13, fontWeight: FontWeight.w900)),
                          Text(formattedTimeStr, style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const VerticalDivider(width: 1, color: Colors.white10),
                  
                  // Prize Pool
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        children: [
                          const Text("PRIZE POOL", style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("${t['prize_pool'] ?? 0}(₹)", style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const VerticalDivider(width: 1, color: Colors.white10),
                  
                  // Per Kill
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        children: [
                          const Text("PER KILL", style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("${t['per_kill'] ?? 0}(₹)", style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const Divider(height: 1, color: Colors.white10),

            // --- 4. BOTTOM BUTTONS ---
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // WATCH Button (Purple)
                  Expanded(
                    flex: 1,
                    child: ElevatedButton(
                      onPressed: () {
                         // YouTube link logic here
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening YouTube Link...')));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6), // Purple
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      child: const Text("WATCH", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // 🌟 NAYA: DISABLED ENTRY BUTTON (Matches the image logic)
                  Expanded(
                    flex: 1,
                    child: ElevatedButton(
                      onPressed: null, // Makes it greyed out
                      style: ElevatedButton.styleFrom(
                        disabledBackgroundColor: const Color(0xFF0F172A), // Dark Grey block
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.network('https://img.icons8.com/emoji/48/coin-emoji.png', width: 14, height: 14),
                          const SizedBox(width: 4),
                          Text(
                            "$entryFee  $filledSlots JOINED", 
                            style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)
                          ),
                        ],
                      ),
                    ),
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