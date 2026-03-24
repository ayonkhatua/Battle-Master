import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class BlockedScreen extends StatefulWidget {
  const BlockedScreen({super.key});

  @override
  _BlockedScreenState createState() => _BlockedScreenState();
}

class _BlockedScreenState extends State<BlockedScreen> {
  bool _isLoading = true;
  String _contactUsLink = '';

  @override
  void initState() {
    super.initState();
    _fetchContactLink();
  }

  Future<void> _fetchContactLink() async {
    try {
      final response = await Supabase.instance.client
          .from('app_config')
          .select('contact_us_link')
          .eq('id', 1)
          .single();

      setState(() {
        _contactUsLink = response['contact_us_link']?.toString() ?? '';
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching contact link: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openTelegram() async {
    if (_contactUsLink.isEmpty) return;
    
    final Uri url = Uri.parse(_contactUsLink);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Telegram link')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevents user from going back using hardware back button
      child: Scaffold(
        backgroundColor: const Color(0xFF111827), // Dark Theme
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.block, color: Colors.redAccent, size: 80),
                const SizedBox(height: 20),
                const Text(
                  "Account Blocked",
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Your account has been blocked by the Administrator. If you think this is a mistake, please contact support.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
                ),
                const SizedBox(height: 30),
                if (_isLoading)
                  const CircularProgressIndicator(color: Color(0xFFfacc15))
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563eb), // Blue color
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _openTelegram,
                      icon: const Icon(Icons.telegram, color: Colors.white),
                      label: const Text("Contact Us", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}