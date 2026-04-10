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

  // 🌟 NAYA DIRECT FLUTTER LOGIC 🌟
  Future<void> _handleJoin() async {
    final List<String> uniqueSlots = widget.selectedSlots.toSet().toList();
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    for (var controller in _ignControllers) {
      if (controller.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Please enter IGN for all selected slots!"), backgroundColor: Colors.orange));
        return;
      }
    }

    setState(() => _isProcessing = true);

    try {
      // 1. Tournament ki latest details lao
      final tData = await Supabase.instance.client
          .from('tournaments')
          .select('entry_fee, filled, slots, type, status')
          .eq('id', widget.tournamentId)
          .single();
      
      int actualEntryFee = tData['entry_fee'] ?? 0;
      int currentFilled = tData['filled'] ?? 0;
      int totalFeeToPay = actualEntryFee * uniqueSlots.length;
      String status = tData['status'].toString().toLowerCase();

      if (status != 'upcoming') {
        throw "Sorry! The match has already started or is full.";
      }

      int totalCapacity = (tData['slots'] ?? 0) * (tData['type'].toString().toLowerCase() == 'squad' ? 4 : (tData['type'].toString().toLowerCase() == 'duo' ? 2 : 1));
      if (currentFilled + uniqueSlots.length > totalCapacity) {
        throw "Sorry! Not enough slots available.";
      }

      // 2. User ka Latest Wallet Balance lao
      final userData = await Supabase.instance.client
          .from('users')
          .select('wallet_balance')
          .eq('id', user.id)
          .single();
      
      int currentWallet = userData['wallet_balance'] ?? 0;

      // 3. Check Balance
      if (currentWallet < totalFeeToPay) {
        throw "Insufficient balance! Need 🪙$totalFeeToPay, but you have 🪙$currentWallet.";
      }

      // 🌟 STEP A: WALLET SE PAISA KATO 🌟
      await Supabase.instance.client
          .from('users')
          .update({'wallet_balance': currentWallet - totalFeeToPay})
          .eq('id', user.id);

      // 🌟 STEP B: JOIN ENTRIES 🌟
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

      // 🌟 STEP C: TRANSACTION HISTORY RECORD 🌟
      // Use 'withdraw' to avoid constraint errors
      await Supabase.instance.client.from('transactions').insert({
        'user_id': user.id,
        'amount': totalFeeToPay,
        'type': 'withdraw', 
        'txn_ref': 'JOIN_MATCH_${widget.tournamentId}',
        'status': 'approved',
      });

      // 🌟 STEP D: TOURNAMENT FILLED SLOTS UPDATE 🌟
      await Supabase.instance.client
          .from('tournaments')
          .update({'filled': currentFilled + uniqueSlots.length})
          .eq('id', widget.tournamentId);

      try {
        await FirebaseMessaging.instance.subscribeToTopic('tournament_${widget.tournamentId}');
      } catch (_) {}

      // Success Popup
      if (mounted) {
        setState(() => _isProcessing = false);
        _showSuccessPopup();
      }

    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        String errorMsg = e is PostgrestException ? e.message : e.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Error: $errorMsg"), backgroundColor: Colors.redAccent, duration: const Duration(seconds: 5)),
        );
      }
    }
  }

  void _showSuccessPopup() {
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
      : Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
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
                          _buildSummaryRow("Entry Fee", "🪙 ${widget.entryFee}"),
                          const SizedBox(height: 10),
                          _buildSummaryRow("Slots Selected", "x ${displayUniqueSlots.length}"),
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

                    const Align(alignment: Alignment.centerLeft, child: Text("Enter In-Game Names (IGN)", style: TextStyle(color: Color(0xFFfacc15), fontSize: 18, fontWeight: FontWeight.bold))),
                    const SizedBox(height: 15),

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
                  ],
                ),
              ),
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF374151), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        onPressed: () => Navigator.pop(context),
                        child: const Text("CANCEL", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563eb), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        onPressed: _userWallet < totalPayable ? null : _handleJoin,
                        child: Text(_userWallet < totalPayable ? "LOW BALANCE" : "JOIN NOW", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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