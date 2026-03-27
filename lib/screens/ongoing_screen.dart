import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:async'; // Auto-refresh ke liye zaroori hai
import 'package:battle_master/screens/rules_screen.dart'; 

class OngoingScreen extends StatefulWidget {
  final bool isMyMatches; 
  const OngoingScreen({super.key, this.isMyMatches = false});

  @override
  _OngoingScreenState createState() => _OngoingScreenState();
}

class _OngoingScreenState extends State<OngoingScreen> {
  bool _isLoading = true;
  Map<String, List<Map<String, dynamic>>> _groupedTournaments = {};
  Timer? _refreshTimer; // Auto-refresh timer

  @override
  void initState() {
    super.initState();
    _fetchOngoingTournaments();
    
    // ⏳ AUTO REFRESH: Har 1 minute baad check karega ki koi naya match ongoing mein toh nahi aaya
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        _fetchOngoingTournaments(silentRefresh: true);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel(); // Memory leak se bachne ke liye timer cancel karo
    super.dispose();
  }

  Future<void> _fetchOngoingTournaments({bool silentRefresh = false}) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    try {
      if (!silentRefresh) setState(() => _isLoading = true);
      
      dynamic response;

      if (widget.isMyMatches && userId != null) {
        // PERSONAL MATCHES
        response = await Supabase.instance.client
            .from('tournaments')
            .select('*, user_tournaments!inner(user_id)')
            .eq('user_tournaments.user_id', userId)
            .neq('status', 'completed')
            .order('time', ascending: false);
      } else {
        // GLOBAL MATCHES
        response = await Supabase.instance.client
            .from('tournaments')
            .select('*')
            .neq('status', 'completed')
            .order('time', ascending: false);
      }

      // 🌍 GLOBAL TIME FIX: Har comparison ke liye UTC time use hoga
      final nowUTC = DateTime.now().toUtc();
      
      Map<String, List<Map<String, dynamic>>> tempGrouped = {};

      if (response != null) {
        for (var row in response as List<dynamic>) {
          // Database se aaye time ko strictly UTC mein convert kiya
          DateTime matchTimeUTC = DateTime.tryParse(row['time'].toString())?.toUtc() ?? nowUTC;

          // ⏳ TIME LOGIC: Agar match ka UTC time, current UTC time ke barabar ya usse kam hai
          if (!matchTimeUTC.isAfter(nowUTC)) {
            String mode = row['mode']?.toString().toUpperCase() ?? 'UNKNOWN';
            if (!tempGrouped.containsKey(mode)) tempGrouped[mode] = [];
            
            tempGrouped[mode]!.add({
              ...row as Map<String, dynamic>,
              'matchTime': matchTimeUTC, // Save format for displaying
            });
          }
        }
      }

      if (mounted) {
        setState(() {
          _groupedTournaments = tempGrouped;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching ongoing tournaments: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1e293b),
        title: Text(widget.isMyMatches ? "🔥 MY ONGOING MATCHES" : "🔥 ALL ONGOING MATCHES", style: const TextStyle(color: Color(0xFFf8fafc), fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFfacc15)))
          : _groupedTournaments.isEmpty
              ? Center(
                  child: Text(
                    widget.isMyMatches ? "⚠️ No ongoing matches for you." : "⚠️ No ongoing tournaments right now.", 
                    style: const TextStyle(color: Color(0xFF9ca3af), fontSize: 16)
                  )
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
                  itemCount: _groupedTournaments.length,
                  itemBuilder: (context, index) {
                    String mode = _groupedTournaments.keys.elementAt(index);
                    List<Map<String, dynamic>> modeTournaments = _groupedTournaments[mode]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: EdgeInsets.only(bottom: 15, top: index == 0 ? 0 : 20),
                          padding: const EdgeInsets.only(bottom: 6),
                          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF334155), width: 2))),
                          child: Text(mode, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF38bdf8))),
                        ),
                        
                        // Yahan decide hoga kaunsa card dikhana hai
                        ...modeTournaments.map((t) => widget.isMyMatches ? _buildPrivateCard(t) : _buildGlobalCard(t)),
                      ],
                    );
                  },
                ),
    );
  }

  // ==========================================
  // 1️⃣ PRIVATE CARD (White Theme)
  // ==========================================
  Widget _buildPrivateCard(Map<String, dynamic> t) {
    // Note: Dikhane ke liye time ko wapas local time mein la sakte hain
    DateTime localTime = t['matchTime'].toLocal();
    String formattedTime = DateFormat('dd/MM/yyyy hh:mm a').format(localTime);

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RulesScreen(tournamentId: t['id']))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 4))]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("#${t['id']} - ${t['title']}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
            const SizedBox(height: 5),
            Text("Started: $formattedTime", style: const TextStyle(fontSize: 14, color: Color(0xFF6b7280))),
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildPrivateGridItem("Prize", "💰 ${t['prize_pool']}"),
                _buildPrivateGridItem("Per Kill", "💰 ${t['per_kill']}"),
                _buildPrivateGridItem("Entry", "💰 ${t['entry_fee']}"),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildPrivateGridItem("Type", t['type']?.toString().toUpperCase() ?? '-'),
                _buildPrivateGridItem("Version", t['version'] ?? '-'),
                _buildPrivateGridItem("Map", t['map'] ?? '-'),
              ],
            ),
            const SizedBox(height: 18),
            
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: const Color(0xFFf59e0b).withOpacity(0.1), border: Border.all(color: const Color(0xFFf59e0b)), borderRadius: BorderRadius.circular(8)),
              child: const Text("🔥 MATCH IS LIVE", textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFf59e0b), fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 2️⃣ GLOBAL CARD (Dark Theme with Image)
  // ==========================================
  Widget _buildGlobalCard(Map<String, dynamic> t) {
    DateTime localTime = t['matchTime'].toLocal();
    String formattedTime = DateFormat('dd/MM/yyyy hh:mm a').format(localTime);

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RulesScreen(tournamentId: t['id']))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(color: const Color(0xFF1e293b), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 8, offset: const Offset(0, 4))]),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 160, width: double.infinity, color: Colors.grey[800],
              child: t['image_url'] != null && t['image_url'].toString().isNotEmpty
                  ? Image.network(t['image_url'], fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.image, color: Colors.white54, size: 50))
                  : const Icon(Icons.image, color: Colors.white54, size: 50),
            ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("#${t['id']} - ${t['title']}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFfacc15))),
                  const SizedBox(height: 5),
                  Text("Started: $formattedTime", style: const TextStyle(fontSize: 12, color: Color(0xFF9ca3af))),
                  const SizedBox(height: 15),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildGlobalGridItem("Prize", "💰 ${t['prize_pool']}"),
                      _buildGlobalGridItem("Per Kill", "💰 ${t['per_kill']}"),
                      _buildGlobalGridItem("Entry", "💰 ${t['entry_fee']}"),
                    ],
                  ),
                  const SizedBox(height: 15),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildGlobalGridItem("Type", t['type'] ?? '-'),
                      _buildGlobalGridItem("Version", t['version'] ?? '-'),
                      _buildGlobalGridItem("Map", t['map'] ?? '-'),
                    ],
                  ),
                  const SizedBox(height: 15),
                  
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(color: const Color(0xFFf59e0b), borderRadius: BorderRadius.circular(6)),
                    child: const Text("MATCH IS LIVE", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Grid Items Layouts ---
  Widget _buildPrivateGridItem(String title, String value) {
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

  Widget _buildGlobalGridItem(String title, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 13, color: Colors.white70), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}