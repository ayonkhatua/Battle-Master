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
  bool _isFetchingBalance = true;
  int _winningBalance = 0; // 🌟 Pura balance nahi, sirf winning balance dikhana hai
  int _totalBalance = 0;   // Calculation ke liye

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _fetchCurrentBalance();
  }

  // 1. Sirf Winning Balance Fetch Karo
  Future<void> _fetchCurrentBalance() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final userData = await supabase
          .from('users')
          .select('wallet_balance, winning') // 🌟 Sahi columns fetch karo
          .eq('id', userId)
          .single();

      if (mounted) {
        setState(() {
          _totalBalance = userData['wallet_balance'] ?? 0;
          _winningBalance = userData['winning'] ?? 0;
          _isFetchingBalance = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching balance: $e");
      if (mounted) setState(() => _isFetchingBalance = false);
    }
  }

  // 2. Withdraw Request Submit Karna (Safe Logic)
  Future<void> _submitWithdrawRequest() async {
    String amountStr = _amountController.text.trim();
    String upiId = _upiController.text.trim();

    if (amountStr.isEmpty) {
      _showSnackBar('⚠️ Enter a valid amount!', Colors.orange);
      return;
    }
    
    int amountToWithdraw = int.parse(amountStr);

    if (amountToWithdraw < 50) { // 🌟 Minimum withdraw limit (e.g., 50 rs)
      _showSnackBar('⚠️ Minimum withdraw amount is 50 coins!', Colors.orange);
      return;
    }

    if (upiId.isEmpty || upiId.length < 5) {
      _showSnackBar('⚠️ Enter a valid UPI ID or Number!', Colors.orange);
      return;
    }

    // 🌟 SAFE CHECK: Sirf Winning balance se check karo
    if (amountToWithdraw > _winningBalance) {
      _showSnackBar('❌ You don\'t have enough WINNING coins!', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception("User session expired!");

      // 🌟 MAGIC LOGIC: RPC call ya manual update
      // Step 1: Request Pending me dalo
      await supabase.from('transactions').insert({
        'user_id': userId,
        'amount': amountToWithdraw,
        'type': 'withdraw',
        'txn_ref': upiId, // UPI ID as reference
        'status': 'pending',
      });

      // Step 2: User ka balance abhi kaat lo (taaki wo double withdraw na mare)
      // Agar admin reject karega, toh admin panel se paise wapas mil jayenge
      await supabase.from('users').update({
        'wallet_balance': _totalBalance - amountToWithdraw,
        'winning': _winningBalance - amountToWithdraw,
      }).eq('id', userId);

      _showSnackBar('✅ Withdraw request submitted successfully!', const Color(0xFF10B981));
      
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context); // Wapas wallet page par bhej do
      });

    } catch (e) {
      debugPrint("Error submitting withdraw: $e");
      _showSnackBar('❌ Error: Could not submit request. Try again.', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildBalanceCard(),
            const SizedBox(height: 35),
            const Text(
              "WITHDRAW DETAILS",
              style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.5),
            ),
            const SizedBox(height: 15),
            _buildInputForm(),
          ],
        ),
      ),
    );
  }

  // 🌟 Premium Green Balance Card (Withdraw logic ke hisaab se)
  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.5), width: 1.5), // Emerald Green
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
              const Icon(Icons.emoji_events, color: Color(0xFF10B981), size: 38), // Trophy icon for winning
              const SizedBox(width: 12),
              _isFetchingBalance 
                ? const SizedBox(height: 30, width: 30, child: CircularProgressIndicator(color: Color(0xFF10B981)))
                : Text(
                  '$_winningBalance',
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

  // 🌟 Clean Form Inputs
  Widget _buildInputForm() {
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
          const SizedBox(height: 15),
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
              onPressed: _isLoading || _isFetchingBalance ? null : _submitWithdrawRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981), // Green Button
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
}