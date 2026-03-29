import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart'; // 🌟 Naya QR Package

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
  bool _isQrGenerated = false; // Naya variable flow control ke liye

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
      setState(() => _isFetchingConfig = false);
    }
  }

  void _copyUPI() {
    if (_upiId == "Loading..." || _upiId == "No UPI Found") return;
    Clipboard.setData(ClipboardData(text: _upiId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ UPI ID Copied!"), behavior: SnackBarBehavior.floating),
    );
  }

  // 🌟 Naya Function: QR Generate Karne Ke Liye
  void _generateQR() {
    FocusScope.of(context).unfocus(); // Keyboard hide karo
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
      _isQrGenerated = true; // Flow aage badhao
    });
  }

  Future<void> _submitRequest() async {
    final txnId = _txnController.text.trim();

    if (txnId.isEmpty) {
      _showError("⚠️ Please enter the Transaction ID");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception("User session expired.");

      await Supabase.instance.client.from('transactions').insert({
        'user_id': userId,
        'amount': _currentAmount, // Jo amount final hua hai
        'type': 'deposit',
        'txn_ref': txnId,
        'status': 'pending',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Request submitted successfully!"), backgroundColor: Colors.green),
      );

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context);
      });

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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.redAccent));
  }

  // 🌟 UPI string with specific amount logic
  String getUpiString() {
    // Format: upi://pay?pa=UPI_ID&pn=BattleMaster&am=AMOUNT&cu=INR
    return "upi://pay?pa=$_upiId&pn=BattleMaster&am=$_currentAmount&cu=INR";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1f2937),
        elevation: 0,
        title: const Text("Add Coins", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isFetchingConfig 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFfacc15)))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAmountSection(),
                
                // 🌟 Agar QR generate ho gaya hai toh baaki ka UI dikhao
                if (_isQrGenerated) ...[
                  const SizedBox(height: 25),
                  _buildPaymentCard(),
                  const SizedBox(height: 25),
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
      decoration: BoxDecoration(color: const Color(0xFF1f2937), borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Step 1: Enter Amount", style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          _buildTextField(
            controller: _amountController, 
            hint: "Enter Amount (e.g. 50)", 
            icon: Icons.currency_rupee, 
            isNumber: true,
            enabled: !_isQrGenerated // Agar QR ban gaya toh amount lock kar do
          ),
          const SizedBox(height: 15),
          
          if (!_isQrGenerated) 
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFfacc15),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _generateQR,
                child: const Text("Generate QR Code", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            
          if (_isQrGenerated)
            TextButton.icon(
              onPressed: () => setState(() => _isQrGenerated = false),
              icon: const Icon(Icons.edit, color: Colors.white54, size: 16),
              label: const Text("Change Amount", style: TextStyle(color: Colors.white54)),
            )
        ],
      ),
    );
  }

  Widget _buildPaymentCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1f2937),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFfacc15).withOpacity(0.5)),
      ),
      child: Column(
        children: [
          const Text("Step 2: Scan & Pay", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text("Pay exactly ₹$_currentAmount", style: const TextStyle(color: Color(0xFFfacc15), fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          
          // 🌟 Dynamic QR Code Builder
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: QrImageView(
              data: getUpiString(),
              version: QrVersions.auto,
              size: 180.0,
            ),
          ),
          
          const SizedBox(height: 20),
          const Text("Or copy UPI ID", style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _copyUPI,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: const Color(0xFF111827), borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_upiId, style: const TextStyle(color: Colors.white, fontSize: 14)),
                  const SizedBox(width: 10),
                  const Icon(Icons.copy, color: Color(0xFFfacc15), size: 16),
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
      decoration: BoxDecoration(color: const Color(0xFF1f2937), borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Step 3: Submit Details", style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          _buildTextField(
            controller: _txnController, 
            hint: "Enter 12-digit Ref No. / Txn ID", 
            icon: Icons.numbers, 
            isNumber: false
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563eb),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _isLoading ? null : _submitRequest,
              child: _isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text("Submit Deposit Request", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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
      style: TextStyle(color: enabled ? Colors.white : Colors.grey),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey, size: 20),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        filled: true,
        fillColor: enabled ? const Color(0xFF374151) : const Color(0xFF111827),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }
}