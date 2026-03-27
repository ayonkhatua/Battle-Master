import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:async'; // Auto-refresh ke liye zaroori hai
import 'package:battle_master/screens/rules_screen.dart'; 

class TournamentScreen extends StatefulWidget {
  final String mode;

  const TournamentScreen({super.key, required this.mode});

  @override
  _TournamentScreenState createState() => _TournamentScreenState();
}

class _TournamentScreenState extends State<TournamentScreen> {
  bool _isLoading = true;
  Timer? _refreshTimer; // Auto-refresh timer
  
  List<Map<String, dynamic>> _matches = []; // Match Tab (Upcoming)
  List<Map<String, dynamic>> _ongoing = []; // Ongoing Tab
  List<Map<String, dynamic>> _results = []; // Result Tab (Completed 24h)

  @override
  void initState() {
    super.initState();
    _fetchTournaments();
    
    // ⏳ AUTO REFRESH: Har 1 minute mein list auto-update hogi
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        _fetchTournaments(silentRefresh: true);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel(); // Memory leak rokne ke liye
    super.dispose();
  }

  Future<void> _fetchTournaments({bool silentRefresh = false}) async {
    try {
      if (!silentRefresh) setState(() => _isLoading = true);

      final response = await Supabase.instance.client
          .from('tournaments')
          .select('*')
          .ilike('mode', widget.mode)
          .order('time', ascending: true);

      List<Map<String, dynamic>> tempMatches = [];
      List<Map<String, dynamic>> tempOngoing = [];
      List<Map<String, dynamic>> tempResults = [];

      // 🌍 GLOBAL TIME FIX: Har comparison UTC time ke hisaab se hoga
      final nowUTC = DateTime.now().toUtc();
      final twentyFourHoursAgoUTC = nowUTC.subtract(const Duration(hours: 24));

      for (var row in response as List<dynamic>) {
        int slots = row['slots'] ?? 0;
        String type = (row['type'] ?? '').toString().toLowerCase();
        int squadSize = 1;
        if (type == 'duo') squadSize = 2;
        if (type == 'squad') squadSize = 4;

        int totalSlots = slots * squadSize;
        int filled = row['filled'] ?? 0;
        double progress = totalSlots > 0 ? (filled / totalSlots) : 0;
        if (progress > 1.0) progress = 1.0; 
        
        int spotsLeft = totalSlots - filled;
        bool isFull = filled >= totalSlots;

        // DB se time le kar explicitly UTC mein convert kiya
        DateTime matchTimeUTC = DateTime.tryParse(row['time'].toString())?.toUtc() ?? nowUTC;

        Map<String, dynamic> matchData = {
          ...row,
          'totalSlots': totalSlots,
          'filled': filled,
          'progress': progress,
          'spotsLeft': spotsLeft,
          'isFull': isFull,
          'matchTimeUTC': matchTimeUTC, // Save format
        };

        // 🌟 THE AUTOMATIC TIME-BASED SHIFTING LOGIC 🌟
        
        bool hasResult = row['status'] == 'completed'; 

        if (hasResult) {
          // RESULT TAB: Check if within last 24 hours
          DateTime endTimeUTC = DateTime.tryParse(row['end_time'].toString())?.toUtc() ?? matchTimeUTC;
          if (endTimeUTC.isAfter(twentyFourHoursAgoUTC)) {
            tempResults.add(matchData);
          }
        } else {
          // Agar result nahi aaya hai, toh TIME check karo
          if (matchTimeUTC.isAfter(nowUTC)) {
            // Start time aage ka hai -> MATCH TAB
            tempMatches.add(matchData);
          } else {
            // Start time aa gaya ya cross ho gaya -> ONGOING TAB
            tempOngoing.add(matchData);
          }
        }
      }

      if (mounted) {
        setState(() {
          _matches = tempMatches;
          _ongoing = tempOngoing;
          _results = tempResults.reversed.toList(); // Latest result upar
          _isLoading = false;
        });
      }
      
    } catch (e) {
      print("Error fetching category tournaments: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: 1, 
      child: Scaffold(
        backgroundColor: const Color(0xFF0f172a),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1e293b),
          title: Text("${widget.mode.toUpperCase()} TOURNAMENTS", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
                _buildList(_ongoing, isResult: false, isOngoing: true),
                _buildList(_matches, isResult: false, isOngoing: false),
                _buildList(_results, isResult: true, isOngoing: false),
              ],
            ),
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> list, {required bool isResult, required bool isOngoing}) {
    if (list.isEmpty) {
      return Center(
        child: Text(
          isResult ? "No results in the last 24 hours." : "No tournaments here right now.", 
          style: const TextStyle(color: Color(0xFF9ca3af), fontSize: 16)
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: list.length,
      itemBuilder: (context, index) {
        return _buildCard(list[index], isResult, isOngoing);
      },
    );
  }

  Widget _buildCard(Map<String, dynamic> item, bool isResult, bool isOngoing) {
    // Dikhane ke liye time wapas Local (India time) mein convert kiya
    DateTime localTime = item['matchTimeUTC'].toLocal();
    String formattedTime = DateFormat('dd/MM/yyyy hh:mm a').format(localTime);

    return GestureDetector(
      onTap: () {
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

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildGridItem(isResult ? "Winner" : "Prize", isResult ? (item['winner'] ?? '-') : "💰 ${item['prize_pool']}"),
                      _buildGridItem(isResult ? "Winnings" : "Per Kill", isResult ? "-" : "💰 ${item['per_kill']}"),
                      _buildGridItem(isResult ? "Coins" : "Entry", isResult ? "-" : "💰 ${item['entry_fee']}"),
                    ],
                  ),
                  const SizedBox(height: 15),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildGridItem("Type", item['type'] ?? '-'),
                      _buildGridItem("Version", item['version'] ?? '-'),
                      _buildGridItem("Map", item['map'] ?? '-'),
                    ],
                  ),
                  const SizedBox(height: 15),

                  if (isResult)
                    const SizedBox.shrink() 
                  else if (isOngoing)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(color: const Color(0xFFf59e0b), borderRadius: BorderRadius.circular(6)),
                      child: const Text("MATCH IS LIVE / ONGOING", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    )
                  else ...[
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
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: item['isFull'] ? const Color(0xFF6b7280) : const Color(0xFF2563eb),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        onPressed: item['isFull'] ? null : () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => RulesScreen(tournamentId: item['id'])));
                        },
                        child: Text(
                          item['isFull'] ? "MATCH FULL" : "JOIN NOW",
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