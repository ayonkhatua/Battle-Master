import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:async'; // Auto-refresh ke liye zaroori hai
import 'package:battle_master/screens/rules_screen.dart';

class UpcomingScreen extends StatefulWidget {
  const UpcomingScreen({super.key});

  @override
  _UpcomingScreenState createState() => _UpcomingScreenState();
}

class _UpcomingScreenState extends State<UpcomingScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _tournaments = [];
  Timer? _refreshTimer; // Auto-refresh timer

  @override
  void initState() {
    super.initState();
    _fetchUpcomingTournaments();
    
    // ⏳ AUTO REFRESH: Har 1 minute baad background mein check karega
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        _fetchUpcomingTournaments(silentRefresh: true);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel(); // Memory leak se bachne ke liye cancel karo
    super.dispose();
  }

  // silentRefresh se list background me update hogi, loading spinner nahi aayega baar baar
  Future<void> _fetchUpcomingTournaments({bool silentRefresh = false}) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      if (!silentRefresh) setState(() => _isLoading = true);

      // 🌟 MAGIC QUERY: Sirf Joined aur jinka result nahi aaya hai
      final response = await Supabase.instance.client
          .from('tournaments')
          .select('*, user_tournaments!inner(user_id)')
          .eq('user_tournaments.user_id', user.id)
          .neq('status', 'completed') 
          .order('time', ascending: true);

      // 🌍 GLOBAL TIME FIX: Har comparison UTC time ke hisaab se hoga
      final nowUTC = DateTime.now().toUtc();
      List<Map<String, dynamic>> formattedList = [];

      for (var row in response as List<dynamic>) {
        // Database se aaye time ko strictly UTC mein convert kiya
        DateTime matchTimeUTC = DateTime.tryParse(row['time'].toString())?.toUtc() ?? nowUTC;
        
        // ⏳ TIME LOGIC: Sirf aage ka time (Upcoming) dikhao
        if (matchTimeUTC.isAfter(nowUTC)) {
          int slots = row['slots'] ?? 0;
          String type = (row['type'] ?? '').toString().toLowerCase();
          int squadSize = 1;
          if (type == 'duo') squadSize = 2;
          if (type == 'squad') squadSize = 4;

          int totalSlots = slots * squadSize;
          int filled = row['filled'] ?? 0;
          double progress = totalSlots > 0 ? (filled / totalSlots) : 0;
          if (progress > 1.0) progress = 1.0;

          formattedList.add({
            ...row,
            'totalSlots': totalSlots,
            'filled': filled,
            'progress': progress,
            'spotsLeft': totalSlots - filled,
            'matchTimeUTC': matchTimeUTC, // Save format as UTC
          });
        }
      }

      if (mounted) {
        setState(() {
          _tournaments = formattedList;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching upcoming tournaments: $e");
      if (mounted) setState(() => _isLoading = false);
    }
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
                    
                    // Dikhane ke liye time wapas Local (India time) mein convert kiya
                    DateTime localTime = t['matchTimeUTC'].toLocal();
                    String formattedTime = DateFormat('dd/MM/yyyy hh:mm a').format(localTime);

                    return GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RulesScreen(tournamentId: t['id']))),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("#${t['id']} - ${t['title']}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                            const SizedBox(height: 5),
                            Text("Starts: $formattedTime", style: const TextStyle(fontSize: 14, color: Color(0xFF6b7280))),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildGridItem("Prize", "💰 ${t['prize_pool']}"),
                                _buildGridItem("Per Kill", "💰 ${t['per_kill']}"),
                                _buildGridItem("Entry", "💰 ${t['entry_fee']}"),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("${t['spotsLeft']} Spots Left", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                Text("${t['filled']}/${t['totalSlots']}", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(value: t['progress'], backgroundColor: const Color(0xFFe5e7eb), color: const Color(0xFF0ea5e9), minHeight: 10, borderRadius: BorderRadius.circular(5)),
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
          Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF9ca3af), fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 15, color: Color(0xFF374151), fontWeight: FontWeight.w600), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}