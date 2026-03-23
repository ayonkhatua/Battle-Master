import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CoinAddScreen extends StatefulWidget {
  const CoinAddScreen({super.key});

  @override
  State<CoinAddScreen> createState() => _CoinAddScreenState();
}

class _CoinAddScreenState extends State<CoinAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _selectedBucket = 'deposited';
  bool _isLoading = false;
  String _message = '';
  bool _isError = false;

  Future<void> _addCoins() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _message = '';
      _isError = false;
    });

    final identifier = _identifierController.text;
    final amount = int.tryParse(_amountController.text);
    final note = _noteController.text;

    try {
      // Step 1: Find the user by username or mobile
      final userResponse = await Supabase.instance.client
          .from('users')
          .select('id, username')
          .or('username.eq.$identifier,mobile.eq.$identifier')
          .maybeSingle();

      if (userResponse == null) {
        throw 'User not found with that username or mobile.';
      }

      final userId = userResponse['id'];
      final userName = userResponse['username'];

      // Step 2: Call the RPC function
      await Supabase.instance.client.rpc('admin_add_coins', params: {
        'p_user_id': userId,
        'p_amount': amount,
        'p_bucket': _selectedBucket,
        'p_note': note,
      });

      // Success
      setState(() {
        _message =
            '✅ Successfully added $amount coins to user $userName.';
        _isError = false;
        _formKey.currentState?.reset();
        _identifierController.clear();
        _amountController.clear();
        _noteController.clear();
        _selectedBucket = 'deposited';
      });
    } catch (e) {
      // Handle errors
      final errorMessage = e is PostgrestException ? e.message : e.toString();
      setState(() {
        _message = '❌ Operation failed: $errorMessage';
        _isError = true;
      });
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
      backgroundColor: Colors.transparent,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Container(
            width: 540,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF0B1220),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Add Coins to User Account', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.amberAccent)),
                  const SizedBox(height: 20),
                  if (_message.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: _isError ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                        border: Border.all(color: _isError ? Colors.redAccent : Colors.greenAccent),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_message, style: TextStyle(color: _isError ? Colors.redAccent : Colors.greenAccent)),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextFormField(
                    controller: _identifierController,
                    decoration: const InputDecoration(labelText: 'Username or Mobile'),
                    validator: (v) => v!.isEmpty ? 'This field is required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Amount (integer coins)'),
                    validator: (v) {
                      if (v!.isEmpty) return 'Amount is required';
                      if (int.tryParse(v) == null || int.parse(v) <= 0) return 'Must be a positive integer';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedBucket,
                    decoration: const InputDecoration(labelText: 'Credit Bucket'),
                    items: const [
                      DropdownMenuItem(value: 'deposited', child: Text('Deposited')),
                      DropdownMenuItem(value: 'winning', child: Text('Winning')),
                      DropdownMenuItem(value: 'bonus', child: Text('Bonus')),
                    ],
                    onChanged: (v) => setState(() => _selectedBucket = v!),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _noteController,
                    decoration: const InputDecoration(labelText: 'Note (optional)'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(onPressed: _addCoins, child: const Text('Add Coins'), style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
