import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:battle_master/screens/rules_screen.dart';

class UpcomingScreen extends StatefulWidget {
  const UpcomingScreen({super.key});

  @override
  _UpcomingScreenState createState() => _UpcomingScreenState();
}

class _UpcomingScreenState extends State<UpcomingScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _tournaments = [];
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchUpcomingTournaments();
    
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        _fetchUpcomingTournaments(silentRefresh: true);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchUpcomingTournaments({bool silentRefresh = false}) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      if (!silentRefresh) setState(() => _isLoading = true);

      final response = await Supabase.instance.client
          .from('tournaments')
          .select('*, user_tournaments!inner(user_id)')
          .eq('user_tournaments.user_id', user.id)
          .neq('status', 'completed') 
          .order('time', ascending: true);

      final nowUTC = DateTime.now().toUtc();
      
      // 🌟 MAP SE DUPLICATE HATANA (Duo/Squad Fix) 🌟
      Map<int, Map<String, dynamic>> uniqueUpcoming = {};

      for (var row in response as List<dynamic>) {
        int tId = row['id'];
        DateTime matchTimeUTC = DateTime.tryParse(row['time'].toString())?.toUtc() ?? nowUTC;
        
        // Sirf aage ka time (Upcoming) dikhao
        if (matchTimeUTC.isAfter(nowUTC)) {
          if (!uniqueUpcoming.containsKey(tId)) {
            int slots = row['slots'] ?? 0;
            String type = (row['type'] ?? '').toString().toLowerCase();
            int squadSize = 1;
            if (type == 'duo') squadSize = 2;
            if (type == 'squad') squadSize = 4;

            int totalSlots = slots * squadSize;
            int filled = row['filled'] ?? 0;
            double progress = totalSlots > 0 ? (filled / totalSlots) : 0;
            if (progress > 1.0) progress = 1.0;

            uniqueUpcoming[tId] = {
              ...row as Map<String, dynamic>,
              'totalSlots': totalSlots,
              'filled': filled,
              'progress': progress,
              'spotsLeft': totalSlots - filled,
              'matchTimeUTC': matchTimeUTC,
            };
          }
        }
      }

      if (mounted) {
        setState(() {
          _tournaments = uniqueUpcoming.values.toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching upcoming tournaments: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🌟 POPUP LOGIC: Prize Pool Arrow dabane par dikhega 🌟
  void _showPrizePoolPopup(BuildContext context, Map<String, dynamic> t) {
    // Abhi ke liye hum static dummy data dikha rahe hain.
    // Jab Admin panel mein "Prize Description" ka column banega, tab hum ise wahan se dynamic kar denge.
    String prizeDesc = t['prize_description'] ?? "1st Team: ${t['prize_pool']} Coins\n2nd Team: 50 Coins\n3rd Team: 20 Coins";

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          titlePadding: EdgeInsets.zero,
          title: Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: const BoxDecoration(
              color: Color(0xFF1e293b), // Dark Header
              borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
            ),
            child: const Text("PRIZE POOL", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${t['title']} - Match #${t['id']}",
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1e293b)),
              ),
              const Divider(height: 20, thickness: 1),
              Text(
                prizeDesc,
                style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.5),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("CLOSE", style: TextStyle(color: Color(0xFF1e293b), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1e293b),
        title: const Text("⏳ MY UPCOMING MATCHES", style: TextStyle(color: Color(0xFFf8fafc), fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0ea5e9)))
          : _tournaments.isEmpty
              ? const Center(child: Text("You haven’t joined any upcoming matches yet.", style: TextStyle(color: Color(0xFF94a3b8), fontSize: 16)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
                  itemCount: _tournaments.length,
                  itemBuilder: (context, index) {
                    final t = _tournaments[index];
                    return _buildCompactUpcomingCard(t);
                  },
                ),
    );
  }

  // ==========================================
  // 🚀 COMPACT UPCOMING CARD (NO IMAGE)
  // ==========================================
  Widget _buildCompactUpcomingCard(Map<String, dynamic> t) {
    DateTime localTime = t['matchTimeUTC'].toLocal();
    String formattedDate = DateFormat('dd/MM/yyyy').format(localTime);
    String formattedTimeStr = DateFormat('hh:mm a').format(localTime);

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RulesScreen(tournamentId: t['id']))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
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
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFfca5a5), borderRadius: BorderRadius.circular(4)),
                        child: Text(t['type']?.toString().toUpperCase() ?? 'SOLO', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFF6ee7b7), borderRadius: BorderRadius.circular(4)),
                        child: Text(t['map']?.toString().toUpperCase() ?? 'BERMUDA', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.sports_esports, color: Color(0xFF374151), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "${t['title']} - Match #${t['id']}",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1f2937)),
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
                          Text(formattedDate, style: const TextStyle(color: Color(0xFFef4444), fontSize: 13, fontWeight: FontWeight.w600)),
                          Text(formattedTimeStr, style: const TextStyle(color: Color(0xFF9ca3af), fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                  const VerticalDivider(width: 1, color: Color(0xFFe5e7eb)),
                  
                  // Prize Pool (With Popup Arrow)
                  Expanded(
                    flex: 3,
                    child: GestureDetector(
                      onTap: () => _showPrizePoolPopup(context, t), // 🌟 Click action for Popup
                      child: Container(
                        color: Colors.transparent, // Click area cover karne ke liye
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          children: [
                            const Text("PRIZE POOL", style: TextStyle(color: Color(0xFF4b5563), fontSize: 11, fontWeight: FontWeight.bold)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("(🪙)${t['prize_pool'] ?? 0}", style: const TextStyle(color: Color(0xFF1f2937), fontSize: 14, fontWeight: FontWeight.bold)),
                                const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF4b5563)), // Dropdown icon
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const VerticalDivider(width: 1, color: Color(0xFFe5e7eb)),
                  
                  // Per Kill
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        children: [
                          const Text("PER KILL", style: TextStyle(color: Color(0xFF3b82f6), fontSize: 11, fontWeight: FontWeight.bold)),
                          Text("(🪙)${t['per_kill'] ?? 0}", style: const TextStyle(color: Color(0xFF3b82f6), fontSize: 14, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const Divider(height: 1, color: Color(0xFFe5e7eb)),

            // --- BOTTOM PROGRESS BAR ---
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("${t['spotsLeft']} Spots Left", style: const TextStyle(color: Color(0xFF4b5563), fontSize: 12, fontWeight: FontWeight.w600)),
                      Text("${t['filled']}/${t['totalSlots']}", style: const TextStyle(color: Color(0xFF4b5563), fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: LinearProgressIndicator(
                      value: t['progress'], 
                      backgroundColor: const Color(0xFFe5e7eb), 
                      color: const Color(0xFF0ea5e9), 
                      minHeight: 8,
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