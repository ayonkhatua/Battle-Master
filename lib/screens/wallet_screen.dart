import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:battle_master/screens/add_coin_screen.dart';
import 'package:battle_master/screens/withdraw_screen.dart';
import 'package:battle_master/screens/transaction_history_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  _WalletScreenState createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  Map<String, int> _walletData = {'total': 0, 'deposited': 0, 'winning': 0, 'bonus': 0};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWalletData();
  }

  // 🌟 Database se fetch karne ka logic (Sahi Column Names ke sath)
  Future<void> _fetchWalletData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await Supabase.instance.client
          .from('users')
          // ⚠️ Dhyan dein: Schema ke hisab se sahi naam use kiye hain
          .select('wallet_balance, deposited, winning, bonus') 
          .eq('id', user.id)
          .single();

      if (mounted) {
        setState(() {
          _walletData = {
            'total': response['wallet_balance'] ?? 0,
            'deposited': response['deposited'] ?? 0,
            'winning': response['winning'] ?? 0,
            'bonus': response['bonus'] ?? 0,
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching wallet data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Kisi bhi page se wapas aane par data refresh karne ke liye
  void _navigateTo(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    ).then((_) {
      // Wapas aate hi loading true karke naya data fetch karo
      setState(() => _isLoading = true);
      _fetchWalletData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1120), // Deep Dark Gaming Background
      appBar: AppBar(
        title: const Text('MY WALLET', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white), // App bar icon changed to white
      ),
      // Pull to refresh feature
      body: RefreshIndicator(
        onRefresh: _fetchWalletData,
        color: const Color(0xFF0B1120),
        backgroundColor: const Color(0xFF3B82F6), // Refresh icon background changed to Blue
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6))) // Loading changed to Blue
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildMainBalanceCard(),
                    const SizedBox(height: 25),
                    const Text(
                      "BALANCE BREAKUP",
                      style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 10),
                    _buildSubBalances(),
                    const SizedBox(height: 35),
                    const Text(
                      "QUICK ACTIONS",
                      style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 10),
                    _buildActionButtons(),
                  ],
                ),
              ),
      ),
    );
  }

  // 🌟 Premium Main Balance Card
  Widget _buildMainBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 35, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.5), width: 1.5), // Border changed to Blue
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.15), // Shadow changed to Blue
            blurRadius: 25,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text("TOTAL COINS", style: TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.network('https://img.icons8.com/emoji/48/coin-emoji.png', width: 45, height: 45),
              const SizedBox(width: 12),
              Text(
                '${_walletData['total']}',
                style: const TextStyle(color: Colors.white, fontSize: 55, fontWeight: FontWeight.w900, height: 1.1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 🌟 Breakup Balances (Glassmorphism look)
  Widget _buildSubBalances() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _miniBalanceCard("DEPOSITED", _walletData['deposited'] ?? 0, Icons.account_balance_wallet, const Color(0xFF3B82F6)),
        _miniBalanceCard("WINNING", _walletData['winning'] ?? 0, Icons.emoji_events, const Color(0xFF10B981)),
        _miniBalanceCard("BONUS", _walletData['bonus'] ?? 0, Icons.card_giftcard, const Color(0xFFEC4899)),
      ],
    );
  }

  Widget _miniBalanceCard(String title, int amount, IconData icon, Color iconColor) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(height: 8),
            Text(amount.toString(), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(title, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
          ],
        ),
      ),
    );
  }

  // 🌟 Action Buttons Row (Add, Withdraw, History)
  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: _actionBox(
            "ADD COINS", 
            Icons.add_circle_outline, 
            const Color(0xFF3B82F6), // 🌟 CHANGED TO BLUE
            Colors.white,            // 🌟 CHANGED TO WHITE TEXT
            () => _navigateTo(const AddCoinScreen())
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _actionBox(
            "WITHDRAW", 
            Icons.account_balance, 
            const Color(0xFF10B981), // 🌟 CHANGED TO GREEN (To keep it distinct)
            Colors.white,
            () => _navigateTo(const WithdrawScreen())
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _actionBox(
            "HISTORY", 
            Icons.history, 
            const Color(0xFF1E293B), // Dark Grey
            Colors.white,
            () => _navigateTo(const TransactionHistoryScreen())
          ),
        ),
      ],
    );
  }

  Widget _actionBox(String title, IconData icon, Color bgColor, Color textColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 5),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            // 🌟 Only add glow if it's Blue or Green
            if (bgColor == const Color(0xFF3B82F6) || bgColor == const Color(0xFF10B981))
              BoxShadow(color: bgColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: textColor, size: 28),
            const SizedBox(height: 8),
            Text(
              title, 
              style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}