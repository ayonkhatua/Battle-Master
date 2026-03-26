import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class OngoingScreen extends StatefulWidget {
  final bool isMyMatches; // True from Home screen, False from Global
  const OngoingScreen({super.key, this.isMyMatches = false});

  @override
  _OngoingScreenState createState() => _OngoingScreenState();
}

class _OngoingScreenState extends State<OngoingScreen> {
  bool _isLoading = true;
  Map<String, List<Map<String, dynamic>>> _groupedTournaments = {};

  @override
  void initState() {
    super.initState();
    _fetchOngoingTournaments();
  }

  Future<void> _fetchOngoingTournaments() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    try {
      dynamic response;

      if (widget.isMyMatches && userId != null) {
        // PERSONAL MATCHES: Joined aur Result pending
        response = await Supabase.instance.client
            .from('tournaments')
            .select('*, user_tournaments!inner(user_id)')
            .eq('user_tournaments.user_id', userId)
            .neq('status', 'completed')
            .order('time', ascending: false);
      } else {
        // GLOBAL MATCHES: Result pending
        response = await Supabase.instance.client
            .from('tournaments')
            .select('*')
            .neq('status', 'completed')
            .order('time', ascending: false);
      }

      final now = DateTime.now();
      Map<String, List<Map<String, dynamic>>> tempGrouped = {};

      if (response != null) {
        for (var row in response as List<dynamic>) {
          DateTime matchTime = DateTime.tryParse(row['time'].toString()) ?? now;

          // ⏳ TIME LOGIC: Sirf wo dikhao jinka time nikal chuka hai (Ongoing/Live)
          if (!matchTime.isAfter(now)) {
            String mode = row['mode']?.toString().toUpperCase() ?? 'UNKNOWN';
            if (!tempGrouped.containsKey(mode)) tempGrouped[mode] = [];
            
            tempGrouped[mode]!.add({
              ...row as Map<String, dynamic>,
              'matchTime': matchTime,
            });
          }
        }
      }

      setState(() {
        _groupedTournaments = tempGrouped;
        _isLoading = false;
      });
    } catch (e) {
      print("Error: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1e293b),
        title: Text(widget.isMyMatches ? "My Ongoing Matches" : "All Ongoing Matches", style: const TextStyle(color: Colors.white, fontSize: 18)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFfacc15)))
          : _groupedTournaments.isEmpty
              ? Center(child: Text(widget.isMyMatches ? "⚠️ No ongoing matches for you." : "⚠️ No ongoing tournaments right now.", style: const TextStyle(color: Color(0xFF9ca3af), fontSize: 16)))
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _groupedTournaments.length,
                  itemBuilder: (context, index) {
                    String mode = _groupedTournaments.keys.elementAt(index);
                    List<Map<String, dynamic>> modeTournaments = _groupedTournaments[mode]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: EdgeInsets.only(bottom: 15, top: index == 0 ? 0 : 20),
                          padding: const EdgeInsets.only(bottom: 6),
                          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF334155), width: 2))),
                          child: Text(mode, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF38bdf8))),
                        ),
                        ...modeTournaments.map((t) => _buildCard(t)),
                      ],
                    );
                  },
                ),
    );
  }

  Widget _buildCard(Map<String, dynamic> t) {
    String formattedTime = DateFormat('dd/MM/yyyy hh:mm a').format(t['matchTime']);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(color: const Color(0xFF1e293b), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 8, offset: const Offset(0, 4))]),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            height: 160, width: double.infinity, color: Colors.grey[800],
            child: t['image_url'] != null ? Image.network(t['image_url'], fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.image, color: Colors.white54, size: 50)) : const Icon(Icons.image, color: Colors.white54, size: 50),
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("#${t['id']} - ${t['title']}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFfacc15))),
                const SizedBox(height: 5),
                Text("Started: $formattedTime", style: const TextStyle(fontSize: 12, color: Color(0xFF9ca3af))),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildGridItem("Prize", "💰 ${t['prize_pool']}"),
                    _buildGridItem("Per Kill", "💰 ${t['per_kill']}"),
                    _buildGridItem("Entry", "💰 ${t['entry_fee']}"),
                  ],
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFf59e0b), borderRadius: BorderRadius.circular(6)),
                  child: const Text("MATCH IS LIVE", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridItem(String title, String value) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 12, color: Colors.white70)),
      ],
    );
  }
}