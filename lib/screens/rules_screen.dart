import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:battle_master/screens/choose_slot_screen.dart'; // Apna ChooseSlotScreen ka path check karna

class RulesScreen extends StatefulWidget {
  final int tournamentId;

  const RulesScreen({super.key, required this.tournamentId});

  @override
  _RulesScreenState createState() => _RulesScreenState();
}

class _RulesScreenState extends State<RulesScreen> {
  bool _isLoading = true;
  bool _hasJoined = false;
  
  // Tournament Data
  Map<String, dynamic> _tData = {};
  String _roomId = '';
  String _roomPass = '';
  
  // User Slots Data
  List<Map<String, dynamic>> _mySlots = [];

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      // 1. Fetch Tournament details
      final tResponse = await Supabase.instance.client
          .from('tournaments')
          .select('*')
          .eq('id', widget.tournamentId)
          .single();

      // 2. Fetch User's joined slots
      final joinedResponse = await Supabase.instance.client
          .from('user_tournaments')
          .select('id, slot_number, position, user_ign')
          .eq('user_id', user.id)
          .eq('tournament_id', widget.tournamentId)
          .order('slot_number', ascending: true);

      setState(() {
        _tData = tResponse;
        _roomId = _tData['room_id']?.toString() ?? '';
        _roomPass = _tData['room_password']?.toString() ?? '';
        
        final slotsList = joinedResponse as List;
        _hasJoined = slotsList.isNotEmpty;
        _mySlots = List<Map<String, dynamic>>.from(slotsList);
        
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching details: $e");
      setState(() => _isLoading = false);
    }
  }

