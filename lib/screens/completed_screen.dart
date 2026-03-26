import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class CompletedScreen extends StatefulWidget {
  const CompletedScreen({super.key});

  @override
  _CompletedScreenState createState() => _CompletedScreenState();
}

class _CompletedScreenState extends State<CompletedScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _completedTournaments = [];

  @override
  void initState() {
    super.initState();
    _fetchCompletedTournaments();
  }

  Future<void> _fetchCompletedTournaments() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (userId == null) return;

    try {
      // 1-Month Rule: Aaj ki date se 30 din pehle ki date nikal rahe hain
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30)).toIso8601String();

      // 🌟 Supabase '!inner' Join (Game Results) 🌟
      // Ab hum game_results se data la rahe hain taaki user ki apni winnings dikhein,
      // Aur date filter lagaya hai taaki 30 din purane matches na dikhein.
      final response = await Supabase.instance.client
          .from('tournaments')
          .select('*, game_results!inner(kills, winnings, is_winner)')
          .eq('game_results.user_id', userId)
          .eq('status', 'completed')
          .gte('end_time', thirtyDaysAgo) // 1 Month filter
          .order('end_time', ascending: false); // Jo abhi khatam hua wo upar

      setState(() {
        _completedTournaments = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching completed tournaments: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f172a), // Dark Blue/Slate background
      appBar: AppBar(
        backgroundColor: const Color(0xFF1e293b),
        title: const Text(
          "🏆 MY COMPLETED MATCHES",
          style: TextStyle(color: Color(0xFFf8fafc), fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 4,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _completedTournaments.isEmpty
              ? _buildEmptyState()
              : _buildList(),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        "No completed matches in the last 30 days.",
        style: TextStyle(color: Color(0xFF94a3b8), fontSize: 16),
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
      itemCount: _completedTournaments.length,
      itemBuilder: (context, index) {
        final t = _completedTournaments[index];
        
        // Supabase nested relation list form mein deta hai, isliye [0]
        final myResult = (t['game_results'] as List).isNotEmpty ? t['game_results'][0] : null;

        String timeString = t['end_time'] ?? t['time'] ?? '';
        String formattedTime = '';
        if (timeString.isNotEmpty) {
          formattedTime = DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.parse(timeString));
        }

        // Check if user is winner
        bool isWinner = myResult != null && myResult['is_winner'] == true;

        return GestureDetector(
          onTap: () {
            // TODO: Navigate to Result Details Screen
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white, 
              borderRadius: BorderRadius.circular(18),
              // Agar winner hai toh golden glow, warna normal shadow
              boxShadow: [
                BoxShadow(
                  color: isWinner ? Colors.amber.withOpacity(0.4) : Colors.black.withOpacity(0.1), 
                  blurRadius: 15, 
                  offset: const Offset(0, 4)
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        "#${t['id']} - ${t['title']}",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isWinner)
                      const Icon(Icons.workspace_premium, color: Colors.amber, size: 28),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  "Ended: $formattedTime",
                  style: const TextStyle(fontSize: 14, color: Color(0xFF6b7280)),
                ),
                
                const SizedBox(height: 16),
                
                // 🚀 PERSONAL RESULT GRID (Kills & Winnings)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFf8fafc),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFe2e8f0))
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildGridItem("My Kills", "🔫 ${myResult?['kills'] ?? 0}"),
                      Container(height: 30, width: 1, color: Colors.grey.shade300), // Divider
                      _buildGridItem("My Winnings", "🪙 ${myResult?['winnings'] ?? 0}", color: Colors.green.shade700),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Extra Grid (Winner Name, Map)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildGridItem("Match Winner", t['winner']?.toString().isNotEmpty == true ? t['winner'] : '-'),
                    _buildGridItem("Type", t['type']?.toString().toUpperCase() ?? '-'),
                    _buildGridItem("Map", t['map'] ?? '-'),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Chota widget grids banane ke liye
  Widget _buildGridItem(String title, String value, {Color? color}) {
    return Expanded(
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Color(0xFF9ca3af), fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 15, color: color ?? const Color(0xFF374151), fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}