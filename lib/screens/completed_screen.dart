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
      // 🌟 Supabase '!inner' Join Magic 🌟
      // Ye query tournaments table se data layegi, lekin sirf wahi jahan 
      // user_tournaments mein is user ki entry ho, aur status 'completed' ho.
      final response = await Supabase.instance.client
          .from('tournaments')
          .select('*, user_tournaments!inner(user_id)')
          .eq('user_tournaments.user_id', userId)
          .eq('status', 'completed')
          .order('time', ascending: false);

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
          "🏆 COMPLETED MATCHES",
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
        "No completed tournaments yet.",
        style: TextStyle(color: Color(0xFF94a3b8), fontSize: 17),
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
      itemCount: _completedTournaments.length,
      itemBuilder: (context, index) {
        final t = _completedTournaments[index];

        // PHP Logic: End time check karna, warna start time dikhana
        String timeString = t['end_time'] ?? t['time'] ?? '';
        String formattedTime = '';
        if (timeString.isNotEmpty) {
          formattedTime = DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.parse(timeString));
        }

        return GestureDetector(
          onTap: () {
            // TODO: Navigate to Result Details Screen
            // Navigator.push(context, MaterialPageRoute(builder: (context) => ResultDetailsScreen(tournamentId: t['id'])));
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white, // White card design
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(color: Colors.white.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 4))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "#${t['id']} - ${t['title']} (Result)",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                ),
                const SizedBox(height: 5),
                Text(
                  "Ended: $formattedTime",
                  style: const TextStyle(fontSize: 14, color: Color(0xFF6b7280)),
                ),
                
                const SizedBox(height: 16),
                
                // Details Grid (Winner, Prize, Per Kill)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildGridItem("Winner", t['winner']?.toString().isNotEmpty == true ? t['winner'] : '-'),
                    _buildGridItem("Prize", "💰 ${t['prize_pool']}"),
                    _buildGridItem("Per Kill", "💰 ${t['per_kill']}"),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Extra Grid (Type, Version, Map)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildGridItem("Type", t['type'] ?? '-'),
                    _buildGridItem("Version", t['version'] ?? '-'),
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
  Widget _buildGridItem(String title, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 13, color: Color(0xFF9ca3af), fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 15, color: Color(0xFF374151), fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}