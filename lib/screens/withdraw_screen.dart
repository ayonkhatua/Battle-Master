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
  int _currentBalance = 0;

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _fetchCurrentBalance();
  }

  // 1. Page load hote hi user ka current balance fetch karna
  Future<void> _fetchCurrentBalance() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final userData = await supabase
          .from('users')
          .select('wallet_balance')
          .eq('id', userId)
          .single();

      if (mounted) {
        setState(() {
          _currentBalance = userData['wallet_balance'] ?? 0;
          _isFetchingBalance = false;
        });
      }
    } catch (e) {
      print("Error fetching balance: $e");
      if (mounted) {
        setState(() {
          _isFetchingBalance = false;
        });
      }
    }
  }

  // 2. Withdraw Request Submit karna
  Future<void> _submitWithdrawRequest() async {
    String amountStr = _amountController.text.trim();
    String upiId = _upiController.text.trim();

    // Validation
    if (amountStr.isEmpty || int.parse(amountStr) <= 0) {
      _showSnackBar('Enter a valid amount!', Colors.red);
      return;
    }
    if (upiId.isEmpty) {
      _showSnackBar('Enter your UPI ID or Number!', Colors.red);
      return;
    }

    int amountToWithdraw = int.parse(amountStr);

    // Balance check
    if (amountToWithdraw > _currentBalance) {
      _showSnackBar('❌ You don\'t have enough coins!', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        throw Exception("User is not logged in!");
      }

      // 3. Request save karo (Balance abhi deduct nahi hoga, jaisa PHP me tha)
      await supabase.from('transactions').insert({
        'user_id': userId,
        'amount': amountToWithdraw,
        'type': 'withdraw',
        'txn_ref': upiId,
        'status': 'pending',
      });

      _showSnackBar('✅ Withdraw request submitted successfully!', Colors.green);
      
      _amountController.clear();
      _upiController.clear();
      
      // Optional: Agar user ko wapas wallet page par bhejna hai
      // Navigator.pop(context);

    } catch (e) {
      print("Error submitting withdraw: $e");
      _showSnackBar('Error: Could not submit request.', Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Chota sa helper function messages dikhane ke liye
  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: color),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(
        title: const Text('Withdraw Coins', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF111827),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 💰 Current Balance Display Box
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1F2937),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF374151)),
              ),
              child: Column(
                children: [
                  const Text('Your Balance', style: TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 8),
                  _isFetchingBalance
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Color(0xFFFACC15), strokeWidth: 2),
                        )
                      : Text(
                          '$_currentBalance Coins',
                          style: const TextStyle(
                            color: Color(0xFFFACC15),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // 📝 Form Inputs
            const Text(
              'Withdraw Details',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            
            // Amount Input
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Withdraw Amount',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF374151), // Matching your PHP CSS
                prefixIcon: const Icon(Icons.monetization_on, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 15),

            // UPI Input
            TextField(
              controller: _upiController,
              keyboardType: TextInputType.text,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'UPI ID / Mobile Number',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF374151), // Matching your PHP CSS
                prefixIcon: const Icon(Icons.account_balance_wallet, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 30),

            // 🚀 Submit Button
            ElevatedButton(
              onPressed: _isLoading || _isFetchingBalance ? null : _submitWithdrawRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB), // Blue button matching your PHP CSS
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Submit Request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}