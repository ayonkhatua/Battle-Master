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
  bool _hasJoined = false; 
  
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

      // 2. Fetch ALL PARTICIPANTS (Ye base list hogi, jisme sab honge)
      final utResponse = await Supabase.instance.client
          .from('user_tournaments')
          .select('user_id, user_ign')
          .eq('tournament_id', widget.tournamentId);

      // 3. Fetch Game Results (Jinke paas kills/winnings hain)
      final rResponse = await Supabase.instance.client
          .from('game_results')
          .select('user_id, kills, winnings, is_winner')
          .eq('tournament_id', widget.tournamentId);

      // Map banalo jisse quickly pata chale kisne kitne kill kiye
      Map<String, Map<String, dynamic>> resultsMap = {};
      for (var r in rResponse as List<dynamic>) {
        resultsMap[r['user_id'].toString()] = {
          'kills': r['kills'] ?? 0,
          'winnings': r['winnings'] ?? 0,
          'isWinner': r['is_winner'] == true,
        };
      }

      List<Map<String, dynamic>> rawResults = [];
      List<Map<String, dynamic>> winnerRes = [];

      // 4. Combine Participant List + Results
      for (var ut in utResponse as List<dynamic>) {
        String userId = ut['user_id'].toString();
        String ign = ut['user_ign']?.toString() ?? 'Unknown';
        
        if (_currentUserId != null && userId == _currentUserId) {
          _hasJoined = true;
        }

        // Agar result hai toh wo daalo, warna 0 daalo
        Map<String, dynamic> userResult = resultsMap[userId] ?? {
          'kills': 0,
          'winnings': 0,
          'isWinner': false,
        };

        Map<String, dynamic> rowData = {
          'user_id': userId,
          'ign': ign,
          'kills': userResult['kills'],
          'winnings': userResult['winnings'],
          'isWinner': userResult['isWinner'],
          'isMe': _currentUserId != null && userId == _currentUserId,
        };

        rawResults.add(rowData);

        if (rowData['isWinner']) {
          winnerRes.add(rowData);
        }
      }

      // 🌟 MAGIC LOGIC 1: Sorting -> Pehle winnings pe, fir kills pe
      rawResults.sort((a, b) {
        int wCmp = b['winnings'].compareTo(a['winnings']);
        if (wCmp != 0) return wCmp;
        return b['kills'].compareTo(a['kills']);
      });

      // 🌟 Rank assign karo
      for (int i = 0; i < rawResults.length; i++) {
        rawResults[i]['rank'] = i + 1;
      }

      // 🌟 MAGIC LOGIC 2: Current user ko sabse upar pin karo
      List<Map<String, dynamic>> finalResultsList = [];
      Map<String, dynamic>? myResultData;

      for (var res in rawResults) {
        if (res['isMe'] == true) {
          myResultData = res;
          break;
        }
      }

      if (myResultData != null) {
        finalResultsList.add(myResultData);
      }

      for (var res in rawResults) {
        if (res['isMe'] == false) {
          finalResultsList.add(res);
        }
      }

      // Winners array ko bhi sort kardo just in case
      winnerRes.sort((a, b) {
        int wCmp = b['winnings'].compareTo(a['winnings']);
        if (wCmp != 0) return wCmp;
        return b['kills'].compareTo(a['kills']);
      });

      if (mounted) {
        setState(() {
          _tournament = tResponse;
          _allResults = finalResultsList; 
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
        backgroundColor: Color(0xFF0B1120), 
        body: Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6))),
      );
    }

    if (_tournament == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0B1120),
        appBar: AppBar(title: const Text("Match Result"), backgroundColor: const Color(0xFF0F172A)),
        body: const Center(child: Text("Tournament not found.", style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0B1120), 
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A), 
        title: const Text("MATCH RESULT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildImageCard(),
            
            const SizedBox(height: 25),

            if (_winnerResults.isNotEmpty) ...[
              _buildTableCard("🏆 WINNERS", _winnerResults),
              const SizedBox(height: 25),
            ],

            _buildTableCard("📋 FULL LEADERBOARD", _allResults),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCard() {
    DateTime localTime = DateTime.parse(_tournament!['time']).toLocal();
    String formattedDate = DateFormat('dd/MM/yyyy').format(localTime);
    String formattedTimeStr = DateFormat('hh:mm a').format(localTime);
    
    String type = _tournament!['type']?.toString().toUpperCase() ?? 'SOLO';
    String mapName = _tournament!['map']?.toString().toUpperCase() ?? 'BERMUDA';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
            child: _tournament!['image_url'] != null && _tournament!['image_url'].toString().isNotEmpty
                ? Image.network(_tournament!['image_url'], width: double.infinity, height: 180, fit: BoxFit.cover)
                : Container(height: 180, color: const Color(0xFF0F172A), child: const Icon(Icons.image, color: Colors.white24, size: 50)),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(type, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.white12)
                      ),
                      child: Text(mapName, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    const Icon(Icons.sports_esports, color: Colors.amberAccent, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "${_tournament!['mode']} Esports Mode - Match #${_tournament!['id']}",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const Divider(height: 1, color: Colors.white10),

          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      children: [
                        Text(formattedDate, style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 13, fontWeight: FontWeight.w900)), 
                        Text(formattedTimeStr, style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const VerticalDivider(width: 1, color: Colors.white10),
                
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      children: [
                        const Text("PRIZE POOL", style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("${_tournament!['prize_pool']}(₹)", style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const VerticalDivider(width: 1, color: Colors.white10),
                
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      children: [
                        const Text("PER KILL", style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("${_tournament!['per_kill']}(₹)", style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1, color: Colors.white10),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _hasJoined ? Colors.green.withOpacity(0.1) : Colors.redAccent.withOpacity(0.1),
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _hasJoined ? Icons.check_circle : Icons.cancel, 
                  color: _hasJoined ? Colors.greenAccent : Colors.redAccent, 
                  size: 18
                ),
                const SizedBox(width: 8),
                Text(
                  _hasJoined ? "YOU JOINED THIS MATCH" : "YOU DID NOT JOIN", 
                  style: TextStyle(
                    color: _hasJoined ? Colors.greenAccent : Colors.redAccent, 
                    fontWeight: FontWeight.bold, 
                    fontSize: 13, 
                    letterSpacing: 1.0
                  )
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableCard(String title, List<Map<String, dynamic>> rowsData) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 3))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            color: const Color(0xFF0F172A), 
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.amberAccent, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.2),
            ),
          ),
          
          Container(
            color: const Color(0xFF334155), 
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: const Row(
              children: [
                Expanded(flex: 1, child: Text("#", style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 13))),
                Expanded(flex: 4, child: Text("Player Name", style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 13))),
                Expanded(flex: 2, child: Text("Kills", textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 13))),
                Expanded(flex: 2, child: Text("Winning", textAlign: TextAlign.right, style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 13))),
              ],
            ),
          ),

          if (rowsData.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text("No result data available.", style: TextStyle(color: Colors.white54)),
            )
          else
            ...List.generate(rowsData.length, (index) {
              final r = rowsData[index];
              bool isMe = r['isMe'] ?? false;
              
              Color bgColor = isMe 
                  ? const Color(0xFF3B82F6).withOpacity(0.2) 
                  : index.isOdd 
                      ? const Color(0xFF111827) 
                      : const Color(0xFF1E293B); 

              return Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  color: bgColor, 
                  border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05), width: 1)),
                ),
                child: Row(
                  children: [
                    Expanded(flex: 1, child: Text("${r['rank']}", style: TextStyle(color: isMe ? Colors.blueAccent : Colors.white70, fontSize: 14, fontWeight: isMe ? FontWeight.w900 : FontWeight.bold))),
                    Expanded(
                      flex: 4, 
                      child: Text(
                        r['ign'], 
                        style: TextStyle(
                          color: isMe ? Colors.white : Colors.white70, 
                          fontWeight: isMe ? FontWeight.w900 : FontWeight.w600, 
                          fontSize: 14
                        ),
                        overflow: TextOverflow.ellipsis,
                      )
                    ),
                    Expanded(flex: 2, child: Text("${r['kills']}", textAlign: TextAlign.center, style: TextStyle(color: isMe ? Colors.white : Colors.white70, fontSize: 14, fontWeight: isMe ? FontWeight.w900 : FontWeight.bold))),
                    Expanded(flex: 2, child: Text("${r['winnings']}", textAlign: TextAlign.right, style: TextStyle(color: isMe ? Colors.greenAccent : Colors.greenAccent.withOpacity(0.7), fontSize: 14, fontWeight: FontWeight.w900))),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}