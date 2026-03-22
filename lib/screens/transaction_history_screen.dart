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
  int _walletBalance = 0;
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
      // 1. Fetch Wallet Balance
      final userRes = await Supabase.instance.client
          .from('users')
          .select('wallet_balance')
          .eq('id', user.id)
          .single();

      // 2. Fetch Transactions (Only deposit & withdraw as per your PHP)
      final txnRes = await Supabase.instance.client
          .from('transactions')
          .select('type, amount, txn_ref, status, created_at')
          .eq('user_id', user.id)
          .or('type.eq.deposit,type.eq.withdraw') // logic for: (type = 'deposit' OR type = 'withdraw')
          .order('created_at', ascending: false);

      setState(() {
        _walletBalance = userRes['wallet_balance'] ?? 0;
        _transactions = List<Map<String, dynamic>>.from(txnRes);
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching transactions: $e");
      setState(() => _isLoading = false);
    }
  }

  // Status ke hisaab se color decide karne ka function
  Color _getStatusColor(String status) {
    status = status.toLowerCase();
    if (status == 'pending') return Colors.orange;
    if (status == 'success' || status == 'approved') return Colors.green;
    if (status == 'rejected' || status == 'failed') return Colors.red;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1e293b), // Dark background (PHP body bg)
      appBar: AppBar(
        backgroundColor: const Color(0xFF0f172a),
        title: const Text("📜 My Transactions", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF10b981)))
          : RefreshIndicator(
              onRefresh: _fetchData, // Pull to refresh feature
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Wallet Balance Card (Gradient look like your CSS)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10b981), Color(0xFF059669)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8)],
                    ),
                    child: Center(
                      child: Text(
                        "💰 Wallet Balance: $_walletBalance Coins",
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Transactions List
                  if (_transactions.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 50),
                        child: Text("No Add Coin or Withdraw history yet.", style: TextStyle(color: Colors.white70)),
                      ),
                    )
                  else
                    ..._transactions.map((t) => _buildTransactionCard(t)),
                ],
              ),
            ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> t) {
    String type = t['type'] ?? '';
    bool isDeposit = type.toLowerCase() == 'deposit';
    String amountPrefix = isDeposit ? "+" : "-";
    Color amountColor = isDeposit ? const Color(0xFF16a34a) : const Color(0xFFdc2626);
    
    // Formatting Date
    String formattedDate = '';
    if (t['created_at'] != null) {
      DateTime dt = DateTime.parse(t['created_at']);
      formattedDate = DateFormat('dd/MM/yyyy hh:mm a').format(dt);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white, // White card as per your CSS
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                type.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
              ),
              Text(
                "$amountPrefix${t['amount']} Coins",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: amountColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Txn Ref: ${t['txn_ref']}",
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.black87, fontSize: 14),
                  children: [
                    const TextSpan(text: "Status: ", style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                      text: t['status'].toString().toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(t['status'].toString()),
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                formattedDate,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}