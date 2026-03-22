import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResultsScreen extends StatefulWidget {
  final int tournamentId;

  const ResultsScreen({super.key, required this.tournamentId});

  @override
  _ResultsScreenState createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _tournament;
  List<Map<String, dynamic>> _players = [];
  List<String> _winnerList = [];

  @override
  void initState() {
    super.initState();
    _fetchResults();
  }

  Future<void> _fetchResults() async {
    try {
      // 1. Fetch Tournament Info
      final tResponse = await Supabase.instance.client
          .from('tournaments')
          .select()
          .eq('id', widget.tournamentId)
          .single();

      String winnerStr = tResponse['winner'] ?? '';
      _winnerList = winnerStr.isNotEmpty ? winnerStr.split(',').map((e) => e.trim()).toList() : [];

      // 2. Fetch Results & Users
      // Assuming 'results' table links to 'users' via 'participant_id'
      final rResponse = await Supabase.instance.client
          .from('results')
          .select('participant_id, kills, won, users!participant_id(username)')
          .eq('tournament_id', widget.tournamentId);

      // 3. Fetch IGNs from user_tournaments
      final utResponse = await Supabase.instance.client
          .from('user_tournaments')
          .select('user_id, ign')
          .eq('tournament_id', widget.tournamentId);

      // Create a map for quick IGN lookup by user_id
      Map<String, String> ignMap = {};
      for (var ut in utResponse as List<dynamic>) {
        ignMap[ut['user_id'].toString()] = ut['ign']?.toString() ?? '';
      }

      // 4. 🔥 DART MAGIC: Group By & MAX Logic (Replacing PHP's GROUP BY) 🔥
      Map<String, Map<String, dynamic>> groupedPlayers = {};

      for (var r in rResponse as List<dynamic>) {
        String pId = r['participant_id'].toString();
        
        // Safety checks for nested JSON
        String username = '';
        try {
          username = r['users']['username']?.toString().trim() ?? 'Unknown';
        } catch (_) {
          username = 'Unknown';
        }

        // COALESCE(ign, username) logic
        String ign = ignMap[pId] ?? '';
        if (ign.isEmpty) ign = username;

        String uniqueKey = "${username}_$ign";
        int kills = (r['kills'] as num?)?.toInt() ?? 0;
        int won = (r['won'] as num?)?.toInt() ?? 0;

        if (groupedPlayers.containsKey(uniqueKey)) {
          // Getting MAX(kills) and MAX(won)
          if (kills > groupedPlayers[uniqueKey]!['kills']) {
            groupedPlayers[uniqueKey]!['kills'] = kills;
          }
          if (won > groupedPlayers[uniqueKey]!['won']) {
            groupedPlayers[uniqueKey]!['won'] = won;
          }
        } else {
          groupedPlayers[uniqueKey] = {
            'username': username,
            'ign': ign,
            'kills': kills,
            'won': won,
          };
        }
      }

      // 5. Convert Map to List and Sort (ORDER BY won DESC, kills DESC)
      List<Map<String, dynamic>> finalPlayers = groupedPlayers.values.toList();
      finalPlayers.sort((a, b) {
        int wonComparison = b['won'].compareTo(a['won']);
        if (wonComparison != 0) return wonComparison;
        return b['kills'].compareTo(a['kills']);
      });

      setState(() {
        _tournament = tResponse;
        _players = finalPlayers;
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
      backgroundColor: const Color(0xFF0f172a), // Dark Theme
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
                  child: Column(
                    children: [
                      // Header Title
                      Text(
                        "#${widget.tournamentId} - ${_tournament!['title']} Result",
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFfacc15)),
                      ),
                      const SizedBox(height: 20),

                      // Horizontal Scroll setup for 5 columns
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF1e293b),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 4))
                              ],
                            ),
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(const Color(0xFF111827)),
                              dataRowColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
                                // Alternating row colors
                                return states.contains(WidgetState.selected) ? const Color(0xFF1f2937) : const Color(0xFF162033);
                              }),
                              columnSpacing: 25,
                              columns: const [
                                DataColumn(label: Text("Username", style: TextStyle(color: Color(0xFFfacc15), fontWeight: FontWeight.bold, fontSize: 15))),
                                DataColumn(label: Text("IGN", style: TextStyle(color: Color(0xFFfacc15), fontWeight: FontWeight.bold, fontSize: 15))),
                                DataColumn(label: Text("Kills", style: TextStyle(color: Color(0xFFfacc15), fontWeight: FontWeight.bold, fontSize: 15))),
                                DataColumn(label: Text("Coins Won", style: TextStyle(color: Color(0xFFfacc15), fontWeight: FontWeight.bold, fontSize: 15))),
                                DataColumn(label: Text("Status", style: TextStyle(color: Color(0xFFfacc15), fontWeight: FontWeight.bold, fontSize: 15))),
                              ],
                              rows: _players.isEmpty
                                  ? [
                                      const DataRow(cells: [
                                        DataCell(Text("-", style: TextStyle(color: Colors.white70))),
                                        DataCell(Text("-", style: TextStyle(color: Colors.white70))),
                                        DataCell(Text("No result data found.", style: TextStyle(color: Colors.white70))),
                                        DataCell(Text("-", style: TextStyle(color: Colors.white70))),
                                        DataCell(Text("-", style: TextStyle(color: Colors.white70))),
                                      ])
                                    ]
                                  : _players.map((p) {
                                      String username = p['username'];
                                      String ign = p['ign'];
                                      
                                      // Checking if winner by IGN or Username
                                      bool isWinner = _winnerList.contains(ign) || _winnerList.contains(username);

                                      return DataRow(
                                        cells: [
                                          DataCell(Text(username, style: const TextStyle(color: Color(0xFFe2e8f0)))),
                                          DataCell(Text(ign, style: const TextStyle(color: Color(0xFFe2e8f0)))),
                                          DataCell(Text("${p['kills']}", style: const TextStyle(color: Color(0xFFe2e8f0)))),
                                          DataCell(Text("💰 ${p['won']}", style: const TextStyle(color: Color(0xFFe2e8f0)))),
                                          DataCell(
                                            isWinner
                                                ? Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(color: const Color(0xFF14532d), borderRadius: BorderRadius.circular(6)),
                                                    child: const Text("🏆 Winner", style: TextStyle(color: Color(0xFF22c55e), fontSize: 12, fontWeight: FontWeight.bold)),
                                                  )
                                                : const Text("—", style: TextStyle(color: Color(0xFFe2e8f0))),
                                          ),
                                        ],
                                      );
                                    }).toList(),
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