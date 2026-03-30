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
          .maybeSingle();

      if (tResponse == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // 2. Fetch IGNs directly from user_tournaments to map with user_id
      final utResponse = await Supabase.instance.client
          .from('user_tournaments')
          .select('user_id, user_ign')
          .eq('tournament_id', widget.tournamentId);

      Map<String, String> ignMap = {};
      for (var ut in utResponse as List<dynamic>) {
        ignMap[ut['user_id'].toString()] = ut['user_ign']?.toString() ?? 'Unknown';
      }

      // 3. Fetch Game Results
      final rResponse = await Supabase.instance.client
          .from('game_results')
          .select('user_id, kills, winnings, is_winner')
          .eq('tournament_id', widget.tournamentId)
          .order('winnings', ascending: false)
          .order('kills', ascending: false);

      List<Map<String, dynamic>> rawResults = [];
      List<Map<String, dynamic>> winnerRes = [];

      int rank = 1;
      for (var r in rResponse as List<dynamic>) {
        Map<String, dynamic> rowData = {};
        
        String userId = r['user_id'].toString();
        rowData['user_id'] = userId;
        rowData['kills'] = r['kills'] ?? 0;
        rowData['winnings'] = r['winnings'] ?? 0;
        rowData['isWinner'] = r['is_winner'] == true; 
        rowData['rank'] = rank;
        
        // Map the IGN
        String ign = ignMap[userId] ?? 'Unknown';
        rowData['ign'] = ign;

        // Check if this row belongs to the current logged-in user
        bool isMe = _currentUserId != null && userId == _currentUserId;
        rowData['isMe'] = isMe;

        rawResults.add(rowData);

        if (rowData['isWinner']) {
          winnerRes.add(rowData);
        }
        
        rank++;
      }

      // 🌟 MAGIC LOGIC: Current user ko dhoondo aur sabse upar pin karo
      List<Map<String, dynamic>> finalResultsList = [];
      Map<String, dynamic>? myResultData;

      // Pehle apna result nikal lo (agar hai toh)
      for (var res in rawResults) {
        if (res['isMe'] == true) {
          myResultData = res;
          break; // Mil gaya, loop roko
        }
      }

      // Agar mera data mila, toh use naye list ke sabse TOP par daal do
      if (myResultData != null) {
        finalResultsList.add(myResultData);
      }

      // Ab baaki sab ko line se add karo (par mera wala dobara mat add karna)
      for (var res in rawResults) {
        if (res['isMe'] == false) {
          finalResultsList.add(res);
        }
      }

      if (mounted) {
        setState(() {
          _tournament = tResponse;
          _allResults = finalResultsList; // 🌟 Updated list (jisme Main sabse upar hoon)
          _winnerResults = winnerRes;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching results: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFf8fafc), 
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
      backgroundColor: const Color(0xFFf3f4f6), 
      appBar: AppBar(
        backgroundColor: const Color(0xFF1e1b4b), 
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
                        Text(
                          "${_tournament!['mode']} Esports Mode - Match #${_tournament!['id']}",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1e1b4b)),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text("Organised on $formattedDate", style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w500)),
                        ),
                        const SizedBox(height: 12),
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

            // --- 1. WINNERS TABLE ---
            if (_winnerResults.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildTableCard("Winner", _winnerResults),
              ),
              const SizedBox(height: 16),
            ],

            // 🌟 FIXED: Removed 'My Match Result' separate table 

            // --- 2. FULL MATCH RESULT TABLE ---
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
  Widget _buildTableCard(String title, List<Map<String, dynamic>> rowsData) {
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
          if (rowsData.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("No result data available.", style: TextStyle(color: Colors.grey)),
            )
          else
            ...List.generate(rowsData.length, (index) {
              final r = rowsData[index];
              bool isMe = r['isMe'] ?? false;
              
              // 🌟 Background color logic: Apna result yellow highlight hoga
              Color bgColor = Colors.white;
              if (isMe) {
                bgColor = const Color(0xFFfef9c3); // Light Yellow highlight for current user
              } else if (index.isOdd) {
                bgColor = const Color(0xFFf9fafb); // Very light gray for odd rows
              }

              return Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: bgColor, // Sahi jagah par decoration set kiya
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
                ),
                child: Row(
                  children: [
                    Expanded(flex: 1, child: Text("${r['rank']}", style: TextStyle(color: isMe ? Colors.black : Colors.black87, fontSize: 14, fontWeight: isMe ? FontWeight.w900 : FontWeight.normal))),
                    Expanded(
                      flex: 4, 
                      child: Text(
                        r['ign'], 
                        style: TextStyle(
                          color: isMe ? Colors.black : Colors.black87, 
                          fontWeight: isMe ? FontWeight.w900 : FontWeight.w500, // 🌟 Khud ka naam zyada bold dikhega
                          fontSize: 14
                        ),
                        overflow: TextOverflow.ellipsis,
                      )
                    ),
                    Expanded(flex: 2, child: Text("${r['kills']}", textAlign: TextAlign.center, style: TextStyle(color: isMe ? Colors.black : Colors.black87, fontSize: 14, fontWeight: isMe ? FontWeight.w900 : FontWeight.normal))),
                    Expanded(flex: 2, child: Text("${r['winnings']}", textAlign: TextAlign.right, style: TextStyle(color: isMe ? Colors.black : Colors.black87, fontSize: 14, fontWeight: FontWeight.bold))),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}