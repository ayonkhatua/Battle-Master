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

  // EFFICIENT & FIXED: Ab ye RPC use kar raha hai
  Future<List<Map<String, dynamic>>> _fetchStatistics() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw Exception("User not logged in");
    }

    try {
      // RPC (Remote Procedure Call) to the Supabase function
      final response = await Supabase.instance.client
          .rpc('get_user_statistics', params: {'p_user_id': user.id});

      // RPC se mila data already ek list of maps hota hai
      final List<Map<String, dynamic>> matches = (response as List).map((item) {
        final data = item as Map<String, dynamic>;
        String timeString = data['start_time'] ?? '';
        String formattedTime = timeString.isNotEmpty
            ? DateFormat('dd/MM/yy hh:mm a').format(DateTime.parse(timeString))
            : 'Unknown Time';
            
        return {
          'title': data['title'] ?? 'Unknown Match',
          'datetime': formattedTime,
          'paid': data['total_paid'] ?? 0,
          'won': data['total_won'] ?? 0,
        };
      }).toList();

      return matches;

    } catch (e) {
      print("Error fetching statistics via RPC: $e");
      // Agar error aaye to khali list return karo
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
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
          child: Container(color: const Color(0xFFfacc15), height: 2.0),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _statisticsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFfacc15)));
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.white)));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text("No tournament results available yet.", style: TextStyle(color: Color(0xFF9ca3af), fontSize: 16)),
            );
          }

          final matches = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1e293b),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15)],
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
                    ...List.generate(matches.length, (index) {
                      final m = matches[index];
                      final isEven = index.isEven;

                      return Container(
                        color: isEven ? const Color(0xFF111827) : const Color(0xFF1e293b),
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: Color(0xFF334155), width: 1)),
                        ),
                        child: Row(
                          children: [
                            Expanded(flex: 1, child: Text("${index + 1}", textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 12))),
                            Expanded(flex: 3, child: Text(m['title'] ?? '', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 12))),
                            Expanded(flex: 3, child: Text(m['datetime'] ?? '', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 12))),
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
          );
        },
      ),
    );
  }
}