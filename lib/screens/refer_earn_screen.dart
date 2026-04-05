import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';

class ReferEarnScreen extends StatefulWidget {
  const ReferEarnScreen({super.key});

  @override
  State<ReferEarnScreen> createState() => _ReferEarnScreenState();
}

class _ReferEarnScreenState extends State<ReferEarnScreen> {
  bool _isLoading = true;
  String _referCode = "";
  // 🌟 TUMHARA LANDING PAGE LINK
  final String _appBaseLink = "https://battlemasterofficial.vercel.app"; 

  @override
  void initState() {
    super.initState();
    _fetchReferralCode();
  }

  // 🌟 Database se user ka unique code nikalna
  Future<void> _fetchReferralCode() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final response = await Supabase.instance.client
            .from('users')
            .select('fcode') // fcode column tumhare DB me hoga
            .eq('id', user.id)
            .maybeSingle();

        if (response != null && mounted) {
          setState(() {
            _referCode = response['fcode'] ?? "BATTLE123"; 
            _isLoading = false;
          });
        }
      } catch (e) {
        debugPrint("Error fetching code: $e");
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  // 🌟 Code Copy karne ka function
  void _copyToClipboard() {
    if (_referCode.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _referCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("✅ Referral Code Copied!"),
        backgroundColor: Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // 🌟 Link Share karne ka function
  void _shareLink() {
    if (_referCode.isEmpty) return;
    
    final String shareText = 
        "🎮 Play Free Fire Tournaments & Earn Real Money on Battle Master!\n\n"
        "🎁 Use my invite link to get 3 COINS Welcome Bonus instantly.\n"
        // 🌟 LINK MEIN ?ref= JOD DIYA HAI
        "Link: $_appBaseLink/?ref=$_referCode\n\n"
        "Or use my code: $_referCode during signup!";
    
    Share.share(shareText);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1120), 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("REFER & EARN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 18)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF3B82F6)),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
        : SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 🌟 TOP ILLUSTRATION / HERO SECTION
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 120,
                      width: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFF59E0B).withOpacity(0.1),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFFF59E0B).withOpacity(0.3), blurRadius: 40, spreadRadius: 10),
                        ],
                      ),
                    ),
                    const Icon(Icons.redeem_rounded, size: 80, color: Color(0xFFF59E0B)),
                  ],
                ),
                const SizedBox(height: 25),
                
                const Text(
                  "INVITE FRIENDS & EARN COINS",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Share your link. When your friend makes their first deposit, you get 5 Coins and they get 3 Coins!",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.5, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 35),

                // 🌟 YOUR CODE BOX
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.5), width: 1.5),
                  ),
                  child: Column(
                    children: [
                      const Text("YOUR REFERRAL CODE", style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _referCode,
                            style: const TextStyle(color: Colors.amberAccent, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 3.0),
                          ),
                          const SizedBox(width: 15),
                          GestureDetector(
                            onTap: _copyToClipboard,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: const Color(0xFF3B82F6).withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.copy_rounded, color: Color(0xFF3B82F6), size: 20),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 35),

                // 🌟 HOW IT WORKS (STEPS)
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("HOW IT WORKS", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                ),
                const SizedBox(height: 15),
                _buildStepCard("1", "Share Your Link", "Send your unique link or code to your friends.", Icons.share_rounded, const Color(0xFF3B82F6)),
                _buildStepCard("2", "Friend Joins", "They sign up and get 3 Coins as a Welcome Bonus.", Icons.person_add_rounded, const Color(0xFF10B981)),
                _buildStepCard("3", "You Earn 5 Coins", "When they make their first deposit, you earn 5 Coins!", Icons.monetization_on_rounded, const Color(0xFFF59E0B)),

                const SizedBox(height: 40),

                // 🌟 MASSIVE SHARE BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      elevation: 10,
                      shadowColor: const Color(0xFF3B82F6).withOpacity(0.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.share_rounded, size: 22),
                    label: const Text("SHARE LINK NOW", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                    onPressed: _shareLink,
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
    );
  }

  // Helper Widget for Steps
  Widget _buildStepCard(String stepNum, String title, String desc, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            height: 45, width: 45,
            decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
            child: Center(child: Icon(icon, color: color, size: 22)),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.4)),
              ],
            ),
          )
        ],
      ),
    );
  }
}