
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:battle_master/screens/add_coin_screen.dart';
import 'package:battle_master/screens/withdraw_screen.dart';
import 'package:battle_master/screens/transaction_history_screen.dart';

// Class ka naam theek kar diya gaya hai (WalletPage -> WalletScreen)
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  _WalletScreenState createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  Future<Map<String, int>>? _walletDataFuture;

  @override
  void initState() {
    super.initState();
    _walletDataFuture = _fetchWalletData();
  }

  // Supabase se wallet data fetch karne ka logic
  Future<Map<String, int>> _fetchWalletData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    try {
      final response = await Supabase.instance.client
          .from('users')
          .select('wallet_balance, deposited_balance, winning_balance, bonus_balance')
          .eq('id', user.id)
          .single();

      return {
        'total': response['wallet_balance'] ?? 0,
        'deposited': response['deposited_balance'] ?? 0,
        'winning': response['winning_balance'] ?? 0,
        'bonus': response['bonus_balance'] ?? 0,
      };
    } catch (e) {
      print('Error fetching wallet data: $e');
      // Agar error aaye to 0 values ke sath return karo
      return {'total': 0, 'deposited': 0, 'winning': 0, 'bonus': 0};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1f2937),
        elevation: 2,
        title: const Text('My Wallet', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<Map<String, int>>(
        future: _walletDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFfacc15)));
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text("Could not load wallet data.", style: TextStyle(color: Colors.white)));
          }

          final walletData = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                Center(
                  child: Column(
                    children: [
                      Image.network('https://img.icons8.com/emoji/48/coin-emoji.png', width: 45, height: 45),
                      const SizedBox(height: 8),
                      Text(
                        '${walletData['total']} Coins',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFFACC15)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: _buildStatBox('Deposited', "${walletData['deposited']}")),
                    const SizedBox(width: 10),
                    Expanded(child: _buildStatBox('Winning', "${walletData['winning']}")),
                    const SizedBox(width: 10),
                    Expanded(child: _buildStatBox('Bonus', "${walletData['bonus']}")),
                  ],
                ),
                const SizedBox(height: 30),
                const Text(
                  'My Wallet Actions',
                  style: TextStyle(fontSize: 18, color: Color(0xFFFACC15), fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: _buildActionBox(
                        'Add Coin',
                        'https://img.icons8.com/fluency/48/money-bag.png',
                        () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddCoinScreen())),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildActionBox(
                        'Withdraw',
                        'https://img.icons8.com/fluency/48/cash-in-hand.png',
                        () => Navigator.push(context, MaterialPageRoute(builder: (context) => const WithdrawScreen())),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildActionBox(
                        'Transactions',
                        'https://img.icons8.com/fluency/48/bill.png',
                        () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TransactionHistoryScreen())),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatBox(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.network('https://img.icons8.com/emoji/48/coin-emoji.png', width: 16, height: 16),
              const SizedBox(width: 4),
              Text(title, style: const TextStyle(fontSize: 12, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFACC15))),
          const SizedBox(height: 2),
          const Text('Coins', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
        ],
      ),
    );
  }

  Widget _buildActionBox(String title, String iconUrl, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF2563EB),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(iconUrl, width: 26, height: 26),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
