import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart'; 

class AddCoinScreen extends StatefulWidget {
  const AddCoinScreen({super.key});

  @override
  _AddCoinScreenState createState() => _AddCoinScreenState();
}

class _AddCoinScreenState extends State<AddCoinScreen> {
  final _amountController = TextEditingController();
  final _txnController = TextEditingController();
  
  bool _isLoading = false;
  bool _isFetchingConfig = true;
  bool _isQrGenerated = false; 

  String _upiId = "Loading..."; 
  int _currentAmount = 0;

  @override
  void initState() {
    super.initState();
    _fetchAppConfig();
  }

  Future<void> _fetchAppConfig() async {
    try {
      final data = await Supabase.instance.client
          .from('app_config')
          .select('upi_id')
          .eq('id', 1)
          .maybeSingle();

      if (data != null && mounted) {
        setState(() {
          _upiId = data['upi_id'] ?? "No UPI Found";
          _isFetchingConfig = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isFetchingConfig = false);
    }
  }

  void _copyUPI() {
    if (_upiId == "Loading..." || _upiId == "No UPI Found") return;
    Clipboard.setData(ClipboardData(text: _upiId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ UPI ID Copied!"), behavior: SnackBarBehavior.floating, backgroundColor: Colors.green),
    );
  }

  void _generateQR() {
    FocusScope.of(context).unfocus(); 
    final amountText = _amountController.text.trim();
    
    if (amountText.isEmpty) {
      _showError("⚠️ Please enter an amount first.");
      return;
    }

    final amount = int.tryParse(amountText);
    if (amount == null || amount < 10) {
      _showError("⚠️ Minimum deposit amount is ₹10");
      return;
    }

    if (_upiId == "Loading..." || _upiId == "No UPI Found") {
      _showError("⚠️ UPI ID not found. Contact Admin.");
      return;
    }

    setState(() {
      _currentAmount = amount;
      _isQrGenerated = true; 
    });
  }

  Future<void> _submitRequest() async {
    final txnId = _txnController.text.trim();

    if (txnId.isEmpty) {
      _showError("⚠️ Please enter the 12-digit UTR/Txn ID");
      return;
    }

    if (txnId.length < 8) {
      _showError("⚠️ Invalid Txn ID. Please check again.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception("User session expired.");

      await Supabase.instance.client.from('transactions').insert({
        'user_id': userId,
        'amount': _currentAmount, 
        'type': 'deposit',
        'txn_ref': txnId,
        'status': 'pending',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Request submitted! Coins will be added soon."), backgroundColor: Colors.green),
        );
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
      }

    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        _showError("❌ This Transaction ID is already submitted!");
      } else {
        _showError("❌ Database Error: ${e.message}");
      }
    } catch (e) {
      _showError("❌ Something went wrong. Try again.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating));
  }

  String getUpiString() {
    return "upi://pay?pa=$_upiId&pn=BattleMaster&am=$_currentAmount&cu=INR";
  }

  // 🌟 Quick Amount Button Logic
  void _setQuickAmount(int amount) {
    setState(() {
      _amountController.text = amount.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1120), // Premium Dark Theme
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: const Text("ADD COINS", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 16, letterSpacing: 1.2)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isFetchingConfig 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
        : SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAmountSection(),
                
                if (_isQrGenerated) ...[
                  const SizedBox(height: 20),
                  _buildPaymentCard(),
                  const SizedBox(height: 20),
                  _buildSubmitSection(),
                ]
              ],
            ),
          ),
    );
  }

  Widget _buildAmountSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), 
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Step 1: Enter Amount", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          
          _buildTextField(
            controller: _amountController, 
            hint: "Enter Amount (Min ₹10)", 
            icon: Icons.currency_rupee, 
            isNumber: true,
            enabled: !_isQrGenerated 
          ),
          
          // 🌟 Quick Amount Buttons (Sirf tab dikhenge jab QR generate nahi hua ho)
          if (!_isQrGenerated) ...[
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildQuickAmountChip(50),
                _buildQuickAmountChip(100),
                _buildQuickAmountChip(200),
                _buildQuickAmountChip(500),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 5,
                ),
                onPressed: _generateQR,
                child: const Text("PROCEED TO PAY", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
              ),
            ),
          ],
            
          if (_isQrGenerated)
            Padding(
              padding: const EdgeInsets.only(top: 15),
              child: Center(
                child: TextButton.icon(
                  onPressed: () => setState(() => _isQrGenerated = false),
                  icon: const Icon(Icons.edit, color: Colors.amberAccent, size: 16),
                  label: const Text("Change Amount", style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold)),
                ),
              ),
            )
        ],
      ),
    );
  }

  // Quick amount chip widget
  Widget _buildQuickAmountChip(int amount) {
    return GestureDetector(
      onTap: () => _setQuickAmount(amount),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white12),
        ),
        child: Text("+₹$amount", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13)),
      ),
    );
  }

  Widget _buildPaymentCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amberAccent.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.amberAccent.withOpacity(0.1), blurRadius: 20, spreadRadius: 1)
        ]
      ),
      child: Column(
        children: [
          const Text("Step 2: Scan & Pay", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Pay exactly: ", style: TextStyle(color: Colors.white70, fontSize: 16)),
              Text("₹$_currentAmount", style: const TextStyle(color: Colors.greenAccent, fontSize: 24, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 20),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: QrImageView(
              data: getUpiString(),
              version: QrVersions.auto,
              size: 180.0,
            ),
          ),
          
          const SizedBox(height: 25),
          const Text("OR PAY VIA UPI ID", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _copyUPI,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white10)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_upiId, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 15),
                  const Icon(Icons.copy_rounded, color: Colors.blueAccent, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), 
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Step 3: Submit UTR", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          
          _buildTextField(
            controller: _txnController, 
            hint: "Enter 12-digit UTR / Ref No.", 
            icon: Icons.tag, 
            isNumber: true // UTR mostly numbers hota hai
          ),
          const SizedBox(height: 12),
          
          // 🌟 Fake UTR Warning Box
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.redAccent.withOpacity(0.3))
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: const Text(
                    "Warning: Submitting fake UTR will lead to permanent account BAN.",
                    style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent.shade700,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _isLoading ? null : _submitRequest,
              child: _isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text("SUBMIT PAYMENT", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.0)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hint, required IconData icon, required bool isNumber, bool enabled = true}) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: TextStyle(color: enabled ? Colors.white : Colors.white54, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: enabled ? const Color(0xFF3B82F6) : Colors.grey, size: 20),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 13, fontWeight: FontWeight.normal),
        filled: true,
        fillColor: const Color(0xFF0F172A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
    );
  }
}