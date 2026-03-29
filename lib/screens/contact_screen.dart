import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  _ContactScreenState createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  bool _isLoading = true;
  
  // 🌟 Hardcoded links hata diye hain. Default blank/loading rahega.
  String _adminEmail = "Loading...";
  String _telegramLink = "";
  String _instagramLink = "";

  @override
  void initState() {
    super.initState();
    _fetchContactDetails();
  }

  // 🌟 Supabase se App Config Data lana
  Future<void> _fetchContactDetails() async {
    try {
      final data = await Supabase.instance.client
          .from('app_config')
          // 🌟 FIX: Yahan exact column names daal diye hain jo aapne SQL se banaye the
          .select('admin_email, telegram_link, instagram_link') 
          .eq('id', 1)
          .maybeSingle();

      if (data != null && mounted) {
        setState(() {
          _adminEmail = data['admin_email'] ?? "Not Available";
          _telegramLink = data['telegram_link'] ?? "";
          _instagramLink = data['instagram_link'] ?? "";
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching contact details: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🌟 Link open karne ka universal function (With Safety)
  Future<void> _launchURL(String urlString) async {
    if (urlString.isEmpty) {
      _showSnackBar("⚠️ Link not updated by Admin yet!");
      return;
    }

    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        _showSnackBar("❌ Could not open link!");
      }
    } catch (e) {
      _showSnackBar("❌ Invalid Link Format!");
    }
  }

  void _copyToClipboard(String text, String type) {
    if (text == "Loading..." || text == "Not Available" || text.isEmpty) {
      _showSnackBar("⚠️ Email not available to copy!");
      return;
    }
    Clipboard.setData(ClipboardData(text: text));
    _showSnackBar("✅ $type Copied!");
  }

  void _showSnackBar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: const Color(0xFF3B82F6), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1120), // Deep Dark Theme
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text("SUPPORT CENTER", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF3B82F6)), 
        elevation: 0,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo or Header Graphic
                  Center(
                    child: Container(
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.5), width: 2),
                        boxShadow: [BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.2), blurRadius: 20)],
                      ),
                      child: const Icon(Icons.support_agent_rounded, size: 50, color: Color(0xFF3B82F6)),
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  const Text("HOW CAN WE HELP?", textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  const SizedBox(height: 20),

                  // 1. Email Box
                  _buildContactCard(
                    title: "Email Support",
                    subtitle: _adminEmail,
                    icon: Icons.email_rounded,
                    color: const Color(0xFFEF4444), // Red
                    onTap: () => _copyToClipboard(_adminEmail, "Email"),
                    actionText: "COPY",
                  ),
                  
                  const SizedBox(height: 15),

                  // 2. Telegram Box
                  _buildContactCard(
                    title: "Telegram Channel",
                    subtitle: "Join for fast updates & support",
                    icon: Icons.telegram,
                    color: const Color(0xFF0088CC), // Telegram Blue
                    onTap: () => _launchURL(_telegramLink),
                    actionText: "JOIN",
                  ),

                  const SizedBox(height: 15),

                  // 3. Instagram Box
                  _buildContactCard(
                    title: "Instagram",
                    subtitle: "Follow us for tournaments",
                    icon: Icons.camera_alt_rounded, // Stand-in for IG icon
                    color: const Color(0xFFE1306C), // Instagram Pink/Red
                    onTap: () => _launchURL(_instagramLink),
                    actionText: "FOLLOW",
                  ),

                  const SizedBox(height: 30),

                  // 4. Address Box (Static)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.location_on, color: Colors.white54, size: 24),
                        SizedBox(height: 10),
                        Text("BATTLE MASTER HQ", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                        SizedBox(height: 4),
                        Text("Based in India 🇮🇳", style: TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // 🌟 Sleek Glassmorphic Action Card
  Widget _buildContactCard({required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap, required String actionText}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5)),
          ],
        ),
        child: Row(
          children: [
            // Icon Box
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 15),
            
            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            
            // Action Button/Text
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                actionText, 
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}