import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:battle_master/screens/rules_screen.dart'; // Rules screen import

class TournamentScreen extends StatefulWidget {
  final String mode; // e.g., "Battle Royale", "Clash Squad"

  const TournamentScreen({super.key, required this.mode});

  @override
  _TournamentScreenState createState() => _TournamentScreenState();
}

class _TournamentScreenState extends State<TournamentScreen> {
  bool _isLoading = true;
  
  // 3 alag lists banayenge jaisa PHP mein tha
  List<Map<String, dynamic>> _matches = [];
  List<Map<String, dynamic>> _ongoing = [];
  List<Map<String, dynamic>> _results = [];

  @override
  void initState() {
    super.initState();
    _fetchTournaments();
  }

  Future<void> _fetchTournaments() async {
    try {
      // Supabase query: Fetching tournaments based on mode
      final response = await Supabase.instance.client
          .from('tournaments')
          .select('*') // Nested relation hata diya, error isi se aa raha tha
          .ilike('mode', widget.mode) // ilike case-insensitive search karta hai
          .order('time', ascending: true);

      final now = DateTime.now();
      
      List<Map<String, dynamic>> tempMatches = [];
      List<Map<String, dynamic>> tempOngoing = [];
      List<Map<String, dynamic>> tempResults = [];

      for (var row in response as List<dynamic>) {
        // PHP ka logic: Solo=1, Duo=2, Squad=4
        int slots = row['slots'] ?? 0;
        String type = (row['type'] ?? '').toString().toLowerCase();
        int squadSize = 1;
        if (type == 'duo') squadSize = 2;
        if (type == 'squad') squadSize = 4;

        int totalSlots = slots * squadSize;
        
        // Seedha tournaments table ke 'filled' column ko use kar rahe hain
        int filled = row['filled'] ?? 0;

        double progress = totalSlots > 0 ? (filled / totalSlots) : 0;
        int spotsLeft = totalSlots - filled;
        bool isFull = filled >= totalSlots;

        DateTime matchTime;
        try {
          matchTime = DateTime.parse(row['time'].toString());
        } catch (e) {
          matchTime = DateTime.now(); // Agar time format galat hua toh app crash nahi hoga
        }
        
        // Preparing the formatted map
        Map<String, dynamic> matchData = {
          ...row,
          'totalSlots': totalSlots,
          'filled': filled,
          'progress': progress,
          'spotsLeft': spotsLeft,
          'isFull': isFull,
          'matchTime': matchTime,
        };

        // Classification Logic
        if (row['winner'] != null && row['winner'].toString().isNotEmpty) {
          tempResults.add(matchData);
        } else if (matchTime.isBefore(now)) {
          tempOngoing.add(matchData);
        } else {
          tempMatches.add(matchData);
        }
      }

      setState(() {
        _matches = tempMatches;
        _ongoing = tempOngoing;
        _results = tempResults;
        _isLoading = false;
      });
      
    } catch (e) {
      print("Error fetching tournaments: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // DefaultTabController 3 tabs ko manage karta hai. initialIndex: 1 matlab beech wala 'MATCH' tab default khulega.
    return DefaultTabController(
      length: 3,
      initialIndex: 1, 
      child: Scaffold(
        backgroundColor: const Color(0xFF0f172a),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1e293b),
          title: Text("${widget.mode.toUpperCase()} TOURNAMENTS", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: const TabBar(
            indicatorColor: Color(0xFFfacc15),
            labelColor: Color(0xFFfacc15),
            unselectedLabelColor: Color(0xFF9ca3af),
            tabs: [
              Tab(text: "ONGOING"),
              Tab(text: "MATCH"),
              Tab(text: "RESULT"),
            ],
          ),
        ),
        body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFfacc15)))
          : TabBarView(
              children: [
                _buildList(_ongoing, isResult: false),
                _buildList(_matches, isResult: false),
                _buildList(_results, isResult: true),
              ],
            ),
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> list, {required bool isResult}) {
    if (list.isEmpty) {
      return const Center(
        child: Text("No tournaments found.", style: TextStyle(color: Color(0xFF9ca3af), fontSize: 16)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        return _buildCard(item, isResult);
      },
    );
  }

  Widget _buildCard(Map<String, dynamic> item, bool isResult) {
    String formattedTime = DateFormat('dd/MM/yyyy hh:mm a').format(item['matchTime']);

    return GestureDetector(
      onTap: () {
        // Navigate to Rules screen
        Navigator.push(context, MaterialPageRoute(builder: (_) => RulesScreen(tournamentId: item['id'])));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF1e293b),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 8, offset: const Offset(0, 4))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Placeholder (Agar actual image URL ho toh Image.network use karna)
            Container(
              height: 160,
              width: double.infinity,
              color: Colors.grey[800],
              child: item['image_url'] != null && item['image_url'].toString().isNotEmpty
                  ? Image.network(item['image_url'], fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.image, color: Colors.white54, size: 50))
                  : const Icon(Icons.image, color: Colors.white54, size: 50),
            ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "#${item['id']} - ${item['title']} ${isResult ? '(Result)' : ''}",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFfacc15)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isResult ? "Ended: $formattedTime" : "Time: $formattedTime",
                    style: const TextStyle(fontSize: 12, color: Color(0xFF9ca3af)),
                  ),
                  const SizedBox(height: 15),

                  // Details Grid
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildGridItem(isResult ? "Winner" : "Prize", isResult ? (item['winner'] ?? '-') : "💰 ${item['prize_pool']}"),
                      _buildGridItem(isResult ? "Kills" : "Per Kill", isResult ? (item['winner_kills']?.toString() ?? '-') : "💰 ${item['per_kill']}"),
                      _buildGridItem(isResult ? "Coins" : "Entry", isResult ? "💰 ${item['winner_coins'] ?? '-'}" : "💰 ${item['entry_fee']}"),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // Extra Details Grid
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildGridItem("Type", item['type'] ?? '-'),
                      _buildGridItem("Version", item['version'] ?? '-'),
                      _buildGridItem("Map", item['map'] ?? '-'),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // Slots & Progress Bar (Only show if not a result)
                  if (!isResult) ...[
                    Row(
                      children: [
                        Text("${item['spotsLeft']} Spots Left", style: const TextStyle(fontSize: 12, color: Color(0xFFd1d5db))),
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                            child: LinearProgressIndicator(
                              value: item['progress'],
                              backgroundColor: const Color(0xFF374151),
                              color: const Color(0xFFef4444),
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        Text("${item['filled']}/${item['totalSlots']}", style: const TextStyle(fontSize: 12, color: Color(0xFFd1d5db))),
                      ],
                    ),
                    const SizedBox(height: 15),
                    
                    // Join Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: item['isFull'] ? const Color(0xFF6b7280) : const Color(0xFF2563eb),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        onPressed: item['isFull'] ? null : () {
                          // Join par click karne se seedha RulesScreen par bhejenge
                          Navigator.push(context, MaterialPageRoute(builder: (_) => RulesScreen(tournamentId: item['id'])));
                        },
                        child: Text(
                          item['isFull'] ? "FULL" : "JOIN",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridItem(String title, String value) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 12, color: Colors.white70)),
      ],
    );
  }
}