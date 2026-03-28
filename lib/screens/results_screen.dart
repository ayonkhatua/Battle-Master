import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class ResultsScreen extends StatefulWidget {
  final int tournamentId;

  const ResultsScreen({super.key, required this.tournamentId});

  @override
  _ResultsScreenState createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _tournament;
  List<Map<String, dynamic>> _allResults = [];
  List<Map<String, dynamic>> _winnerResults = [];
  List<Map<String, dynamic>> _myResults = [];
  List<String> _winnerList = [];
  
  final String? _currentUserId = Supabase.instance.client.auth.currentUser?.id;

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
      List<String> winners = winnerStr.isNotEmpty 
          ? winnerStr.split(',').map((e) => e.trim().toLowerCase()).toList() 
          : [];

      // 2. Fetch Results with Nested Joins
      final rResponse = await Supabase.instance.client
          .from('results')
          .select('''
            user_id,
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

      List<Map<String, dynamic>> allRes = [];
      List<Map<String, dynamic>> winnerRes = [];
      List<Map<String, dynamic>> myRes = [];

      int rank = 1;
      for (var r in rResponse as List<dynamic>) {
        Map<String, dynamic> rowData = Map<String, dynamic>.from(r);
        rowData['rank'] = rank;
        
        String ign = rowData['ign']?.toString().trim() ?? '-';
        String username = '';
        try {
          username = rowData['user_tournaments']['users']['username']?.toString().trim() ?? '';
        } catch (_) {}
        
        bool isWinner = winners.contains(ign.toLowerCase()) || (username.isNotEmpty && winners.contains(username.toLowerCase()));
        rowData['isWinner'] = isWinner;
        
        // Check if this row belongs to the current logged-in user
        bool isMe = _currentUserId != null && rowData['user_id'] == _currentUserId;
        rowData['isMe'] = isMe;

        allRes.add(rowData);

        if (isWinner) {
          winnerRes.add(rowData);
        }
        if (isMe) {
          myRes.add(rowData); // Storing user's specific results to show on top
        }
        
        rank++;
      }

      setState(() {
        _tournament = tResponse;
        _winnerList = winners;
        _allResults = allRes;
        _winnerResults = winnerRes;
        _myResults = myRes;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching results: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFf8fafc), // Light theme bg per screenshot
        body: Center(child: CircularProgressIndicator(color: Color(0xFF312e81))),
      );
    }

    if (_tournament == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Match Result"), backgroundColor: const Color(0xFF1e1b4b)),
        body: const Center(child: Text("Tournament not found.")),
      );
    }

    DateTime localTime = DateTime.parse(_tournament!['time']).toLocal();
    String formattedDate = DateFormat('dd/MM/yyyy hh:mm a').format(localTime);

    return Scaffold(
      backgroundColor: const Color(0xFFf3f4f6), // Light gray background
      appBar: AppBar(
        backgroundColor: const Color(0xFF1e1b4b), // Dark Purple AppBar
        title: const Text("Match Result", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- TOP BANNER & MATCH INFO ---
            Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
                  Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: _tournament!['image_url'] != null && _tournament!['image_url'].toString().isNotEmpty
                        ? Image.network(_tournament!['image_url'], fit: BoxFit.cover)
                        : const Icon(Icons.image, color: Colors.grey, size: 50),
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          "${_tournament!['mode']} Esports Mode - Match #${_tournament!['id']}",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1e1b4b)),
                        ),
                        const SizedBox(height: 12),
                        
                        // Date Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text("Organised on $formattedDate", style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w500)),
                        ),
                        const SizedBox(height: 12),
                        
                        // Prize | Kill | Entry Badges
                        Row(
                          children: [
                            _buildInfoBadge("Winning Prize", "${_tournament!['prize_pool']}(₹)"),
                            const SizedBox(width: 8),
                            _buildInfoBadge("Per Kill", "${_tournament!['per_kill']}(₹)"),
                            const SizedBox(width: 8),
                            _buildInfoBadge("Entry Fee", "${_tournament!['entry_fee']}", icon: Icons.monetization_on),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),

            // --- WINNERS TABLE ---
            if (_winnerResults.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildTableCard("Winner", _winnerResults),
              ),
              const SizedBox(height: 16),
            ],

            // --- MY RESULTS (IF JOINED) ---
            // Tumhare reference ke hisaab se, agar user join kiya hai toh uske results yahan pinned dikhenge
            if (_myResults.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildTableCard("My Match Result", _myResults, highlightAll: true),
              ),
              const SizedBox(height: 16),
            ],

            // --- FULL MATCH RESULT TABLE ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: _buildTableCard("Match Result", _allResults),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Helper for Top Badges
  Widget _buildInfoBadge(String label, String value, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
        color: Colors.white,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("$label : ", style: const TextStyle(color: Colors.black54, fontSize: 12)),
          if (icon != null) ...[
            Icon(icon, size: 14, color: Colors.amber),
            const SizedBox(width: 2),
          ],
          Text(value, style: const TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // The Leaderboard Table UI
  Widget _buildTableCard(String title, List<Map<String, dynamic>> rowsData, {bool highlightAll = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Table Header Title (Dark Purple)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: const Color(0xFF2e1065), // Very Dark Purple
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          
          // Table Columns Headers
          Container(
            color: const Color(0xFF4b5563), // Dark Gray
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: const Row(
              children: [
                Expanded(flex: 1, child: Text("#", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
                Expanded(flex: 4, child: Text("Player Name", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
                Expanded(flex: 2, child: Text("Kills", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
                Expanded(flex: 2, child: Text("Winning", textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
              ],
            ),
          ),

          // Table Data Rows
          ...List.generate(rowsData.length, (index) {
            final r = rowsData[index];
            bool isMe = r['isMe'] ?? false;
            
            // Background color logic: If it's "My Results" table, make it light yellow, else alternate rows.
            Color bgColor = Colors.white;
            if (highlightAll || isMe) {
              bgColor = const Color(0xFFfef9c3); // Light Yellow highlight for current user
            } else if (index.isOdd) {
              bgColor = const Color(0xFFf9fafb); // Very light gray for odd rows
            }

            return Container(
              color: bgColor,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
              ),
              child: Row(
                children: [
                  Expanded(flex: 1, child: Text("${r['rank']}", style: const TextStyle(color: Colors.black87, fontSize: 14))),
                  Expanded(
                    flex: 4, 
                    child: Text(
                      r['ign'], 
                      style: TextStyle(
                        color: isMe ? Colors.black : Colors.black87, 
                        fontWeight: isMe ? FontWeight.bold : FontWeight.w500,
                        fontSize: 14
                      ),
                      overflow: TextOverflow.ellipsis,
                    )
                  ),
                  Expanded(flex: 2, child: Text("${r['kills']}", textAlign: TextAlign.center, style: const TextStyle(color: Colors.black87, fontSize: 14))),
                  Expanded(flex: 2, child: Text("${r['won']}", textAlign: TextAlign.right, style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.bold))),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}