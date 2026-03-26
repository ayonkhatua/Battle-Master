import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ConfirmJoinScreen extends StatefulWidget {
  final int tournamentId;
  final List<String> selectedSlots; // Example: ['28-A']
  final int entryFee;

  const ConfirmJoinScreen({
    super.key,
    required this.tournamentId,
    required this.selectedSlots,
    required this.entryFee,
  });

  @override
  _ConfirmJoinScreenState createState() => _ConfirmJoinScreenState();
}

class _ConfirmJoinScreenState extends State<ConfirmJoinScreen> {
  bool _isProcessing = false;
  int _userWallet = 0;
  final List<TextEditingController> _ignControllers = [];

  @override
  void initState() {
    super.initState();
    // Jitne slots hain, utne controllers banao
    for (var _ in widget.selectedSlots) {
      _ignControllers.add(TextEditingController());
    }
    _fetchWallet();
  }

  Future<void> _fetchWallet() async {
    final user = Supabase.instance.client.auth.currentUser;
    final res = await Supabase.instance.client.from('users').select('wallet_balance').eq('id', user!.id).single();
    setState(() { _userWallet = res['wallet_balance'] ?? 0; });
  }

  Future<void> _handleJoin() async {
    int totalFee = widget.entryFee * widget.selectedSlots.length;

    // 1. Validation
    if (_userWallet < totalFee) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("❌ Not enough balance!"), backgroundColor: Colors.red));
      return;
    }

    for (var controller in _ignControllers) {
      if (controller.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Please enter IGN for all slots!")));
        return;
      }
    }

    setState(() => _isProcessing = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;

      // 2. Deduct Money
      await Supabase.instance.client.from('users').update({'wallet_balance': _userWallet - totalFee}).eq('id', user!.id);

      // 3. Insert into user_tournaments
      for (int i = 0; i < widget.selectedSlots.length; i++) {
        var parts = widget.selectedSlots[i].split('-');
        await Supabase.instance.client.from('user_tournaments').insert({
          'user_id': user.id,
          'tournament_id': widget.tournamentId,
          'slot_number': int.parse(parts[0]),
          'position': parts[1],
          'user_ign': _ignControllers[i].text.trim(),
        });
      }

      // 4. Record Transaction
      await Supabase.instance.client.from('transactions').insert({
        'user_id': user.id,
        'amount': totalFee,
        'type': 'withdraw',
        'txn_ref': 'JOIN_${widget.tournamentId}_${DateTime.now().millisecondsSinceEpoch}',
        'status': 'success',
      });

      // 5. Update Filled Slots
      final tRes = await Supabase.instance.client.from('tournaments').select('filled').eq('id', widget.tournamentId).single();
      await Supabase.instance.client.from('tournaments').update({'filled': (tRes['filled'] ?? 0) + widget.selectedSlots.length}).eq('id', widget.tournamentId);

      // Success
      Navigator.popUntil(context, (route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Joined Successfully!"), backgroundColor: Colors.green));

    } catch (e) {
      print("Error: $e");
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalPayable = widget.entryFee * widget.selectedSlots.length;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: const Color(0xFF1a0633), title: const Text("Joining Match")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Top Balance Section (As per Screenshot)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Image.asset('assets/wallet_icon.png', height: 80), // Apna path check kar lena
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildBalanceRow("Your Current Balance :", "$_userWallet.00"),
                    _buildBalanceRow("Match Entry Fee Per Person :", "${widget.entryFee}"),
                    _buildBalanceRow("Total Payable Amount :", "$totalPayable", isTotal: true),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Table Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              color: const Color(0xFF1a0633),
              child: const Text("Selected Position", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),

            // Table Body
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                children: widget.selectedSlots.asMap().entries.map((entry) {
                  int idx = entry.key;
                  var parts = entry.value.split('-');
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: Row(
                      children: [
                        const Expanded(child: Text("Team 1", style: TextStyle(color: Colors.black))),
                        Expanded(child: Text(parts[0], textAlign: TextAlign.center, style: TextStyle(color: Colors.black))),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _ignControllers[idx],
                            decoration: const InputDecoration(hintText: "Enter IGN", hintStyle: TextStyle(fontSize: 12)),
                            style: const TextStyle(color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 40),

            // Buttons
            Row(
              children: [
                Expanded(child: _buildButton("CANCEL", Colors.redAccent, () => Navigator.pop(context))),
                const SizedBox(width: 20),
                Expanded(child: _buildButton("JOIN", Colors.cyanAccent, _isProcessing ? null : _handleJoin)),
              ],
            ),

            const SizedBox(height: 60),
            const Text("Note - Please Enter Your In Game Username/Name.", style: TextStyle(color: Colors.orange, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
          const SizedBox(width: 5),
          const Icon(Icons.monetization_on, color: Colors.orange, size: 16),
          Text(value, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _buildButton(String label, Color color, VoidCallback? onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: color, padding: const EdgeInsets.symmetric(vertical: 15)),
      onPressed: onPressed,
      child: Text(label, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
    );
  }
}