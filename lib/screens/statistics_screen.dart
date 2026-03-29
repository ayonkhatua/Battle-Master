import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  _StatisticsScreenState createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  Future<List<Map<String, dynamic>>>? _statisticsFuture;

  @override
  void initState() {
    super.initState();
    _statisticsFuture = _fetchStatistics();
  }

  // 🌟 SAFE & EFFICIENT RPC CALL
  Future<List<Map<String, dynamic>>> _fetchStatistics() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw Exception("User not logged in");
    }

    try {
      final response = await Supabase.instance.client
          .rpc('get_user_statistics', params: {'p_user_id': user.id});

      if (response == null) return [];

      final List<Map<String, dynamic>> matches = (response as List).map((item) {
        final data = item as Map<String, dynamic>;
        String timeString = data['start_time'] ?? '';
        String formattedTime = 'Unknown Time';
        
        // Safe Date Parsing taaki app crash na ho
        try {
          if (timeString.isNotEmpty) {
            formattedTime = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(timeString));
          }
        } catch (e) {
          debugPrint("Date parse error: $e");
        }
            
        return {
          'title': data['title'] ?? 'Unknown Match',
          'datetime': formattedTime,
          'paid': int.tryParse(data['total_paid'].toString()) ?? 0,
          'won': int.tryParse(data['total_won'].toString()) ?? 0,
        };
      }).toList();

      return matches;

    } catch (e) {
      debugPrint("Error fetching statistics via RPC: $e");
      return [];
    }
  }

  // Helper method: App refresh karne ke liye
  Future<void> _refreshData() async {
    setState(() {
      _statisticsFuture = _fetchStatistics();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1120), // 🌟 Deep Dark Blue Theme
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text("MY STATISTICS", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF3B82F6)), // Blue back button
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _statisticsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6))); // Blue Loader
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error loading data", style: const TextStyle(color: Colors.white54)));
          }

          final matches = snapshot.data ?? [];

          return RefreshIndicator(
            onRefresh: _refreshData,
            color: const Color(0xFF0B1120),
            backgroundColor: const Color(0xFF3B82F6),
            child: matches.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 150),
                      Center(child: Text("No tournament results available yet.", style: TextStyle(color: Colors.white54, fontSize: 16))),
                    ],
                  )
                : ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    children: [
                      _buildSummaryCard(matches), // 🌟 Naya Summary Section
                      const SizedBox(height: 25),
                      const Text(
                        "MATCH HISTORY",
                        style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.5),
                      ),
                      const SizedBox(height: 15),
                      ...matches.map((m) => _buildMatchCard(m)),
                    ],
                  ),
          );
        },
      ),
    );
  }

  // 🌟 Naya Feature: Lifetime Summary Card
  Widget _buildSummaryCard(List<Map<String, dynamic>> matches) {
    int totalPaid = 0;
    int totalWon = 0;
    
    for (var match in matches) {
      totalPaid += match['paid'] as int;
      totalWon += match['won'] as int;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text("LIFETIME PERFORMANCE", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryStat("ENTRY PAID", totalPaid, const Color(0xFFEF4444)), // Red
              Container(height: 40, width: 1, color: Colors.white24), // Divider
              _buildSummaryStat("TOTAL WON", totalWon, const Color(0xFF10B981)), // Green
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStat(String title, int amount, Color amountColor) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network('https://img.icons8.com/emoji/48/coin-emoji.png', width: 20, height: 20),
            const SizedBox(width: 6),
            Text(
              amount.toString(),
              style: TextStyle(color: amountColor, fontSize: 24, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
      ],
    );
  }

  // 🌟 Premium Match History Card (Replaces the boring table)
  Widget _buildMatchCard(Map<String, dynamic> match) {
    int won = match['won'] as int;
    bool isWinner = won > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.8), // Glassmorphic Dark
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Title and Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  match['title'].toString().toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isWinner)
                const Icon(Icons.emoji_events, color: Color(0xFFFACC15), size: 20), // Trophy icon for win
            ],
          ),
          const SizedBox(height: 4),
          
          // Row 2: Date & Time
          Text(
            match['datetime'],
            style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w600),
          ),
          
          const SizedBox(height: 12),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 12),

          // Row 3: Paid & Won Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Entry Fee
              Row(
                children: [
                  const Text("ENTRY: ", style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w800)),
                  Image.network('https://img.icons8.com/emoji/48/coin-emoji.png', width: 14, height: 14),
                  const SizedBox(width: 4),
                  Text(
                    match['paid'].toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              
              // Winnings
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isWinner ? const Color(0xFF10B981).withOpacity(0.15) : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text("WON: ", style: TextStyle(color: isWinner ? const Color(0xFF10B981) : Colors.white54, fontSize: 11, fontWeight: FontWeight.w800)),
                    Image.network('https://img.icons8.com/emoji/48/coin-emoji.png', width: 14, height: 14),
                    const SizedBox(width: 4),
                    Text(
                      match['won'].toString(),
                      style: TextStyle(color: isWinner ? const Color(0xFF10B981) : Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}