import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  // Link open karne ka function
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint("Could not launch $urlString");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827), // Dark background
      appBar: AppBar(
        backgroundColor: const Color(0xFF1f2937),
        title: const Text(
          "Contact Us",
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          children: [
            // 1. Contact Us Box
            _buildWhiteBox(
              title: "Contact Us",
              child: Column(
                children: [
                  const Text(
                    "📧 Email: yourmail@example.com", // Client ka actual email yahan daalna
                    style: TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildBlueButton(
                          "Telegram", 
                          () => _launchURL("https://t.me/BattleMasterHost")
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildBlueButton(
                          "Instagram", 
                          () => _launchURL("https://instagram.com/battlemasterofficial?igsh=Yjgya3I1dHBvZDJ2")
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 20),

            // 2. Address Box
            _buildWhiteBox(
              title: "Our Address",
              child: const Center(
                child: Text(
                  "📍 India",
                  style: TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.w500),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 3. Follow Us Box
            _buildWhiteBox(
              title: "Follow Us",
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildCircleIcon(
                    "https://img.icons8.com/3d-fluency/94/telegram.png",
                    () => _launchURL("https://t.me/battlemastersofficial"),
                  ),
                  const SizedBox(width: 30),
                  _buildCircleIcon(
                    "https://img.icons8.com/3d-fluency/94/instagram-logo.png",
                    () => _launchURL("https://www.instagram.com/battlemasterofficial?igsh=Yjgya3I1dHBvZDJ2"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Reusable UI Widgets ---

  // White box with Red Title (Tumhara custom CSS style)
  Widget _buildWhiteBox({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 15, right: 15, bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 5, offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          // Red Title Badge
          Container(
            transform: Matrix4.translationValues(0.0, -15.0, 0.0), // Box se thoda upar nikalne ke liye
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          // Box ka content
          child,
        ],
      ),
    );
  }

  // Blue Link Button
  Widget _buildBlueButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2563eb),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Circle Follow Icons
  Widget _buildCircleIcon(String imageUrl, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Ink(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: NetworkImage(imageUrl),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}