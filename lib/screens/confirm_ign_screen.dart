import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ConfirmJoinScreen extends StatefulWidget {
  final int tournamentId;
  final List<String> selectedSlots; 
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
    for (var _ in widget.selectedSlots) {
      _ignControllers.add(TextEditingController());
    }
    _fetchWallet(); 
  }

  Future<void> _fetchWallet() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    
    final res = await Supabase.instance.client.from('users').select('wallet_balance').eq('id', user.id).single();
    if (mounted) {
      setState(() { _userWallet = res['wallet_balance'] ?? 0; });
    }
  }

  Future<void> _handleJoin() async {
    int totalFee = widget.entryFee * widget.selectedSlots.length;

    for (var controller in _ignControllers) {
      if (controller.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Please enter IGN for all selected slots!"), backgroundColor: Colors.orange));
        return;
      }
    }

    setState(() => _isProcessing = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      final freshUserReq = await Supabase.instance.client.from('users').select('wallet_balance').eq('id', user.id).single();
      int freshWallet = freshUserReq['wallet_balance'] ?? 0;

      if (freshWallet < totalFee) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("❌ Not enough balance in your wallet!"), backgroundColor: Colors.red));
        return;
      }

      await Supabase.instance.client.from('users').update({'wallet_balance': freshWallet - totalFee}).eq('id', user.id);

      for (int i = 0; i < widget.selectedSlots.length; i++) {
        var parts = widget.selectedSlots[i].split('-'); 
        await Supabase.instance.client.from('user_tournaments').insert({
          'user_id': user.id,
          'tournament_id': widget.tournamentId,
          'slot_number': int.parse(parts[0]),
          'position': parts.length > 1 ? parts[1] : '1',
          'user_ign': _ignControllers[i].text.trim(),
        });
      }

      await Supabase.instance.client.from('transactions').insert({
        'user_id': user.id,
        'amount': totalFee,
        'type': 'withdraw',
        'txn_ref': 'JOIN_${widget.tournamentId}_${DateTime.now().millisecondsSinceEpoch}',
        'status': 'success',
      });

      final tRes = await Supabase.instance.client.from('tournaments').select('filled').eq('id', widget.tournamentId).single();
      await Supabase.instance.client.from('tournaments').update({'filled': (tRes['filled'] ?? 0) + widget.selectedSlots.length}).eq('id', widget.tournamentId);

      // 🌟 NAYA LOGIC: SUCCESS POPUP DIALOG 🌟
      if (mounted) {
        setState(() => _isProcessing = false); // Piche wala loading band karo

        showDialog(
          context: context,
          barrierDismissible: false, // User screen par click karke dialog band na kar paye
          builder: (BuildContext context) {
            return Dialog(
              backgroundColor: const Color(0xFF1e293b),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Bada sa Green Check Icon
                    const Icon(Icons.check_circle, color: Colors.greenAccent, size: 80),
                    const SizedBox(height: 20),
                    
                    const Text(
                      "JOINED SUCCESSFULLY!", 
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), 
                      textAlign: TextAlign.center
                    ),
                    const SizedBox(height: 10),
                    
                    const Text(
                      "Your slots are confirmed. Room ID and Password will be updated before the match starts.", 
                      style: TextStyle(color: Colors.grey, fontSize: 14), 
                      textAlign: TextAlign.center
                    ),
                    const SizedBox(height: 30),
                    
                    // 🏠 Back To Home Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFfacc15), // Golden button
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          // Ye code sidha Home Screen par phek dega (stack clear karke)
                          Navigator.popUntil(context, (route) => route.isFirst);
                        },
                        child: const Text("BACK TO HOME", style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }

    } catch (e) {
      print("Join Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Failed to join: $e"), backgroundColor: Colors.red));
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalPayable = widget.entryFee * widget.selectedSlots.length;

    return Scaffold(
      backgroundColor: const Color(0xFF0f172a), 
      appBar: AppBar(
        backgroundColor: const Color(0xFF1e293b), 
        title: const Text("CONFIRM JOIN", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isProcessing 
      ? const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFFfacc15)),
              SizedBox(height: 20),
              Text("Processing your entry...", style: TextStyle(color: Colors.white70, fontSize: 16))
            ],
          ),
        )
      : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1e293b),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF374151)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Current Balance", style: TextStyle(color: Colors.grey, fontSize: 15)),
                      Row(
                        children: [
                          const Icon(Icons.account_balance_wallet, color: Colors.greenAccent, size: 18),
                          const SizedBox(width: 5),
                          Text("🪙 $_userWallet", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      )
                    ],
                  ),
                  const Divider(color: Color(0xFF374151), height: 30, thickness: 1),
                  _buildSummaryRow("Entry Fee (Per Person)", "🪙 ${widget.entryFee}"),
                  const SizedBox(height: 10),
                  _buildSummaryRow("Slots Selected", "x ${widget.selectedSlots.length}"),
                  const Divider(color: Color(0xFF374151), height: 30, thickness: 1),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Total Payable", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text("🪙 $totalPayable", style: const TextStyle(color: Color(0xFFfacc15), fontSize: 22, fontWeight: FontWeight.bold)), 
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Enter In-Game Names (IGN)", style: TextStyle(color: Color(0xFFfacc15), fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 15),

            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1e293b),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF374151)),
              ),
              child: Column(
                children: widget.selectedSlots.asMap().entries.map((entry) {
                  int idx = entry.key;
                  var parts = entry.value.split('-'); 
                  String slotNo = parts[0];
                  String posNo = parts.length > 1 ? parts[1] : '1';

                  return Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      border: idx != widget.selectedSlots.length - 1 
                          ? const Border(bottom: BorderSide(color: Color(0xFF374151))) 
                          : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(color: const Color(0xFF374151), borderRadius: BorderRadius.circular(8)),
                          child: Text("Slot $slotNo\n(P$posNo)", textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: TextField(
                            controller: _ignControllers[idx],
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: "Exact Game Username",
                              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                              filled: true,
                              fillColor: const Color(0xFF0f172a),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 40),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange)),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  SizedBox(width: 10),
                  Expanded(child: Text("Please enter your exact in-game name. Incorrect names will be kicked from the custom room.", style: TextStyle(color: Colors.orange, fontSize: 12))),
                ],
              ),
            ),

            const SizedBox(height: 30),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF374151),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("CANCEL", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563eb), 
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      shadowColor: const Color(0xFF2563eb).withOpacity(0.5),
                      elevation: 8,
                    ),
                    onPressed: _userWallet < totalPayable ? null : _handleJoin,
                    child: Text(
                      _userWallet < totalPayable ? "LOW BALANCE" : "CONFIRM JOIN", 
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 15)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
      ],
    );
  }
}