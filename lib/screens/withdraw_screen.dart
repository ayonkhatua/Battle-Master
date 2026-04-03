import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  _WithdrawScreenState createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _upiController = TextEditingController();
  
  bool _isLoading = false;

  final supabase = Supabase.instance.client;
  
  // 🌟 Realtime Stream for User Data
  Stream<List<Map<String, dynamic>>>? _userStream;

  @override
  void initState() {
    super.initState();
    final userId = supabase.auth.currentUser?.id;
    if (userId != null) {
      _userStream = supabase
          .from('users')
          .stream(primaryKey: ['id'])
          .eq('id', userId);
    }
  }

  // 🌟 Quick Amount Button Logic
  void _setQuickAmount(int amount) {
    setState(() {
      _amountController.text = amount.toString();
    });
  }

  // 2. Withdraw Request Submit Karna (Safe Logic)
  Future<void> _submitWithdrawRequest(int currentTotal, int currentWinning) async {
    String amountStr = _amountController.text.trim();
    String upiId = _upiController.text.trim();

    if (amountStr.isEmpty) {
      _showSnackBar('⚠️ Enter a valid amount!', Colors.orange);
      return;
    }
    
    int? amountToWithdraw = int.tryParse(amountStr);
    
    if (amountToWithdraw == null) {
       _showSnackBar('⚠️ Invalid amount format!', Colors.orange);
      return;
    }

    if (amountToWithdraw < 50) { 
      _showSnackBar('⚠️ Minimum withdraw amount is 50 coins!', Colors.orange);
      return;
    }

    if (upiId.isEmpty || upiId.length < 5) {
      _showSnackBar('⚠️ Enter a valid UPI ID or Number!', Colors.orange);
      return;
    }

    // 🌟 SAFE CHECK: Sirf Winning balance se check karo
    if (amountToWithdraw > currentWinning) {
      _showSnackBar('❌ You don\'t have enough WINNING coins!', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception("User session expired!");

      // 🌟 STEP 1: FORCE UPDATE BALANCE FIRST (with .select() to verify)
      final updateResponse = await supabase.from('users').update({
        'wallet_balance': currentTotal - amountToWithdraw,
        'winning': currentWinning - amountToWithdraw,
      }).eq('id', userId).select();

      // Agar response empty hai, iska matlab database ne permission deny kar di
      if (updateResponse.isEmpty) {
         throw Exception("Database blocked the transaction. Please check RLS policies.");
      }

      // 🌟 STEP 2: Request Pending me dalo (History ke liye)
      await supabase.from('transactions').insert({
        'user_id': userId,
        'amount': amountToWithdraw,
        'type': 'withdraw',
        'txn_ref': upiId, 
        'status': 'pending',
      });

      _showSnackBar('✅ Withdraw request submitted! Coins deducted.', const Color(0xFF10B981));
      
      // Form saaf kar do
      _amountController.clear();
      _upiController.clear();

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) Navigator.pop(context); // Wapas bhej do
      });

    } catch (e) {
      debugPrint("Error submitting withdraw: $e");
      _showSnackBar('❌ Error: Failed to deduct balance.', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    if(mounted){
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: color, behavior: SnackBarBehavior.floating));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1120), // Dark Theme
      appBar: AppBar(
        title: const Text('WITHDRAW', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _userStream == null 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
        : StreamBuilder<List<Map<String, dynamic>>>(
            stream: _userStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)));
              }

              if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text("Error loading balance.", style: TextStyle(color: Colors.redAccent)));
              }

              final userData = snapshot.data!.first;
              final currentTotal = userData['wallet_balance'] ?? 0;
              final currentWinning = userData['winning'] ?? 0;

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildBalanceCard(currentWinning),
                    const SizedBox(height: 35),
                    const Text(
                      "WITHDRAW DETAILS",
                      style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 15),
                    _buildInputForm(currentTotal, currentWinning),
                  ],
                ),
              );
            }
          ),
    );
  }

  // 🌟 Premium Green Balance Card
  Widget _buildBalanceCard(int winningBalance) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.5), width: 1.5), 
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.15),
            blurRadius: 25,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text("WITHDRAWABLE BALANCE", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.emoji_events, color: Color(0xFF10B981), size: 38), 
              const SizedBox(width: 12),
              Text(
                '$winningBalance',
                style: const TextStyle(color: Colors.white, fontSize: 50, fontWeight: FontWeight.w900, height: 1.1),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text("You can only withdraw your winning balance.", style: TextStyle(color: Colors.white38, fontSize: 10)),
        ],
      ),
    );
  }

  // 🌟 Clean Form Inputs with Quick Buttons
  Widget _buildInputForm(int currentTotal, int currentWinning) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: 'Enter Amount (Min 50)',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
              filled: true,
              fillColor: const Color(0xFF0F172A),
              prefixIcon: const Icon(Icons.currency_rupee, color: Color(0xFF10B981)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 18),
            ),
          ),
          const SizedBox(height: 12),
          
          // 🌟 NAYA: Quick Amount Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildQuickAmountChip(50),
              _buildQuickAmountChip(100),
              _buildQuickAmountChip(200),
              _buildQuickAmountChip(500),
            ],
          ),
          
          const SizedBox(height: 20),
          TextField(
            controller: _upiController,
            keyboardType: TextInputType.text,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              hintText: 'UPI ID or Mobile No.',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
              filled: true,
              fillColor: const Color(0xFF0F172A),
              prefixIcon: const Icon(Icons.account_balance, color: Colors.blueAccent),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 18),
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _isLoading ? null : () => _submitWithdrawRequest(currentTotal, currentWinning),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981), 
                foregroundColor: Colors.white,
                elevation: 10,
                shadowColor: const Color(0xFF10B981).withOpacity(0.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isLoading 
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                : const Text("CASH OUT NOW", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
            ),
          ),
        ],
      ),
    );
  }

  // 🌟 NAYA: Quick amount chip UI component
  Widget _buildQuickAmountChip(int amount) {
    return GestureDetector(
      onTap: () => _setQuickAmount(amount),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white12),
        ),
        child: Text(
          "$amount", 
          style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 13)
        ),
      ),
    );
  }
}