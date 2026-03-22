import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class OngoingScreen extends StatefulWidget {
  const OngoingScreen({super.key});

  @override
  _OngoingScreenState createState() => _OngoingScreenState();
}

class _OngoingScreenState extends State<OngoingScreen> {
  bool _isLoading = true;
  
  // Data ko store karne ke liye Map (Mode -> List of Tournaments)
  // Jaise: {'Battle Royale': [t1, t2], 'Clash Squad': [t3]}
  Map<String, List<Map<String, dynamic>>> _groupedTournaments = {};

  @override
  void initState() {
    super.initState();
    _fetchOngoingTournaments();
  }

  Future<void> _fetchOngoingTournaments() async {
    try {
      // Fetch only 'ongoing' tournaments, ordered by time
      final response = await Supabase.instance.client
          .from('tournaments')
          .select()
          .eq('status', 'ongoing')
          .order('time', ascending: false);

      // Dart side Grouping (PHP ke $grouped = [] jaisa)
      Map<String, List<Map<String, dynamic>>> tempGrouped = {};

      for (var row in response as List<dynamic>) {
        String mode = row['mode']?.toString().toUpperCase() ?? 'UNKNOWN MODE';
        
        if (!tempGrouped.containsKey(mode)) {
          tempGrouped[mode] = [];
        }
        tempGrouped[mode]!.add(row as Map<String, dynamic>);
      }

      setState(() {
        _groupedTournaments = tempGrouped;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching ongoing tournaments: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f172a), // Dark theme
      appBar: AppBar(
        backgroundColor: const Color(0xFF1e293b),
        title: const Text("Ongoing Tournaments", style: TextStyle(color: Colors.white, fontSize: 18)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFfacc15)))
          : _groupedTournaments.isEmpty
              ? const Center(
                  child: Text(
                    "⚠️ No ongoing tournaments right now.",
                    style: TextStyle(color: Color(0xFF9ca3af), fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _groupedTournaments.length,
                  itemBuilder: (context, index) {
                    // Extract Mode and its Tournaments List
                    String mode = _groupedTournaments.keys.elementAt(index);
                    List<Map<String, dynamic>> modeTournaments = _groupedTournaments[mode]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Mode Title (e.g., BATTLE ROYALE)
                        Container(
                          margin: EdgeInsets.only(bottom: 15, top: index == 0 ? 0 : 20),
                          padding: const EdgeInsets.only(bottom: 6),
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: Color(0xFF334155), width: 2)),
                          ),
                          child: Text(
                            mode,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF38bdf8)), // Blue text
                          ),
                        ),

                        // List of tournaments under this mode
                        ...modeTournaments.map((t) => _buildCard(t)),
                      ],
                    );
                  },
                ),
    );
  }

  Widget _buildCard(Map<String, dynamic> t) {
    String timeString = t['time'] ?? '';
    String formattedTime = timeString.isNotEmpty
        ? DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.parse(timeString))
        : 'Unknown';

    return GestureDetector(
      onTap: () {
        // TODO: Navigate to Rules screen
        // Navigator.push(context, MaterialPageRoute(builder: (_) => RulesScreen(tid: t['id'])));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF1e293b),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // Image (Agar URL hai toh dikhao, nahi toh placeholder)
            Container(
              height: 160,
              width: double.infinity,
              color: Colors.grey[800],
              child: t['image_url'] != null
                  ? Image.network(t['image_url'], fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.image, color: Colors.white54, size: 50))
                  : const Icon(Icons.image, color: Colors.white54, size: 50),
            ),
            
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "#${t['id']} - ${t['title']}",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFfacc15)),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Started: $formattedTime",
                    style: const TextStyle(fontSize: 12, color: Color(0xFF9ca3af)),
                  ),
                  const SizedBox(height: 15),

                  // Details Grid
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildGridItem("Prize", "💰 ${t['prize_pool']}"),
                      _buildGridItem("Per Kill", "💰 ${t['per_kill']}"),
                      _buildGridItem("Entry", "💰 ${t['entry_fee']}"),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // Extra Details Grid
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildGridItem("Type", t['type'] ?? '-'),
                      _buildGridItem("Version", t['version'] ?? '-'),
                      _buildGridItem("Map", t['map'] ?? '-'),
                    ],
                  ),
                  
                  const SizedBox(height: 15),

                  // ONGOING Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFf59e0b), // Amber color
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      "ONGOING",
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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