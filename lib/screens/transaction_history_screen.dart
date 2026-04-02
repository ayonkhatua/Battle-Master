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
  int _currentWalletBalance = 0;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      // 1. Fetch current wallet balance to calculate closing balances backwards
      final userRes = await Supabase.instance.client
          .from('users')
          .select('wallet_balance')
          .eq('id', user.id)
          .single();

      int currentBal = userRes['wallet_balance'] ?? 0;

      // 2. Fetch ALL Transactions
      final txnRes = await Supabase.instance.client
          .from('transactions')
          .select('type, amount, txn_ref, status, created_at')
          .eq('user_id', user.id)
          .order('created_at', ascending: false) // Sabse naya sabse upar
          .limit(50); 

      // 🌟 MAGIC LOGIC: Reverse Calculate Closing Balances
      // Since transactions are descending, we go backwards from current balance
      List<Map<String, dynamic>> processedList = [];
      int runningBalance = currentBal;

      for (var txn in txnRes) {
        String type = (txn['type'] ?? 'Unknown').toString().toLowerCase();
        int amount = int.tryParse(txn['amount'].toString()) ?? 0;
        String status = (txn['status'] ?? '').toString().toLowerCase();
        
        bool isCredit = ['deposit', 'deposited', 'winning', 'bonus', 'credit'].contains(type);
        
        // Is transaction ke baad kya balance tha
        txn['closing_balance'] = runningBalance; 
        
        // Next (older) transaction ke liye running balance adjust karo
        if (status == 'approved' || status == 'success' || status == 'pending') {
             if (isCredit) {
                runningBalance -= amount;
             } else {
                runningBalance += amount;
             }
        }
        
        processedList.add(txn);
      }

      if (mounted) {
        setState(() {
          _currentWalletBalance = currentBal;
          _transactions = processedList;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching transactions: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🌟 NAYA FIX: Sirf Transaction Title Formatting Ko Perfect Kiya Hai
  String _formatTransactionTitle(String type, String ref, String status) {
    type = type.toLowerCase();
    
    // Agar status pending/rejected hai, toh wo bhi dikhao
    String suffix = "";
    if (status.toLowerCase() != 'success' && status.toLowerCase() != 'approved') {
      suffix = " (${status.toUpperCase()})";
    }

    if (type == 'winning' || type == 'reward') return 'Match Reward - #$ref$suffix';
    if (type == 'join' || type == 'joined') return 'Match Joined - #$ref$suffix';
    
    // Deposit admin ka hai ya user ka, use simple rakha hai taaki image se match kare
    if (type == 'deposit' || type == 'deposited') return 'Money Added to Wallet - #$ref$suffix';
    if (type == 'admin_add') return 'Add Money to Wallet By Admin - #$ref$suffix'; // Extra case agar type admin_add ho
    
    if (type == 'withdraw') return 'Withdraw Money from Wallet - #$ref$suffix';
    if (type == 'bonus') return 'Bonus Added - #$ref$suffix';
    
    return '${type.toUpperCase()} - #$ref$suffix';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1120), 
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        title: const Text("TRANSACTIONS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.2)),
        centerTitle: true, 
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFFACC15)), 
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
          : RefreshIndicator(
              onRefresh: _fetchData,
              color: const Color(0xFF0B1120),
              backgroundColor: const Color(0xFF3B82F6),
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

  Widget _buildTransactionCard(Map<String, dynamic> t) {
    String type = t['type'] ?? 'Unknown';
    String status = t['status'] ?? 'pending';
    int amount = int.tryParse(t['amount'].toString()) ?? 0;
    int closingBalance = t['closing_balance'] ?? 0;
    
    bool isCredit = ['deposit', 'deposited', 'winning', 'bonus', 'credit'].contains(type.toLowerCase());
    String amountPrefix = isCredit ? "+" : "-";
    
    Color creditColor = const Color(0xFF10B981); 
    Color debitColor = const Color(0xFF3B82F6);  

    Color typeColor = isCredit ? Colors.white : debitColor; 
    Color amountColor = Colors.white; 

    String formattedDate = '';
    if (t['created_at'] != null) {
      DateTime dt = DateTime.parse(t['created_at']).toLocal(); 
      formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(dt);
    }

    String displayTitle = _formatTransactionTitle(type, t['txn_ref'].toString(), status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 15),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.8), 
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. LEFT TEXT (CREDIT/DEBIT)
          SizedBox(
            width: 65,
            child: Text(
              isCredit ? "CREDIT" : "DEBIT",
              style: TextStyle(
                color: typeColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          
          // 2. MIDDLE DETAILS (Title & Date)
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
                  style: const TextStyle(color: Colors.white54, fontSize: 11), 
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 5),
          
          // 3. RIGHT SIDE (Plus/Minus & Total Balance)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "$amountPrefix ",
                    style: TextStyle(color: amountColor, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Image.network('https://img.icons8.com/emoji/48/coin-emoji.png', width: 14, height: 14),
                  const SizedBox(width: 4),
                  Text(
                    amount.toString(),
                    style: TextStyle(color: amountColor, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.network('https://img.icons8.com/emoji/48/coin-emoji.png', width: 14, height: 14),
                  const SizedBox(width: 4),
                  Text(
                    "$closingBalance.0",
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
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