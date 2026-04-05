import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:async'; 
import 'package:battle_master/screens/rules_screen.dart'; 
import 'package:battle_master/screens/results_screen.dart'; 

class TournamentScreen extends StatefulWidget {
  final String mode;

  const TournamentScreen({super.key, required this.mode});

  @override
  _TournamentScreenState createState() => _TournamentScreenState();
}

class _TournamentScreenState extends State<TournamentScreen> {
  bool _isLoading = true;
  Timer? _refreshTimer; 
  
  List<Map<String, dynamic>> _matches = []; 
  List<Map<String, dynamic>> _ongoing = []; 
  List<Map<String, dynamic>> _results = []; 

  Set<int> _myJoinedTournaments = {};

  int _userBalance = 0;
  bool _isBalanceLoading = true;

  StreamSubscription<List<Map<String, dynamic>>>? _balanceSubscription;

  @override
  void initState() {
    super.initState();
    _fetchInitialBalance(); // 🌟 FIX: Pehle single fresh fetch karo balance ke liye
    _fetchTournaments();
    _listenToUserBalance(); 
    
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        _fetchTournaments(silentRefresh: true);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel(); 
    _balanceSubscription?.cancel(); 
    super.dispose();
  }

  // 🌟 NAYA: Initial Fresh Balance Fetch 🌟
  Future<void> _fetchInitialBalance() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final response = await Supabase.instance.client
          .from('users')
          .select('wallet_balance')
          .eq('id', userId)
          .maybeSingle();

