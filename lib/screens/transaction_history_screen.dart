import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  _TransactionHistoryScreenState createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _transactions = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      // Fetch ALL Transactions (Deposit, Withdraw, Winning, Bonus)
      final txnRes = await Supabase.instance.client
          .from('transactions')
          .select('type, amount, txn_ref, status, created_at')
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(50); // Performance ke liye 50 ka limit

      if (mounted) {
        setState(() {
          _transactions = List<Map<String, dynamic>>.from(txnRes);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching transactions: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Transaction type ke hisab se title formatting
  String _formatTransactionTitle(String type, String ref, String status) {
    type = type.toLowerCase();
    
    // Agar status pending/rejected hai, toh wo bhi dikhao
    String suffix = "";
    if (status.toLowerCase() != 'success' && status.toLowerCase() != 'approved') {
      suffix = " ($status)";
    }

    if (type == 'winning') return 'Match Reward - #$ref$suffix';
    if (type == 'deposit' || type == 'deposited') return 'Add Money to Wallet - #$ref$suffix';
    if (type == 'withdraw') return 'Withdraw Money - #$ref$suffix';
    if (type == 'bonus') return 'Bonus Added - #$ref$suffix';
    
    // Default fallback
    return '${type.toUpperCase()} - #$ref$suffix';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1120), // 🌟 Wapas Dark Blue Background
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        title: const Text("TRANSACTIONS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.2)),
        centerTitle: true, 
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFFACC15)), // Yellow back button
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
          : RefreshIndicator(
              onRefresh: _fetchData,
              color: const Color(0xFF0B1120),
              backgroundColor: const Color(0xFF3B82F6), // Blue loader
              child: _transactions.isEmpty
                  ? const Center(
                      child: Text("No transaction history found.", style: TextStyle(color: Colors.white54, fontSize: 16)),
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                      itemCount: _transactions.length,
                      itemBuilder: (context, index) {
                        return _buildTransactionCard(_transactions[index]);
                      },
                    ),
            ),
    );
  }

  // 🌟 Premium Dark Card Style with Screenshot Logic
  Widget _buildTransactionCard(Map<String, dynamic> t) {
    String type = t['type'] ?? 'Unknown';
    String status = t['status'] ?? 'pending';
    
    // Check if money is coming IN (+) or going OUT (-)
    bool isCredit = ['deposit', 'deposited', 'winning', 'bonus', 'credit'].contains(type.toLowerCase());
    String amountPrefix = isCredit ? "+" : "-";
    
    // Colors for Dark Theme
    Color typeColor = isCredit ? const Color(0xFF10B981) : const Color(0xFFEF4444); // Green for Credit, Red for Debit
    Color amountColor = isCredit ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    // Formatting Date (Like 2026-03-28 22:17:54)
    String formattedDate = '';
    if (t['created_at'] != null) {
      DateTime dt = DateTime.parse(t['created_at']);
      formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(dt);
    }

    String displayTitle = _formatTransactionTitle(type, t['txn_ref'].toString(), status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 15),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.8), // Dark Glassmorphic Card
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. CREDIT/DEBIT Text
          SizedBox(
            width: 65, // Fixed width
            child: Text(
              isCredit ? "CREDIT" : "DEBIT",
              style: TextStyle(
                color: typeColor,
                fontSize: 13,
                fontWeight: FontWeight.w900, // Bold and sharp
                letterSpacing: 0.5,
              ),
            ),
          ),
          
          // 2. Middle Details (Title & Date)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center, 
              children: [
                Text(
                  displayTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  formattedDate,
                  style: const TextStyle(color: Colors.white54, fontSize: 11), // Dim white for date
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 5),
          
          // 3. Amount and Coin Icon
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    amountPrefix,
                    style: TextStyle(color: amountColor, fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(width: 4),
                  Image.network('https://img.icons8.com/emoji/48/coin-emoji.png', width: 16, height: 16),
                  const SizedBox(width: 4),
                  Text(
                    t['amount'].toString(),
                    style: TextStyle(color: amountColor, fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}