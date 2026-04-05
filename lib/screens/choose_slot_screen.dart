import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:battle_master/screens/confirm_ign_screen.dart'; 

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
  int _entryFee = 0; 
  int _maxSlotsAllowed = 1;
  int _myAlreadyBookedCount = 0;
  
  Map<int, List<String>> _bookedSlots = {};
  final Set<String> _selectedSlots = {};
  Set<String> _lockedSlots = {}; 
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _fetchSlotData();
  }
  
  @override
  void dispose() {
    _releaseMyLocks();
    super.dispose();
  }

  Future<void> _fetchSlotData() async {
    try {
      // 1. Fetch Tournament details (Image url hata diya gaya hai)
      final tRes = await Supabase.instance.client
          .from('tournaments')
          .select('type, slots, entry_fee') 
          .eq('id', widget.tournamentId)
          .single();

      _type = tRes['type']?.toString().toLowerCase() ?? 'solo';
      _totalSlots = tRes['slots'] ?? 0;
      _entryFee = int.tryParse(tRes['entry_fee'].toString()) ?? 0; 
      
      if (_type == 'solo') {
        _maxSlotsAllowed = 1;
      } else if (_type == 'duo') _maxSlotsAllowed = 2;
      else if (_type == 'squad') _maxSlotsAllowed = 4;

      // 2. Fetch Booked Slots
      final bookedRes = await Supabase.instance.client
          .from('user_tournaments')
          .select('slot_number, position, user_id')
          .eq('tournament_id', widget.tournamentId);

      Map<int, List<String>> tempBooked = {};
      final myUserId = Supabase.instance.client.auth.currentUser?.id;
      int tempMyBooked = 0;

      for (var row in bookedRes as List<dynamic>) {
        int slotNo = row['slot_number'];
        String pos = row['position'];
        String? rUserId = row['user_id'];
        
        if (rUserId != null && rUserId == myUserId) {
          tempMyBooked++; 
        }
        
        if (!tempBooked.containsKey(slotNo)) {
          tempBooked[slotNo] = [];
        }
        tempBooked[slotNo]!.add(pos);
      }

      // 3. Fetch Locked Slots
      final threeMinsAgo = DateTime.now().toUtc().subtract(const Duration(minutes: 3)).toIso8601String();
      final locksRes = await Supabase.instance.client
          .from('slot_locks')
          .select('slot_key, user_id')
          .eq('tournament_id', widget.tournamentId)
          .gte('locked_at', threeMinsAgo);

      Set<String> tempLocked = {};
      for (var row in locksRes as List<dynamic>) {
        if (row['user_id'] != myUserId) {
          tempLocked.add(row['slot_key']); 
        }
      }

      setState(() {
        _bookedSlots = tempBooked;
        _lockedSlots = tempLocked;
        _myAlreadyBookedCount = tempMyBooked;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching slots: $e");
      setState(() => _isLoading = false);
    }
  }

  void _releaseMyLocks() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      Supabase.instance.client
          .from('slot_locks')
          .delete()
          .eq('tournament_id', widget.tournamentId)
          .eq('user_id', userId);
    }
  }

  Future<void> _goToNext() async {
    if (_selectedSlots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Please select at least one slot!"), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isProcessing = true);
    final userId = Supabase.instance.client.auth.currentUser!.id;
    final threeMinsAgo = DateTime.now().toUtc().subtract(const Duration(minutes: 3)).toIso8601String();

    try {
      await Supabase.instance.client
          .from('slot_locks')
          .delete()
          .eq('tournament_id', widget.tournamentId)
          .lt('locked_at', threeMinsAgo);

      final existingLocks = await Supabase.instance.client
          .from('slot_locks')
          .select('slot_key, user_id')
          .eq('tournament_id', widget.tournamentId)
          .inFilter('slot_key', _selectedSlots.toList());

      bool conflict = false;
      for (var row in existingLocks) {
        if (row['user_id'] != userId) {
          conflict = true; break;
        }
      }

      if (conflict) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Slot just taken!"), backgroundColor: Colors.orange));
        await _fetchSlotData();
        setState(() => _isProcessing = false);
        return;
      }

      await Supabase.instance.client.from('slot_locks').delete()
          .eq('tournament_id', widget.tournamentId).eq('user_id', userId);

      for (String slot in _selectedSlots) {
        await Supabase.instance.client.from('slot_locks').insert({
          'tournament_id': widget.tournamentId,
          'slot_key': slot,
          'user_id': userId,
          'locked_at': DateTime.now().toUtc().toIso8601String(),
        });
      }

      setState(() => _isProcessing = false);
    
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ConfirmJoinScreen(
            tournamentId: widget.tournamentId,
            selectedSlots: _selectedSlots.toList(),
            entryFee: _entryFee,
          ),
        ),
      );

      _releaseMyLocks();
      _fetchSlotData();

    } catch (e) {
      print("Locking error: $e");
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> headers = ['A'];
    if (_type == 'duo') headers = ['A', 'B'];
    if (_type == 'squad') headers = ['A', 'B', 'C', 'D'];

    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1f2937),
        title: Text("Choose Slot (${_type.toUpperCase()})", style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFfacc15)))
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        // Image section completely removed
                        const SizedBox(height: 30), // Thoda top spacing de diya taaki accha lage
                        const Text("Select Your Slots", style: TextStyle(color: Color(0xFFfacc15), fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),

                        // Table Section
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Table(
                            border: TableBorder.all(color: const Color(0xFF374151), width: 1),
                            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                            children: [
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

                              for (int i = 1; i <= _totalSlots; i++)
                                TableRow(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Text("$i", textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
                                    ),
                                    ...headers.map((pos) {
                                      bool isBooked = _bookedSlots.containsKey(i) && _bookedSlots[i]!.contains(pos);
                                      String slotKey = "$i-$pos";
                                      bool isLocked = _lockedSlots.contains(slotKey);
                                      bool isSelected = _selectedSlots.contains(slotKey);
                                      
                                      bool disabled = isBooked || isLocked;

                                      return Center(
                                        child: Checkbox(
                                          value: disabled ? true : isSelected,
                                          fillColor: WidgetStateProperty.resolveWith((states) {
                                            if (isBooked) return Colors.red;
                                            if (isLocked) return Colors.orange;
                                            if (states.contains(WidgetState.selected)) return const Color(0xFF2563eb);
                                            return Colors.transparent;
                                          }),
                                          checkColor: Colors.white,
                                          side: const BorderSide(color: Colors.grey),
                                          onChanged: disabled
                                              ? null 
                                              : (bool? val) {
                                                  setState(() {
                                                    if (val == true) {
                                                      if (_selectedSlots.length + _myAlreadyBookedCount >= _maxSlotsAllowed) {
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          SnackBar(content: Text("Max $_maxSlotsAllowed allowed!")),
                                                        );
                                                        return;
                                                      }
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
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // Button Section
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563eb),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _isProcessing ? null : _goToNext,
                        child: _isProcessing 
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text("JOIN", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}