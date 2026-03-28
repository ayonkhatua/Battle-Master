import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:async'; 
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
  Timer? _refreshTimer; 

  @override
  void initState() {
    super.initState();
    _fetchOngoingTournaments();
    
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        _fetchOngoingTournaments(silentRefresh: true);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel(); 
    super.dispose();
  }

  Future<void> _fetchOngoingTournaments({bool silentRefresh = false}) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    try {
      if (!silentRefresh) setState(() => _isLoading = true);
      
      dynamic response;

      // 🌟 STATUS FILTERING - Sirf wahi layega jo 'completed' nahi hain
      if (widget.isMyMatches && userId != null) {
        response = await Supabase.instance.client
            .from('tournaments')
            .select('*, user_tournaments!inner(user_id)')
            .eq('user_tournaments.user_id', userId)
            .neq('status', 'completed') 
            .order('time', ascending: false);
      } else {
        response = await Supabase.instance.client
            .from('tournaments')
            .select('*')
            .neq('status', 'completed')
            .order('time', ascending: false);
      }

      final nowUTC = DateTime.now().toUtc();
      
      // 🌟 MAGIC LOGIC: Map use karke ID duplicates hatana 🌟
      Map<int, Map<String, dynamic>> uniqueMatches = {};

      if (response != null) {
        for (var row in response as List<dynamic>) {
          int tId = row['id'];
          DateTime matchTimeUTC = DateTime.tryParse(row['time'].toString())?.toUtc() ?? nowUTC;

          // Sirf wahi match jo START ho chuka hai (Current Time se pehle ka time hai)
          if (!matchTimeUTC.isAfter(nowUTC)) {
            if (!uniqueMatches.containsKey(tId)) {
              uniqueMatches[tId] = {
                ...row as Map<String, dynamic>,
                'matchTime': matchTimeUTC,
              };
            }
          }
        }
      }

      // Group by Category (Mode)
      Map<String, List<Map<String, dynamic>>> tempGrouped = {};
      for (var t in uniqueMatches.values) {
        String mode = t['mode']?.toString().toUpperCase() ?? 'UNKNOWN';
        if (!tempGrouped.containsKey(mode)) tempGrouped[mode] = [];
        tempGrouped[mode]!.add(t);
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
        title: Text(widget.isMyMatches ? "🔥 MY ONGOING MATCHES" : "🔥 ALL ONGOING MATCHES", 
            style: const TextStyle(color: Color(0xFFf8fafc), fontSize: 18, fontWeight: FontWeight.bold)),
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
                        
                        ...modeTournaments.map((t) => _buildOngoingCard(t)),
                      ],
                    );
                  },
                ),
    );
  }

  // ==========================================
  // 🚀 ONGOING CARD (Dark Premium UI - No Confusion with Completed)
  // ==========================================
  Widget _buildOngoingCard(Map<String, dynamic> t) {
    DateTime localTime = t['matchTime'].toLocal();
    String formattedTime = DateFormat('dd/MM/yyyy hh:mm a').format(localTime);

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RulesScreen(tournamentId: t['id']))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          // 🌟 PREMIUM DARK BLUE GRADIENT 🌟
          gradient: const LinearGradient(
            colors: [Color(0xFF1e3a8a), Color(0xFF1e293b)], 
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5), 
              blurRadius: 10, 
              offset: const Offset(0, 5)
            )
          ],
          border: Border.all(color: const Color(0xFF3b82f6).withOpacity(0.3), width: 1),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "#${t['id']} - ${t['title']}", 
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFef4444).withOpacity(0.2), 
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFef4444), width: 1)
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, color: Colors.redAccent, size: 8),
                            SizedBox(width: 4),
                            Text("LIVE", style: TextStyle(color: Color(0xFFef4444), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text("Started: $formattedTime", style: const TextStyle(fontSize: 12, color: Color(0xFF9ca3af))),
                ],
              ),
            ),
            
            const Divider(color: Color(0xFF334155), height: 1),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildPremiumStat("TYPE", t['type']?.toString().toUpperCase() ?? '-'),
                  _buildPremiumStat("VERSION", t['version'] ?? '-'),
                  _buildPremiumStat("MAP", t['map'] ?? '-'),
                ],
              ),
            ),
            
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF3b82f6),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(15), bottomRight: Radius.circular(15)),
              ),
              child: const Text("VIEW ROOM DETAILS", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.2)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumStat(String title, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 10, color: Color(0xFF94a3b8), fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}