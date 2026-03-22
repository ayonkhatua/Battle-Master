import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myapp/screens/confirm_ign_screen.dart'; // Apna sahi path dalna

class ChooseSlotScreen extends StatefulWidget {
  final int tournamentId;

  const ChooseSlotScreen({super.key, required this.tournamentId});

  @override
  _ChooseSlotScreenState createState() => _ChooseSlotScreenState();
}

class _ChooseSlotScreenState extends State<ChooseSlotScreen> {
  bool _isLoading = true;
  String _type = 'solo';
  int _totalSlots = 0;
  
  // Booked slots ko store karne ke liye map: {slot_no: ['A', 'B']}
  Map<int, List<String>> _bookedSlots = {};
  
  // User ne jo slots select kiye hain unki list: ['1-A', '2-C']
  final Set<String> _selectedSlots = {};

  @override
  void initState() {
    super.initState();
    _fetchSlotData();
  }

  Future<void> _fetchSlotData() async {
    try {
      // 1. Fetch Tournament details
      final tRes = await Supabase.instance.client
          .from('tournaments')
          .select('type, slots')
          .eq('id', widget.tournamentId)
          .single();

      _type = tRes['type']?.toString().toLowerCase() ?? 'solo';
      _totalSlots = tRes['slots'] ?? 0;

      // 2. Fetch Booked Slots
      final bookedRes = await Supabase.instance.client
          .from('user_tournaments')
          .select('slot_no, position') // Dhyan dein: DB column name slot_no hai
          .eq('tournament_id', widget.tournamentId);

      Map<int, List<String>> tempBooked = {};
      for (var row in bookedRes as List<dynamic>) {
        int slotNo = row['slot_no'];
        String pos = row['position'];
        
        if (!tempBooked.containsKey(slotNo)) {
          tempBooked[slotNo] = [];
        }
        tempBooked[slotNo]!.add(pos);
      }

      setState(() {
        _bookedSlots = tempBooked;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching slots: $e");
      setState(() => _isLoading = false);
    }
  }

  // Next page par jane ka logic
  void _goToNext() {
    if (_selectedSlots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Please select at least one slot!"), backgroundColor: Colors.orange),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConfirmIGNScreen(
          tournamentId: widget.tournamentId,
          selectedSlots: _selectedSlots.toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Columns (Headers) decide karna
    List<String> headers = ['A'];
    if (_type == 'duo') headers = ['A', 'B'];
    if (_type == 'squad') headers = ['A', 'B', 'C', 'D'];

    return Scaffold(
      backgroundColor: const Color(0xFF111827), // Dark Theme
      appBar: AppBar(
        backgroundColor: const Color(0xFF1f2937),
        title: Text("Choose Slot (${_type.toUpperCase()})", style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFfacc15)))
          : Column(
              children: [
                const SizedBox(height: 20),
                const Text("Select Your Slots", style: TextStyle(color: Color(0xFFfacc15), fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

                // Table Layout
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Table(
                      border: TableBorder.all(color: const Color(0xFF374151), width: 1),
                      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                      children: [
                        // 1. Table Header Row
                        TableRow(
                          decoration: const BoxDecoration(color: Color(0xFF1f2937)),
                          children: [
                            const Padding(padding: EdgeInsets.all(12), child: Text("Slot", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                            ...headers.map((h) => Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(h, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                )),
                          ],
                        ),

                        // 2. Data Rows (Loops from 1 to totalSlots)
                        for (int i = 1; i <= _totalSlots; i++)
                          TableRow(
                            children: [
                              // Slot Number
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text("$i", textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
                              ),
                              // Checkboxes for each position
                              ...headers.map((pos) {
                                bool isBooked = _bookedSlots.containsKey(i) && _bookedSlots[i]!.contains(pos);
                                String slotKey = "$i-$pos";
                                bool isSelected = _selectedSlots.contains(slotKey);

                                return Center(
                                  child: Checkbox(
                                    value: isBooked ? true : isSelected,
                                    // Custom styling taaki booked wala red dikhe aur disabled rahe
                                    fillColor: WidgetStateProperty.resolveWith((states) {
                                      if (isBooked) return Colors.red; // Booked slots (Red)
                                      if (states.contains(WidgetState.selected)) return const Color(0xFF2563eb); // Selected by user (Blue)
                                      return Colors.transparent; // Unselected
                                    }),
                                    checkColor: Colors.white,
                                    side: const BorderSide(color: Colors.grey),
                                    onChanged: isBooked
                                        ? null // Disabled agar booked hai
                                        : (bool? val) {
                                            setState(() {
                                              if (val == true) {
                                                _selectedSlots.add(slotKey);
                                              } else {
                                                _selectedSlots.remove(slotKey);
                                              }
                                            });
                                          },
                                  ),
                                );
                              }),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),

                // Next Button
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563eb),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _goToNext,
                      child: const Text("NEXT", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}