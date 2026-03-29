import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// 🌟 Yahan aapko apne AddCoinScreen ka sahi path dena hoga
import 'package:battle_master/screens/add_coin_screen.dart'; // Apna actual path lagana

class AddWalletScreen extends StatefulWidget {
  const AddWalletScreen({super.key});

  @override
  _AddWalletScreenState createState() => _AddWalletScreenState();
}

class _AddWalletScreenState extends State<AddWalletScreen> {
  final supabase = Supabase.instance.client;
  
  Map<String, dynamic>? _walletData;
  List<dynamic> _recentTransactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWalletData();
  }

  // Database se Wallet Balance aur Transactions fetch karo
  Future<void> _fetchWalletData() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      // 1. Fetch User Balances
      final userData = await supabase
          .from('users')
          .select('wallet_balance, deposited, winning, bonus')
          .eq('id', userId)
          .single();

      // 2. Fetch Recent Transactions (Aakhiri 5)
      final txnData = await supabase
          .from('transactions')
          .select('amount, type, status, created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(5);

      if (mounted) {
        setState(() {
          _walletData = userData;
          _recentTransactions = txnData;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching wallet data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Add Coins button pe click karne par Payment Screen khulegi
  void _navigateToAddCoins() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddCoinScreen()),
    ).then((value) {
      // Wapas aane par data refresh karo taaki naya pending request dikhe
      _fetchWalletData(); 
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(
        title: const Text('My Wallet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1F2937),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      // 🌟 Pull to Refresh laga diya taaki user khud refresh kar sake
      body: RefreshIndicator(
        onRefresh: _fetchWalletData,
        color: const Color(0xFFFACC15),
        backgroundColor: const Color(0xFF1F2937),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFFACC15)))
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildMainBalanceCard(),
                    const SizedBox(height: 15),
                    _buildSubBalances(),
                    const SizedBox(height: 30),
                    const Text(
                      "Recent Transactions",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 15),
                    _buildTransactionList(),
                  ],
                ),
              ),
      ),
    );
  }

  // 🌟 Main Balance Card (Bada wala)
  Widget _buildMainBalanceCard() {
    int totalBalance = _walletData?['wallet_balance'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563eb), Color(0xFF1e40af)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          const Text("Total Balance", style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.network('https://img.icons8.com/emoji/48/coin-emoji.png', width: 32, height: 32),
              const SizedBox(width: 10),
              Text(
                totalBalance.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 25),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _navigateToAddCoins,
              icon: const Icon(Icons.add_circle, color: Colors.black),
              label: const Text("Add Coins", style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFACC15),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🌟 Chote wale balance cards (Deposit, Winning, Bonus)
  Widget _buildSubBalances() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _miniBalanceCard("Deposited", _walletData?['deposited'] ?? 0, Icons.account_balance_wallet, Colors.blue),
        _miniBalanceCard("Winning", _walletData?['winning'] ?? 0, Icons.emoji_events, Colors.orange),
        _miniBalanceCard("Bonus", _walletData?['bonus'] ?? 0, Icons.card_giftcard, Colors.green),
      ],
    );
  }

  Widget _miniBalanceCard(String title, int amount, IconData icon, Color iconColor) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1F2937),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            const SizedBox(height: 4),
            Text(amount.toString(), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // 🌟 Transactions List
  Widget _buildTransactionList() {
    if (_recentTransactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: const Color(0xFF1F2937), borderRadius: BorderRadius.circular(12)),
        child: const Center(
          child: Text("No transactions yet.", style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _recentTransactions.length,
      itemBuilder: (context, index) {
        final txn = _recentTransactions[index];
        final bool isCredit = txn['type'] == 'deposit' || txn['type'] == 'winning' || txn['type'] == 'bonus';
        
        // Status Colors
        Color statusColor = Colors.grey;
        if (txn['status'] == 'success') statusColor = Colors.green;
        if (txn['status'] == 'pending') statusColor = Colors.orange;
        if (txn['status'] == 'rejected') statusColor = Colors.red;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFF1F2937), borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: isCredit ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                    child: Icon(
                      isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                      color: isCredit ? Colors.green : Colors.red,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        txn['type'].toString().toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        txn['status'].toString().toUpperCase(),
                        style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                "${isCredit ? '+' : '-'} ${txn['amount']}",
                style: TextStyle(
                  color: isCredit ? Colors.green : Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}