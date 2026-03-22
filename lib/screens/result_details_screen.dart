import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResultDetailsScreen extends StatefulWidget {
  final int tournamentId; // PHP ke $_GET['tid'] ka replacement

  const ResultDetailsScreen({super.key, required this.tournamentId});

  @override
  _ResultDetailsScreenState createState() => _ResultDetailsScreenState();
}

class _ResultDetailsScreenState extends State<ResultDetailsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _tournament;
  List<Map<String, dynamic>> _results = [];
  List<String> _winnerList = [];

  @override
  void initState() {
    super.initState();
    _fetchResults();
  }

  Future<void> _fetchResults() async {
    try {
      // 1. Tournament ki basic info fetch karna
      final tResponse = await Supabase.instance.client
          .from('tournaments')
          .select()
          .eq('id', widget.tournamentId)
          .single();

      // 2. Winner list ko split karke List<String> banana (PHP ka explode)
      String winnerStr = tResponse['winner'] ?? '';
      List<String> winners = winnerStr.isNotEmpty 
          ? winnerStr.split(',').map((e) => e.trim()).toList() 
          : [];

      // 3. Results fetch karna with Nested Joins (PHP ka LEFT JOIN)
      // DHYAN DEIN: Ye tabhi chalega jab Foreign Keys sahi se set hon
      final rResponse = await Supabase.instance.client
          .from('results')
          .select('''
            ign, 
            kills, 
            won,
            user_tournaments (
              users (username)
            )
          ''')
          .eq('tournament_id', widget.tournamentId)
          .order('won', ascending: false)
          .order('kills', ascending: false);

      setState(() {
        _tournament = tResponse;
        _winnerList = winners;
        _results = List<Map<String, dynamic>>.from(rResponse);
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching results: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f172a), // Pure dark background
      appBar: AppBar(
        backgroundColor: const Color(0xFF1e293b),
        title: Text(
          _tournament != null ? "Result - ${_tournament!['title']}" : "Result",
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFfacc15)))
          : _tournament == null
              ? const Center(child: Text("Tournament not found.", style: TextStyle(color: Colors.white)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1e293b),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 20, offset: const Offset(0, 4))
                      ],
                    ),
                    child: Column(
                      children: [
                        // Title
                        Text(
                          "#${widget.tournamentId} - ${_tournament!['title']} Result",
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFfacc15)),
                        ),
                        const SizedBox(height: 20),

                        // Custom Table banane ke liye hum Column aur Rows use karenge
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Column(
                            children: [
                              // Table Header
                              Container(
                                color: const Color(0xFF111827),
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                                child: const Row(
                                  children: [
                                    Expanded(flex: 3, child: Text("IGN", textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFfacc15), fontWeight: FontWeight.bold))),
                                    Expanded(flex: 2, child: Text("Kills", textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFfacc15), fontWeight: FontWeight.bold))),
                                    Expanded(flex: 3, child: Text("Coins", textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFfacc15), fontWeight: FontWeight.bold))),
                                    Expanded(flex: 3, child: Text("Status", textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFfacc15), fontWeight: FontWeight.bold))),
                                  ],
                                ),
                              ),

                              // Table Rows
                              if (_results.isEmpty)
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  color: const Color(0xFF162033),
                                  child: const Center(child: Text("No result data found.", style: TextStyle(color: Colors.white70))),
                                )
                              else
                                ...List.generate(_results.length, (index) {
                                  final r = _results[index];
                                  final ign = r['ign']?.toString().trim() ?? '-';
                                  
                                  // Nested join se username nikalna (safety checks ke sath)
                                  String username = '';
                                  try {
                                    username = r['user_tournaments']['users']['username']?.toString().trim() ?? '';
                                  } catch (_) {}

                                  // Check if winner
                                  bool isWinner = _winnerList.contains(ign) || (username.isNotEmpty && _winnerList.contains(username));

                                  // Alternating row colors
                                  Color rowColor = index.isEven ? const Color(0xFF162033) : Colors.transparent;

                                  return Container(
                                    color: rowColor,
                                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                                    decoration: const BoxDecoration(
                                      border: Border(bottom: BorderSide(color: Color(0xFF334155), width: 1)),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(flex: 3, child: Text(ign, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFe2e8f0)))),
                                        Expanded(flex: 2, child: Text("${r['kills'] ?? 0}", textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFe2e8f0)))),
                                        Expanded(flex: 3, child: Text("💰 ${r['won'] ?? 0}", textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFe2e8f0)))),
                                        Expanded(
                                          flex: 3, 
                                          child: isWinner 
                                            ? Center(
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(color: const Color(0xFF14532d), borderRadius: BorderRadius.circular(6)),
                                                  child: const Text("🏆 Winner", style: TextStyle(color: Color(0xFF22c55e), fontSize: 10, fontWeight: FontWeight.bold)),
                                                ),
                                              )
                                            : const Text("—", textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFe2e8f0))),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}