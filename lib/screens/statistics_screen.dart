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

  // 🌟 FIXED: Direct Table Fetch aur Tournament ID & Date formatting
  Future<List<Map<String, dynamic>>> _fetchStatistics() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw Exception("User not logged in");
    }

    try {
      final response = await Supabase.instance.client
          .from('statistics')
          .select('*')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> matches = (response as List).map((item) {
        final data = item as Map<String, dynamic>;
        
        String timeString = data['created_at'] ?? ''; 
        String formattedTime = 'Unknown Time';
        
        // Date format like Screenshot: 28/03/2026 10:00 pm
        try {
          if (timeString.isNotEmpty) {
            formattedTime = DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.parse(timeString).toLocal());
          }
        } catch (e) {
          debugPrint("Date parse error: $e");
        }
            
        return {
          'title': data['title'] ?? 'Unknown Match',
          'tournament_id': data['tournament_id']?.toString() ?? '',
          'datetime': formattedTime.toLowerCase(), // pm/am chote case me
          'paid': int.tryParse(data['paid'].toString()) ?? 0, 
          'won': int.tryParse(data['won'].toString()) ?? 0,
        };
      }).toList();

      return matches;

    } catch (e) {
      debugPrint("Error fetching statistics: $e");
      return [];
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _statisticsFuture = _fetchStatistics();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1120), // Dark Background
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Transparent AppBar
        title: const Text("MY STATISTICS", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        centerTitle: true, 
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF3B82F6)), // Blue icon
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _statisticsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6))); 
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error loading data", style: const TextStyle(color: Colors.white54)));
          }

          final matches = snapshot.data ?? [];

          return RefreshIndicator(
            onRefresh: _refreshData,
            color: const Color(0xFF0B1120),
            backgroundColor: const Color(0xFF3B82F6),
            child: Column(
              children: [
                // 🌟 HEADER ROW (Dark Theme with your exact headers)
                Container(
                  color: const Color(0xFF1E293B), // Darker header row
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
                  child: Row(
                    children: const [
                      SizedBox(
                        width: 25,
                        child: Text("#", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                      Expanded(
                        child: Text("Match Info", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                      SizedBox(
                        width: 50,
                        child: Text("Paid", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                      SizedBox(
                        width: 50,
                        child: Text("Won", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ],
                  ),
                ),
                
                // 🌟 LIST VIEW (Dark rows with divider)
                Expanded(
                  child: matches.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 150),
                            Center(child: Text("No match history found yet.", style: TextStyle(color: Colors.white54, fontSize: 16))),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: matches.length,
                          itemBuilder: (context, index) {
                            return _buildListRow(matches[index], index + 1);
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // 🌟 Dark Theme List Row Style
  Widget _buildListRow(Map<String, dynamic> match, int index) {
    // Title construction: "Battle Royale Classic - Match #36710"
    String baseTitle = match['title'].toString();
    String tId = match['tournament_id'];
    String displayTitle = tId.isNotEmpty ? "$baseTitle - Match #$tId" : baseTitle;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 15),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Dark row background
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.05), width: 1), // Subtle divider line
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Index Number
          SizedBox(
            width: 25,
            child: Text(
              "$index",
              style: const TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.w400),
            ),
          ),
          
          // 2. Match Info (Title + Date)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayTitle,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600), // White text for title
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  match['datetime'],
                  style: const TextStyle(color: Colors.white38, fontSize: 12), // Dimmer text for date
                ),
              ],
            ),
          ),
          
          // 3. Paid Amount
          SizedBox(
            width: 50,
            child: Text(
              match['paid'].toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          
          // 4. Won Amount
          SizedBox(
            width: 50,
            child: Text(
              match['won'].toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}