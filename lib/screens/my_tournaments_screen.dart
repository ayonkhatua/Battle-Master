import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyTournamentsScreen extends StatefulWidget {
  const MyTournamentsScreen({super.key});

  @override
  _MyTournamentsScreenState createState() => _MyTournamentsScreenState();
}

class _MyTournamentsScreenState extends State<MyTournamentsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _myTournaments = [];

  @override
  void initState() {
    super.initState();
    _fetchMyTournaments();
  }

  Future<void> _fetchMyTournaments() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (userId == null) {
      // Agar user login nahi hai, toh wapas bhej do (jaise PHP mein header location tha)
      return;
    }

    try {
      // Supabase mein JOIN lagane ka tareeka
      // Hum 'user_tournaments' se data le rahe hain aur sath mein 'tournaments' table ka data bhi fetch kar rahe hain
      final response = await Supabase.instance.client
          .from('user_tournaments')
          .select('''
            id,
            tournaments (
              name,
              game,
              status
            )
          ''')
          .eq('user_id', userId)
          .order('id', ascending: false); // DESC order jaise query mein tha

      // Data ko list mein set karna
      setState(() {
        _myTournaments = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching my tournaments: $e");
      setState(() => _isLoading = false);
    }
  }

  // Status ke hisaab se color return karne ka function
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'live':
        return Colors.redAccent;
      case 'upcoming':
        return Colors.amber; // Yellow
      case 'completed':
        return Colors.greenAccent;
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827), // Tailwind ka bg-gray-900
      appBar: AppBar(
        backgroundColor: const Color(0xFF1f2937), // Dark header
        title: Row(
          children: [
            Icon(Icons.sports_esports, color: Colors.white), // gamepad icon
            SizedBox(width: 10),
            Text(
              "My Tournaments",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _myTournaments.isEmpty
              ? _buildEmptyState()
              : _buildList(),
    );
  }

  // Agar user ne koi tournament join nahi kiya hai
  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        "You haven’t joined any tournaments yet.",
        style: TextStyle(color: Colors.grey, fontSize: 16),
      ),
    );
  }

  // Tournament ki list build karna
  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _myTournaments.length,
      itemBuilder: (context, index) {
        final item = _myTournaments[index];
        // Kyunki humne join kiya hai, data 'tournaments' key ke andar aayega
        final tournamentData = item['tournaments']; 
        
        // Safety check agar tournament delete ho gaya ho par record reh gaya ho
        if (tournamentData == null) return const SizedBox.shrink();

        final name = tournamentData['name'] ?? 'Unknown';
        final game = tournamentData['game'] ?? 'Unknown';
        final status = tournamentData['status'] ?? 'completed';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1f2937), // Tailwind ka bg-gray-800
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Name aur Game Name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      game,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              
              // Status Indicator (Live, Upcoming, Completed)
              Container(
                margin: const EdgeInsets.only(left: 10),
                child: Text(
                  status.toUpperCase(), // Text uppercase karne ke liye
                  style: TextStyle(
                    color: _getStatusColor(status),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}