      if (response != null && mounted) {
        setState(() {
          _userBalance = response['wallet_balance'] ?? 0;
          _isBalanceLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Initial Balance Fetch Error: $e");
    }
  }

  void _listenToUserBalance() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) setState(() => _isBalanceLoading = false);
      return;
    }

    _balanceSubscription = Supabase.instance.client
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .listen((List<Map<String, dynamic>> data) {
      if (mounted && data.isNotEmpty) {
        setState(() {
          _userBalance = data.first['wallet_balance'] ?? 0;
          _isBalanceLoading = false;
        });
      }
    }, onError: (error) {
      debugPrint("Error listening to wallet balance: $error");
      if (mounted) setState(() => _isBalanceLoading = false);
    });
  }

  Future<void> _fetchTournaments({bool silentRefresh = false}) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    try {
      if (!silentRefresh) setState(() => _isLoading = true);

      if (userId != null) {
        final joinedRes = await Supabase.instance.client
            .from('user_tournaments')
            .select('tournament_id')
            .eq('user_id', userId);
            
        Set<int> joinedIds = {};
        for (var r in joinedRes as List<dynamic>) {
          joinedIds.add(r['tournament_id']);
        }
        _myJoinedTournaments = joinedIds;
      }

      final response = await Supabase.instance.client
          .from('tournaments')
          .select('*')
          .ilike('mode', widget.mode)
          .order('time', ascending: true);

      List<Map<String, dynamic>> tempMatches = [];
      List<Map<String, dynamic>> tempOngoing = [];
      List<Map<String, dynamic>> tempResults = [];

      final nowUTC = DateTime.now().toUtc();
      final twentyFourHoursAgoUTC = nowUTC.subtract(const Duration(hours: 24));

      for (var row in response as List<dynamic>) {
        int slots = row['slots'] ?? 0;
        String type = (row['type'] ?? '').toString().toLowerCase().trim(); 
        
        int squadSize = 1;
        if (type == 'duo') {
          squadSize = 2;
        } else if (type == 'squad') {
          squadSize = 4;
        }

        int totalCapacity = slots * squadSize; 
        int filled = row['filled'] ?? 0;
        double progress = totalCapacity > 0 ? (filled / totalCapacity) : 0;
        if (progress > 1.0) progress = 1.0; 
        
        int spotsLeft = totalCapacity - filled;
        bool isFull = filled >= totalCapacity; 

        DateTime matchTimeUTC = DateTime.tryParse(row['time'].toString())?.toUtc() ?? nowUTC;
        // 🌟 NAYA: Status check ko strictly classify karo
        String status = (row['status'] ?? 'upcoming').toString().toLowerCase().trim();

        Map<String, dynamic> matchData = {
          ...row,
          'totalCapacity': totalCapacity,
          'filled': filled,
          'progress': progress,
          'spotsLeft': spotsLeft,
          'isFull': isFull,
          'matchTimeUTC': matchTimeUTC, 
        };
        
        // 🔥 LOGIC: Pehle status check karo, phir time
        if (status == 'completed') {
          DateTime endTimeUTC = DateTime.tryParse(row['end_time'].toString())?.toUtc() ?? matchTimeUTC;
          if (endTimeUTC.isAfter(twentyFourHoursAgoUTC)) {
            tempResults.add(matchData);
          }
        } else if (status == 'ongoing' || status == 'live') {
          tempOngoing.add(matchData);
        } else {
          // Status agar 'upcoming' hai, tab time check karo safety ke liye
          if (matchTimeUTC.isAfter(nowUTC)) {
            tempMatches.add(matchData);
          } else {
            tempOngoing.add(matchData); // Time nikal gaya toh Ongoing
          }
        }
      }

      if (mounted) {
        setState(() {
          _matches = tempMatches;
          _ongoing = tempOngoing;
          _results = tempResults.reversed.toList(); 
          _isLoading = false;
        });
      }
      
    } catch (e) {
      print("Error fetching category tournaments: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showPrizePoolPopup(BuildContext context, Map<String, dynamic> item) {
    String prizeDesc = item['prize_description'] ?? "Prize details not available.";
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          titlePadding: EdgeInsets.zero,
          title: Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: const BoxDecoration(
              color: Color(0xFF312e81),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
            ),
            child: const Text("PRIZE POOL", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${item['title']} - Match #${item['id']}",
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
    return DefaultTabController(
      length: 3,
      initialIndex: 1, 
      child: Scaffold(
        backgroundColor: const Color(0xFF111827),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1e1b4b),
          title: Text(widget.mode, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          elevation: 0,
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 15, top: 12, bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.monetization_on, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    _isBalanceLoading ? "..." : _userBalance.toString(), 
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
                  ),
                ],
              ),
            )
          ],
          bottom: const TabBar(
            indicatorColor: Color(0xFF6366f1),
            labelColor: Colors.white,
            unselectedLabelColor: Color(0xFF9ca3af),
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            tabs: [
              Tab(text: "ONGOING"),
              Tab(text: "UPCOMING"),
              Tab(text: "RESULTS"),
            ],
          ),
        ),
        body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366f1)))
          : TabBarView(
              children: [
                _buildList(_ongoing, tabType: 'ongoing'),
                _buildList(_matches, tabType: 'upcoming'),
                _buildList(_results, tabType: 'result'),
              ],
            ),
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> list, {required String tabType}) {
    if (list.isEmpty) {
      return Center(
        child: Text(
          "No tournaments available here.", 
          style: const TextStyle(color: Color(0xFF9ca3af), fontSize: 16)
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: list.length,
      itemBuilder: (context, index) {
        return _buildModernCard(list[index], tabType);
      },
    );
  }

  Widget _buildModernCard(Map<String, dynamic> item, String tabType) {
    DateTime localTime = item['matchTimeUTC'].toLocal();
    String formattedDate = DateFormat('dd/MM/yyyy').format(localTime);
    String formattedTime = DateFormat('hh:mm a').format(localTime);
    
    int tId = item['id'];
    bool isJoined = _myJoinedTournaments.contains(tId);

    bool isResult = tabType == 'result';
    bool isOngoing = tabType == 'ongoing';

    return GestureDetector(
      onTap: () {
        if (isResult) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ResultsScreen(tournamentId: tId)));
        } else {
          // Yahan status auto-refresh ke liye handleRefresh add kiya hai
          Navigator.push(context, MaterialPageRoute(builder: (_) => RulesScreen(tournamentId: tId))).then((_) => _fetchTournaments(silentRefresh: true));
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 180,
                  width: double.infinity,
                  color: Colors.grey[300],
                  child: item['image_url'] != null && item['image_url'].toString().isNotEmpty
                      ? Image.network(item['image_url'], fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.image, color: Colors.grey, size: 50))
                      : const Icon(Icons.image, color: Colors.grey, size: 50),
                ),
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black.withOpacity(0.9), Colors.transparent],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12, left: 15, right: 15,
                  child: Text(
                    item['title'].toString().toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFF818cf8), borderRadius: BorderRadius.circular(4)), 
                        child: Text(item['type']?.toString().toUpperCase() ?? 'SOLO', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFF1e1b4b), borderRadius: BorderRadius.circular(4)), 
                        child: Text(item['map']?.toString().toUpperCase() ?? 'BERMUDA', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 30, color: Color(0xFFe5e7eb)),
                  IntrinsicHeight(
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              Text(formattedDate, style: const TextStyle(color: Color(0xFF818cf8), fontSize: 12, fontWeight: FontWeight.w600)),
                              Text(formattedTime, style: const TextStyle(color: Color(0xFF818cf8), fontSize: 12)),
                            ],
                          ),
                        ),
                        const VerticalDivider(width: 1, color: Color(0xFFe5e7eb)),
                        Expanded(
                          flex: 3,
                          child: GestureDetector(
                            onTap: () => _showPrizePoolPopup(context, item),
                            child: Column(
                              children: [
                                const Text("PRIZE POOL", style: TextStyle(color: Color(0xFF4b5563), fontSize: 11, fontWeight: FontWeight.bold)),
                                Text("${item['prize_pool']}(🪙)", style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                        const VerticalDivider(width: 1, color: Color(0xFFe5e7eb)),
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              const Text("PER KILL", style: TextStyle(color: Color(0xFF4b5563), fontSize: 11, fontWeight: FontWeight.bold)),
                              Text("${item['per_kill']}(🪙)", style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  if (isResult)
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(color: const Color(0xFF818cf8), borderRadius: BorderRadius.circular(6)), 
                            child: const Text("WATCH", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(color: isJoined ? const Color(0xFF10b981) : const Color(0xFF818cf8), borderRadius: BorderRadius.circular(6)), 
                            child: Text(isJoined ? "JOINED" : "CLOSED", textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    )
                  else if (isOngoing)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(color: const Color(0xFFf59e0b), borderRadius: BorderRadius.circular(6)),
                      child: const Text("MATCH IS LIVE / ONGOING", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("${item['filled']}/${item['totalCapacity']}", style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              LinearProgressIndicator(
                                value: item['progress'],
                                backgroundColor: const Color(0xFFe5e7eb),
                                color: const Color(0xFF818cf8), 
                                minHeight: 6,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isJoined ? const Color(0xFF10b981) : (item['isFull'] ? const Color(0xFF111827) : const Color(0xFF818cf8)), 
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            onPressed: (item['isFull'] && !isJoined) ? null : () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => RulesScreen(tournamentId: tId))).then((_) => _fetchTournaments(silentRefresh: true));
                            },
                            child: Text(isJoined ? "JOINED" : (item['isFull'] ? "FULL" : "JOIN"), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
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