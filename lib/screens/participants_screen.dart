import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ParticipantsScreen extends StatefulWidget {
  final int tournamentId; // PHP ke $_GET['tid'] ka replacement

  const ParticipantsScreen({super.key, required this.tournamentId});

  @override
  _ParticipantsScreenState createState() => _ParticipantsScreenState();
}

class _ParticipantsScreenState extends State<ParticipantsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _participants = [];

  @override
  void initState() {
    super.initState();
    _fetchParticipants();
  }

  Future<void> _fetchParticipants() async {
    try {
      // Supabase Query: user_tournaments table se data nikalna
      // NOTE: Maine pichli files ke hisaab se 'slot_no' use kiya hai. 
      // Agar tumhare database mein column ka naam 'slot_number' hai, toh ise change kar lena.
      final response = await Supabase.instance.client
          .from('user_tournaments')
          .select('slot_no, position, ign')
          .eq('tournament_id', widget.tournamentId)
          .order('slot_no', ascending: true)
          .order('position', ascending: true);

      setState(() {
        _participants = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching participants: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f172a), // Dark theme (PHP ka #111827 ke kareeb)
      appBar: AppBar(
        backgroundColor: const Color(0xFF1e293b),
        title: const Text(
          "Participants List",
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFfacc15)))
          : _participants.isEmpty
              ? const Center(
                  child: Text(
                    "No participants have joined yet.",
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
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          // Table Header
                          Container(
                            color: const Color(0xFF111827),
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                            child: const Row(
                              children: [
                                Expanded(flex: 1, child: Text("Slot", textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFfacc15), fontWeight: FontWeight.bold, fontSize: 14))),
                                Expanded(flex: 1, child: Text("Position", textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFfacc15), fontWeight: FontWeight.bold, fontSize: 14))),
                                Expanded(flex: 2, child: Text("IGN", textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFfacc15), fontWeight: FontWeight.bold, fontSize: 14))),
                              ],
                            ),
                          ),

                          // Table Rows
                          ...List.generate(_participants.length, (index) {
                            final p = _participants[index];
                            final isEven = index.isEven;

                            return Container(
                              color: isEven ? const Color(0xFF1e293b) : const Color(0xFF162033),
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                              decoration: const BoxDecoration(
                                border: Border(bottom: BorderSide(color: Color(0xFF334155), width: 1)),
                              ),
                              child: Row(
                                children: [
                                  // Slot Number
                                  Expanded(
                                    flex: 1, 
                                    child: Text("${p['slot_no'] ?? '-'}", textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 14))
                                  ),
                                  
                                  // Position (A, B, C, D)
                                  Expanded(
                                    flex: 1, 
                                    child: Text(p['position'] ?? '-', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 14))
                                  ),
                                  
                                  // IGN
                                  Expanded(
                                    flex: 2, 
                                    child: Text(p['ign'] ?? 'Unknown', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))
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