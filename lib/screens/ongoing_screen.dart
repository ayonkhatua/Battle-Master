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

      // 🌟 ASLI FIX: SIRF 'completed' STATUS KO CHHOD KAR SAB LO 🌟
      if (widget.isMyMatches && userId != null) {
        response = await Supabase.instance.client
            .from('tournaments')
            .select('*, user_tournaments!inner(user_id)')
            .eq('user_tournaments.user_id', userId)
            .neq('status', 'completed') // 👈 FIX: 'ongoing' hata kar ye wapas laga diya
            .order('time', ascending: false);
      } else {
        response = await Supabase.instance.client
            .from('tournaments')
            .select('*')
            .neq('status', 'completed') // 👈 FIX
            .order('time', ascending: false);
      }

      final nowLocal = DateTime.now(); // 🌟 Local Time le rahe hain
      Map<int, Map<String, dynamic>> uniqueMatches = {};

      if (response != null) {
        for (var row in response as List<dynamic>) {
          int tId = row['id'];
          
          // Time ko directly Local mein convert kar rahe hain taaki galti na ho
          DateTime matchTimeLocal = DateTime.tryParse(row['time'].toString())?.toLocal() ?? nowLocal;

          // 🌟 TIME CHECK: Agar match ka time nikal chuka hai (future mein nahi hai), tabhi yahan dikhao 🌟
          if (!matchTimeLocal.isAfter(nowLocal)) {
            if (!uniqueMatches.containsKey(tId)) {
              uniqueMatches[tId] = {
                ...row as Map<String, dynamic>,
                'matchTimeLocal': matchTimeLocal,
              };
            }
          }
        }
      }

      // Group by Category
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
                        
                        ...modeTournaments.map((t) => _buildCompactCard(t)),
                      ],
                    );
                  },
                ),
    );
  }

  // ==========================================
  // 🚀 COMPACT ONGOING CARD
  // ==========================================
  Widget _buildCompactCard(Map<String, dynamic> t) {
    DateTime localTime = t['matchTimeLocal'];
    String formattedDate = DateFormat('dd/MM/yyyy').format(localTime);
    String formattedTimeStr = DateFormat('hh:mm a').format(localTime);

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RulesScreen(tournamentId: t['id']))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          color: Colors.white, // Reference image ke hisaab se white bg
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
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
                    children: [
                      // Team Type Badge (e.g., Squad)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6), // Purple from reference image
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          t['type']?.toString().toUpperCase() ?? 'SOLO',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Map Badge (e.g., Bermuda)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1B4B), // Dark Navy from reference image
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          t['map']?.toString().toUpperCase() ?? 'BERMUDA',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
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
                          Text(formattedDate, style: const TextStyle(color: Color(0xFF8B5CF6), fontSize: 13, fontWeight: FontWeight.w600)), // Purple date
                          Text(formattedTimeStr, style: const TextStyle(color: Color(0xFF8B5CF6), fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                  const VerticalDivider(width: 1, color: Color(0xFFe5e7eb)),
                  
                  // Prize Pool
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        children: [
                          const Text("PRIZE POOL", style: TextStyle(color: Color(0xFF4b5563), fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.network('https://img.icons8.com/emoji/48/coin-emoji.png', width: 14, height: 14),
                              const SizedBox(width: 4),
                              Text("${t['prize_pool'] ?? 0}", style: const TextStyle(color: Color(0xFF1f2937), fontSize: 14, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
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
                          const Text("PER KILL", style: TextStyle(color: Color(0xFF4b5563), fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.network('https://img.icons8.com/emoji/48/coin-emoji.png', width: 14, height: 14),
                              const SizedBox(width: 4),
                              Text("${t['per_kill'] ?? 0}", style: const TextStyle(color: Color(0xFF1f2937), fontSize: 14, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const Divider(height: 1, color: Color(0xFFe5e7eb)),

            // --- 🌟 NAYA: BIG SPECTATE BUTTON ---
            Container(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Yahan baad mein Youtube link kholne ka code aayega
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Opening YouTube Link... (Add URL logic here)'))
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6), // Purple color
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "SPECTATE", 
                    style: TextStyle(
                      color: Colors.white, 
                      fontSize: 14, 
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5
                    )
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}