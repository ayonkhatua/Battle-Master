import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  _StatisticsScreenState createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _matches = [];

  @override
  void initState() {
    super.initState();
    _fetchStatistics();
  }

  Future<void> _fetchStatistics() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      // Supabase Data Fetching (Group By Logic)
      // Note: Supabase ke Dart SDK mein direct 'GROUP BY' SQL query nahi hoti.
      // Isliye hum RPC (Remote Procedure Call) ya raw query ka use kar sakte hain.
      // Lekin simpler approach ke liye, agar user ka data bohot zyada nahi hai, 
      // toh hum saara data laake Dart mein group kar sakte hain.
      // Yahan main Dart-side grouping dikha raha hoon.

      final response = await Supabase.instance.client
          .from('statistics')
          .select('tournament_id, title, start_time, paid, won')
          .eq('user_id', user.id)
          .order('start_time', ascending: false);

      // Dart side grouping (to replicate PHP's SUM and GROUP BY)
      Map<int, Map<String, dynamic>> groupedData = {};

      for (var row in response as List<dynamic>) {
        int tId = row['tournament_id'] ?? 0;
        
        if (!groupedData.containsKey(tId)) {
          groupedData[tId] = {
            'title': row['title'] ?? 'Unknown Match',
            'start_time': row['start_time'],
            'total_paid': 0,
            'total_won': 0,
          };
        }
        
        groupedData[tId]!['total_paid'] += (row['paid'] as num?)?.toInt() ?? 0;
        groupedData[tId]!['total_won'] += (row['won'] as num?)?.toInt() ?? 0;
      }

      // Map ko List mein convert karna
      List<Map<String, dynamic>> formattedMatches = groupedData.values.map((data) {
        String timeString = data['start_time'] ?? '';
        String formattedTime = timeString.isNotEmpty
            ? DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.parse(timeString))
            : 'Unknown Time';

        return {
          'title': data['title'],
          'datetime': formattedTime,
          'paid': data['total_paid'],
          'won': data['total_won'],
        };
      }).toList();

      setState(() {
        _matches = formattedMatches;
        _isLoading = false;
      });
      
    } catch (e) {
      print("Error fetching statistics: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f172a), // Dark theme
      appBar: AppBar(
        backgroundColor: const Color(0xFF1e293b),
        title: const Text(
          "My Statistics",
          style: TextStyle(color: Color(0xFFfacc15), fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2.0),
          child: Container(color: const Color(0xFFfacc15), height: 2.0), // Bottom border jaisa CSS mein tha
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFfacc15)))
          : _matches.isEmpty
              ? const Center(
                  child: Text(
                    "No tournament results available yet.",
                    style: TextStyle(color: Color(0xFF9ca3af), fontSize: 16),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1e293b),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15)
                        ],
                      ),
                      child: Column(
                        children: [
                          // Table Header
                          Container(
                            color: const Color(0xFF0f172a),
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                            child: const Row(
                              children: [
                                Expanded(flex: 1, child: Text("#", textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFfacc15), fontWeight: FontWeight.bold, fontSize: 13))),
                                Expanded(flex: 3, child: Text("Match Info", textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFfacc15), fontWeight: FontWeight.bold, fontSize: 13))),
                                Expanded(flex: 3, child: Text("Start Time", textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFfacc15), fontWeight: FontWeight.bold, fontSize: 13))),
                                Expanded(flex: 2, child: Text("Paid", textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFfacc15), fontWeight: FontWeight.bold, fontSize: 13))),
                                Expanded(flex: 2, child: Text("Won", textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFfacc15), fontWeight: FontWeight.bold, fontSize: 13))),
                              ],
                            ),
                          ),

                          // Table Rows
                          ...List.generate(_matches.length, (index) {
                            final m = _matches[index];
                            final isEven = index.isEven;

                            return Container(
                              color: isEven ? const Color(0xFF111827) : const Color(0xFF1e293b),
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                              decoration: const BoxDecoration(
                                border: Border(bottom: BorderSide(color: Color(0xFF334155), width: 1)),
                              ),
                              child: Row(
                                children: [
                                  // Serial Number
                                  Expanded(flex: 1, child: Text("${index + 1}", textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 12))),
                                  
                                  // Match Title
                                  Expanded(flex: 3, child: Text(m['title'], textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 12))),
                                  
                                  // Start Time
                                  Expanded(flex: 3, child: Text(m['datetime'], textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 12))),
                                  
                                  // Paid Coins
                                  Expanded(
                                    flex: 2,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.monetization_on, color: Color(0xFFfacc15), size: 14),
                                        const SizedBox(width: 4),
                                        Text("${m['paid']}", style: const TextStyle(color: Color(0xFFfacc15), fontWeight: FontWeight.bold, fontSize: 12)),
                                      ],
                                    ),
                                  ),

                                  // Won Coins
                                  Expanded(
                                    flex: 2,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.monetization_on, color: Color(0xFF22c55e), size: 14),
                                        const SizedBox(width: 4),
                                        Text("${m['won']}", style: const TextStyle(color: Color(0xFF22c55e), fontWeight: FontWeight.bold, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}