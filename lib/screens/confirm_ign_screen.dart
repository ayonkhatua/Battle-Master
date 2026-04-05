import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

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
    // Unique slots handle karne ke liye controllers
    final int uniqueCount = widget.selectedSlots.toSet().length;
    for (int i = 0; i < uniqueCount; i++) {
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
    final List<String> uniqueSlots = widget.selectedSlots.toSet().toList();
    int totalFee = widget.entryFee * uniqueSlots.length;

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

      // 🛡️ NAYA: ONGOING CHECK (Final check before payment) 🛡️
      final statusRes = await Supabase.instance.client
          .from('tournaments')
          .select('status, filled')
          .eq('id', widget.tournamentId)
          .single();

      if (statusRes['status'].toString().toLowerCase() != 'upcoming') {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("❌ Sorry! The match has already started or is full."), backgroundColor: Colors.red));
        Navigator.of(context).popUntil((route) => route.isFirst); // Home bhej do
        return;
      }

      // Wallet balance check
      final freshUserReq = await Supabase.instance.client.from('users').select('wallet_balance').eq('id', user.id).single();
      int freshWallet = freshUserReq['wallet_balance'] ?? 0;

      if (freshWallet < totalFee) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("❌ Not enough balance!"), backgroundColor: Colors.red));
        return;
      }

      // 1. Wallet deduction
      await Supabase.instance.client.from('users').update({'wallet_balance': freshWallet - totalFee}).eq('id', user.id);

      // 2. Participants entries
      for (int i = 0; i < uniqueSlots.length; i++) {
        var parts = uniqueSlots[i].split('-'); 
        await Supabase.instance.client.from('user_tournaments').insert({
          'user_id': user.id,
          'tournament_id': widget.tournamentId,
          'slot_number': int.parse(parts[0]),
          'position': parts.length > 1 ? parts[1] : '1',
          'user_ign': _ignControllers[i].text.trim(),
        });
      }

      // 3. Transaction record
      await Supabase.instance.client.from('transactions').insert({
        'user_id': user.id,
        'amount': totalFee,
        'type': 'withdraw',
        'txn_ref': 'JOIN_${widget.tournamentId}_${DateTime.now().millisecondsSinceEpoch}',
        'status': 'success',
      });

      // 4. Update filled count
      int currentFilled = statusRes['filled'] ?? 0;
      await Supabase.instance.client.from('tournaments').update({'filled': currentFilled + uniqueSlots.length}).eq('id', widget.tournamentId);

      // FCM Subscription
      try {
        await FirebaseMessaging.instance.subscribeToTopic('tournament_${widget.tournamentId}');
      } catch (_) {}

      // 🌟 SUCCESS POPUP 🌟
      if (mounted) {
        setState(() => _isProcessing = false); 
        Future.delayed(Duration.zero, () {
          showDialog(
            context: context,
            barrierDismissible: false, 
            builder: (BuildContext dialogContext) {
              return Dialog(
                backgroundColor: const Color(0xFF1e293b),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.greenAccent, size: 80),
                      const SizedBox(height: 20),
                      const Text("JOINED SUCCESSFULLY!", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                      const SizedBox(height: 10),
                      const Text("Your slots are confirmed. Room ID and Password will be updated before the match starts.", style: TextStyle(color: Colors.grey, fontSize: 14), textAlign: TextAlign.center),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFfacc15),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => Navigator.of(dialogContext).popUntil((route) => route.isFirst),
                          child: const Text("BACK TO HOME", style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        });
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Failed: $e"), backgroundColor: Colors.red));
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> displayUniqueSlots = widget.selectedSlots.toSet().toList();
    int totalPayable = widget.entryFee * displayUniqueSlots.length;

    return Scaffold(
      backgroundColor: const Color(0xFF0f172a), 
      appBar: AppBar(
        backgroundColor: const Color(0xFF1e293b), 
        title: const Text("CONFIRM JOIN", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isProcessing 
      ? const Center(child: CircularProgressIndicator(color: Color(0xFFfacc15)))
      : Column(
          children: [
            // 🌟 Scrollable content area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Balance Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1e293b),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF374151)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Current Balance", style: TextStyle(color: Colors.grey, fontSize: 15)),
                              Text("🪙 $_userWallet", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const Divider(color: Color(0xFF374151), height: 30),
                          _buildSummaryRow("Entry Fee", "🪙 ${widget.entryFee}"),
                          const SizedBox(height: 10),
                          _buildSummaryRow("Slots", "x ${displayUniqueSlots.length}"),
                          const Divider(color: Color(0xFF374151), height: 30),
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
                    const Align(alignment: Alignment.centerLeft, child: Text("Enter In-Game Names (IGN)", style: TextStyle(color: Color(0xFFfacc15), fontSize: 18, fontWeight: FontWeight.bold))),
                    const SizedBox(height: 15),

                    // IGN Inputs
                    Container(
                      decoration: BoxDecoration(color: const Color(0xFF1e293b), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF374151))),
                      child: Column(
                        children: displayUniqueSlots.asMap().entries.map((entry) {
                          int idx = entry.key;
                          var parts = entry.value.split('-'); 
                          return Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(border: idx != displayUniqueSlots.length - 1 ? const Border(bottom: BorderSide(color: Color(0xFF374151))) : null),
                            child: Row(
                              children: [
                                Container(
                                  width: 60,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(color: const Color(0xFF374151), borderRadius: BorderRadius.circular(8)),
                                  child: Text("S-${parts[0]}\nP${parts.length > 1 ? parts[1] : '1'}", textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: TextField(
                                    controller: _ignControllers[idx],
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      hintText: "Exact Username",
                                      hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                                      filled: true,
                                      fillColor: const Color(0xFF0f172a),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // 🌟 Fixed Bottom Buttons (Safely handling overflows)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF374151), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        onPressed: () => Navigator.pop(context),
                        child: const Text("CANCEL", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563eb), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        onPressed: _userWallet < totalPayable ? null : _handleJoin,
                        child: Text(_userWallet < totalPayable ? "LOW BALANCE" : "JOIN NOW", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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