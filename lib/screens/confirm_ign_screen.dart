import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ConfirmIGNScreen extends StatefulWidget {
  final int tournamentId;
  final List<String> selectedSlots; // Example: ['1-A', '1-B', '2-A']

  const ConfirmIGNScreen({
    super.key,
    required this.tournamentId,
    required this.selectedSlots,
  });

  @override
  _ConfirmIGNScreenState createState() => _ConfirmIGNScreenState();
}

class _ConfirmIGNScreenState extends State<ConfirmIGNScreen> {
  bool _isLoading = true;
  bool _isProcessing = false;
  int _userWallet = 0;
  int _entryFee = 0;
  int _totalFee = 0;

  // Har ek slot ke liye uski IGN store karne ki list
  final List<Map<String, dynamic>> _slotsData = [];

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      // 1. Fetch User Wallet
      final userRes = await Supabase.instance.client
          .from('users')
          .select('wallet_balance')
          .eq('id', user.id)
          .single();

      // 2. Fetch Tournament Entry Fee
      final tRes = await Supabase.instance.client
          .from('tournaments')
          .select('entry_fee')
          .eq('id', widget.tournamentId)
          .single();

      _userWallet = userRes['wallet_balance'] ?? 0;
      _entryFee = tRes['entry_fee'] ?? 0;
      _totalFee = _entryFee * widget.selectedSlots.length;

      // 3. Prepare Slots Data based on selected slots
      for (int i = 0; i < widget.selectedSlots.length; i++) {
        String slotStr = widget.selectedSlots[i];
        String number = slotStr;
        String position = 'A';

        if (slotStr.contains('-')) {
          var parts = slotStr.split('-');
          number = parts[0];
          position = parts[1];
        }

        _slotsData.add({
          'slot_number': int.parse(number),
          'position': position,
          'ign': 'Player ${i + 1}', // Default IGN
        });
      }

      setState(() => _isLoading = false);
    } catch (e) {
      print("Error fetching details: $e");
      setState(() => _isLoading = false);
    }
  }

  // IGN Edit karne ke liye ek Popup Dialog (PHP ke prompt jaisa)
  Future<void> _editIGN(int index) async {
    TextEditingController ignController = TextEditingController(text: _slotsData[index]['ign']);

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1f2937),
          title: const Text("Enter your IGN", style: TextStyle(color: Colors.white)),
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
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text("CANCEL", style: TextStyle(color: Colors.grey))
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFfacc15)),
              onPressed: () => Navigator.pop(context, ignController.text.trim()),
              child: const Text("SAVE", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _slotsData[index]['ign'] = result;
      });
    }
  }

  // PHP ke join_process.php ka logic yahan aayega
  Future<void> _processJoin() async {
    if (_userWallet < _totalFee) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Not enough coins!"), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      // 1. Deduct wallet balance
      final newBalance = _userWallet - _totalFee;
      await Supabase.instance.client
          .from('users')
          .update({'wallet_balance': newBalance})
          .eq('id', userId);

      // 2. Insert slots into user_tournaments table
      for (var slot in _slotsData) {
        await Supabase.instance.client.from('user_tournaments').insert({
          'user_id': userId,
          'tournament_id': widget.tournamentId,
          'slot_no': slot['slot_number'],
          'position': slot['position'],
          'ign': slot['ign'],
        });
      }

      // 3. Create a transaction record (optional but good for history)
      await Supabase.instance.client.from('transactions').insert({
        'user_id': userId,
        'amount': _totalFee,
        'type': 'withdraw', // withdraw from wallet
        'txn_ref': 'JOIN_T_${widget.tournamentId}',
        'status': 'success',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Match Joined Successfully!"), backgroundColor: Colors.green),
      );

      // TODO: Wapas Home Screen bhej do
      // Navigator.popUntil(context, (route) => route.isFirst);

    } catch (e) {
      print("Join error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Error joining match."), backgroundColor: Colors.redAccent),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827), // Dark background
      appBar: AppBar(
        backgroundColor: const Color(0xFF1f2937),
        title: const Text("Confirm IGN", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFfacc15)))
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Wallet Display
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.monetization_on, color: Color(0xFFfacc15), size: 24),
                        const SizedBox(width: 6),
                        Text(
                          "$_userWallet Coins",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Selected Slots List
                  Expanded(
                    child: ListView.builder(
                      itemCount: _slotsData.length,
                      itemBuilder: (context, index) {
                        final slot = _slotsData[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 15),
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFdc2626), // Tumhara Red Box
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))],
                          ),
                          child: Row(
                            children: [
                              Text(
                                "Slot ${slot['slot_number']} - Position ${slot['position']}",
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                              ),
                              const Spacer(),
                              Text(
                                slot['ign'],
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 10),
                              GestureDetector(
                                onTap: () => _editIGN(index),
                                child: const Icon(Icons.edit, color: Color(0xFFfacc15), size: 20),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // Join Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563eb),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _isProcessing ? null : _processJoin,
                      child: _isProcessing
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(
                              "JOIN (Pay $_totalFee Coins)",
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}