  // Text copy karne ka function
  void _copyToClipboard(String text, String type) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("✅ $type Copied!"), backgroundColor: Colors.green),
    );
  }

  // IGN Edit Logic
  Future<void> _editIGN(int index, int recordId, String currentIgn) async {
    TextEditingController ignController = TextEditingController(text: currentIgn);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1f2937),
        title: const Text("Edit your IGN", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: ignController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF374151),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFfacc15)),
            onPressed: () => Navigator.pop(context, ignController.text.trim()),
            child: const Text("SAVE", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != currentIgn) {
      try {
        // Update database
        await Supabase.instance.client
            .from('user_tournaments')
            .update({'user_ign': result})
            .eq('id', recordId);

        // Update UI locally
        setState(() {
          _mySlots[index]['user_ign'] = result;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ IGN Updated!"), backgroundColor: Colors.green));
      } catch (e) {
        print("Update error: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF111827),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFfacc15))),
      );
    }

    bool roomSet = _roomId.isNotEmpty && _roomPass.isNotEmpty;
    int totalSlots = _tData['slots'] ?? 0;
    int filledSlots = _tData['filled'] ?? 0;
    bool isFull = filledSlots >= totalSlots;

    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1f2937),
        title: Text(_tData['title'] ?? "Match Details", style: const TextStyle(color: Colors.white, fontSize: 18)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Banner Image
            if (_tData['image_url'] != null)
              Image.network(_tData['image_url'], width: double.infinity, height: 180, fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(height: 180, color: Colors.grey.shade800, child: const Icon(Icons.image, size: 50, color: Colors.grey)),
              ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ==========================================
                  // 2. BIG & BOLD MATCH INFO BLOCKS (FIXED!)
                  // ==========================================
                  Text("Match Info", style: TextStyle(color: Colors.grey.shade400, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      // Reusable fixed logic
                      _buildStylizedDataBlock(Icons.groups, "Team", _tData['type']?.toString().toUpperCase() ?? 'SOLO', Colors.white),
                      _buildStylizedDataBlock(Icons.monetization_on, "Entry Fee", "🪙 ${_tData['entry_fee'] ?? 0}", const Color(0xFFfacc15)), // Gold coin
                      _buildStylizedDataBlock(Icons.map, "Map", _tData['map'] ?? 'BERMUDA', Colors.white),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // ==========================================
                  // 3. BIG & BOLD PRIZE BLOCKS (FIXED!)
                  // ==========================================
                  Text("Prize Details", style: TextStyle(color: Colors.grey.shade400, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildStylizedDataBlock(Icons.emoji_events, "Prize Pool", "🪙 ${_tData['prize_pool'] ?? 0}", const Color(0xFFfacc15)),
                      const SizedBox(width: 12),
                      _buildStylizedDataBlock(Icons.ads_click, "Per Kill", "🪙 ${_tData['per_kill'] ?? 0}", const Color(0xFFfacc15)),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // ==========================================
                  // 4. DYNAMIC SECTION: Only if User Joined
                  // ==========================================
                  if (_hasJoined) ...[
                    const Divider(color: Color(0xFF374151), thickness: 2),
                    const SizedBox(height: 15),
                    
                    // A. Room ID & Pass Section (Show only if Room is set)
                    if (roomSet) ...[
                      const Text("Room Details", style: TextStyle(color: Color(0xFFfacc15), fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: const Color(0xFF1f2937), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFfacc15), width: 1.5), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 8, offset: const Offset(0, 4))]),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Room ID: $_roomId", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                IconButton(onPressed: () => _copyToClipboard(_roomId, "Room ID"), icon: const Icon(Icons.copy, color: Colors.green, size: 24), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                              ],
                            ),
                            const Divider(color: Colors.grey, thickness: 1),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Password: $_roomPass", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                IconButton(onPressed: () => _copyToClipboard(_roomPass, "Password"), icon: const Icon(Icons.copy, color: Colors.green, size: 24), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // If room not set yet
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: const Color(0xFF374151), borderRadius: BorderRadius.circular(10)),
                        child: const Text("⏳ Room ID and Password will be updated here before the match starts.", style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.4), textAlign: TextAlign.center),
                      ),
                    ],
                    const SizedBox(height: 25),

                    // B. My Slots (IGN Table)
                    const Text("My Joined Slots", style: TextStyle(color: Color(0xFFfacc15), fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(color: const Color(0xFF1f2937), borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 5)]),
                      child: Column(
                        children: _mySlots.asMap().entries.map((entry) {
                          int idx = entry.key;
                          var slot = entry.value;
                          return ListTile(
                            leading: CircleAvatar(backgroundColor: const Color(0xFF374151), child: Text(slot['position'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                            title: Text("Slot ${slot['slot_number']}", style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
                            subtitle: Text(slot['user_ign'], style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            // ONLY show Edit Icon if Room is NOT set
                            trailing: !roomSet 
                                ? IconButton(icon: const Icon(Icons.edit, color: Colors.blue, size: 24), onPressed: () => _editIGN(idx, slot['id'], slot['user_ign']))
                                : const Icon(Icons.check_circle, color: Colors.green, size: 24),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 25),
                    const Divider(color: Color(0xFF374151), thickness: 2),
                    const SizedBox(height: 25),
                  ],

                  // 5. Rules Section
                  const Text("Rules & Regulations", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(color: const Color(0xFF1f2937), borderRadius: BorderRadius.circular(10)),
                    child: const Text(
                      "• Hacks or third-party apps are strictly prohibited.\n\n"
                      "• Teaming up in Solo matches will lead to an instant ban.\n\n"
                      "• Room ID and Password will be provided 10 minutes before the match time.\n\n"
                      "• Ensure you join the correct slot, otherwise you will be kicked.",
                      style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.6),
                    ),
                  ),
                  const SizedBox(height: 100), // Bottom padding for fixed bar
                ],
              ),
            ),
          ],
        ),
      ),

      // ==========================================
      // 6. BOTTOM FIXED ACTION BAR
      // ==========================================
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(18),
        decoration: const BoxDecoration(
          color: Color(0xFF1f2937),
          border: Border(top: BorderSide(color: Color(0xFF374151), width: 1.5)),
        ),
        child: SizedBox(
          height: 55,
          child: _hasJoined
              ? ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF374151), disabledBackgroundColor: const Color(0xFF374151), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  onPressed: null, // Disabled
                  child: const Text("ALREADY JOINED", style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.bold)),
                )
              : isFull
                  ? ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF374151), disabledBackgroundColor: const Color(0xFF374151), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      onPressed: null, // Disabled
                      child: const Text("MATCH FULL", style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.bold)),
                    )
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563eb), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), // Blue Join button
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ChooseSlotScreen(tournamentId: widget.tournamentId)),
                        ).then((_) => _fetchDetails()); // Refresh if user comes back after joining
                      },
                      child: const Text("JOIN NOW", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
        ),
      ),
    );
  }

  // ==========================================
  // 🛠️ Custom BIG & BOLD Data Block Widget
  // ==========================================
  Widget _buildStylizedDataBlock(IconData icon, String label, String value, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: const Color(0xFF374151), borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))]),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: accentColor, size: 24), // Bolder icon
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 3),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), // Big bold value
            ],
          ),
        ],
      ),
    );
  }
}