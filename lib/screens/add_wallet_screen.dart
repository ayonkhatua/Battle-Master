import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddWalletScreen extends StatefulWidget {
  const AddWalletScreen({super.key});

  @override
  _AddWalletScreenState createState() => _AddWalletScreenState();
}

class _AddWalletScreenState extends State<AddWalletScreen> {
  final TextEditingController _amountController = TextEditingController();
  bool _isLoading = false;

  // Supabase client initialize
  final supabase = Supabase.instance.client;

  Future<void> _addCoins() async {
    String amountStr = _amountController.text.trim();
    if (amountStr.isEmpty || int.parse(amountStr) < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimum 10 coins required!'), backgroundColor: Colors.red),
      );
      return;
    }

    int amountToAdd = int.parse(amountStr);

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Current logged-in user ki ID nikalna
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        throw Exception("User is not logged in!");
      }

      // 2. User ka purana balance aur referral code fetch karna
      final userData = await supabase
          .from('users')
          .select('wallet_balance, deposited, referred_by')
          .eq('id', userId)
          .single();

      int currentBalance = userData['wallet_balance'] ?? 0;
      int currentDeposited = userData['deposited'] ?? 0;
      String? referredBy = userData['referred_by'];

      // 3. User ka naya balance update karna
      await supabase.from('users').update({
        'wallet_balance': currentBalance + amountToAdd,
        'deposited': currentDeposited + amountToAdd,
      }).eq('id', userId);

      // 4. Referral Reward Logic (Agar user kisi ke link se aaya tha)
      if (referredBy != null && referredBy.isNotEmpty) {
        // Jis bande ka code hai, uska data nikalo
        final referrerData = await supabase
            .from('users')
            .select('id, wallet_balance, bonus')
            .eq('fcode', referredBy)
            .maybeSingle();

        // Agar wo banda database me exist karta hai, toh use 5 coin de do
        if (referrerData != null) {
          int refBalance = referrerData['wallet_balance'] ?? 0;
          int refBonus = referrerData['bonus'] ?? 0;

          await supabase.from('users').update({
            'wallet_balance': refBalance + 5,
            'bonus': refBonus + 5,
          }).eq('id', referrerData['id']);
        }
      }

      // Success Message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$amountToAdd Coins added successfully!'), backgroundColor: Colors.green),
        );
        _amountController.clear();
        // Navigator.pop(context); // Optional: Piche wallet page par bhejne ke liye
      }

    } catch (e) {
      print("Error updating wallet: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(
        title: const Text('Add Coins', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF111827),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Enter Coin Amount',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              decoration: InputDecoration(
                hintText: 'Minimum 10 Coins',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF1F2937),
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Image.network('https://img.icons8.com/emoji/48/coin-emoji.png', width: 24, height: 24),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isLoading ? null : _addCoins,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E), 
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Add to Wallet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}