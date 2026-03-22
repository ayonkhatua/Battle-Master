import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Copy to clipboard ke liye
import 'package:supabase_flutter/supabase_flutter.dart';

class AddCoinScreen extends StatefulWidget {
  const AddCoinScreen({super.key});

  @override
  _AddCoinScreenState createState() => _AddCoinScreenState();
}

class _AddCoinScreenState extends State<AddCoinScreen> {
  final _amountController = TextEditingController();
  final _txnController = TextEditingController();
  bool _isLoading = false;

  final String _upiId = "yourupi@fam"; // Yahan client ka asli UPI ID aayega

  // UPI ID copy karne ka function
  void _copyUPI() {
    Clipboard.setData(ClipboardData(text: _upiId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ UPI ID Copied!"), duration: Duration(seconds: 2)),
    );
  }

  Future<void> _submitRequest() async {
    final amountText = _amountController.text.trim();
    final txnId = _txnController.text.trim();

    if (amountText.isEmpty || txnId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Please fill all fields")));
      return;
    }

    final int? amount = int.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Enter a valid amount")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception("User not logged in");

      // Supabase Insert Logic (Same as your PHP)
      await Supabase.instance.client.from('transactions').insert({
        'user_id': userId,
        'amount': amount,
        'type': 'deposit',
        'txn_ref': txnId,
        'status': 'pending',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Request submitted! Pending Admin Approval."), backgroundColor: Colors.green),
      );

      // TextBox clear kar do taaki dobara same submit na ho
      _amountController.clear();
      _txnController.clear();
      
      // TODO: Wapas Wallet screen par bhej do
      // Navigator.pop(context); 

    } catch (e) {
      print("Add coin error: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("❌ Failed to submit request")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827), // Dark Background
      appBar: AppBar(
        backgroundColor: const Color(0xFF1f2937),
        title: const Text("Add Coin", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: const Color(0xFF1f2937),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Add Coin", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFfacc15))),
                const SizedBox(height: 20),

                // Payment Box
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(color: const Color(0xFF374151), borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    children: [
                      const Text("📌 Scan QR or Pay via UPI", style: TextStyle(color: Colors.white, fontSize: 14)),
                      const SizedBox(height: 10),
                      
                      // QR Image
                      Container(
                        height: 150,
                        width: 150,
                        color: Colors.white,
                        child: const Center(child: Text("QR Image Here", style: TextStyle(color: Colors.black))),
                        // Asli image ke liye: Image.asset('assets/qr.png')
                      ),
                      const SizedBox(height: 15),

                      // UPI ID with Copy Button
                      GestureDetector(
                        onTap: _copyUPI,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(color: const Color(0xFF1e293b), borderRadius: BorderRadius.circular(6)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_upiId, style: const TextStyle(color: Color(0xFFfacc15), fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              const Icon(Icons.copy, color: Color(0xFFfacc15), size: 16),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Inputs
                _buildInput(_amountController, "Enter Amount", isNumber: true),
                const SizedBox(height: 15),
                _buildInput(_txnController, "Enter Transaction ID"),
                const SizedBox(height: 20),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563eb),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _isLoading ? null : _submitRequest,
                    child: _isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Submit Request", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String hint, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFF374151),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}