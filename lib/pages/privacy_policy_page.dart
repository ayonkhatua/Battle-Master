import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  // Policy ka Data List (App ka naam 'Battle Master' kar diya hai)
  final List<Map<String, String>> _policies = const [
    {
      "title": "1. Data Collection",
      "text": "Battle Master sirf wahi data collect karta hai jo aap account create karte waqt dete ho, jaise username, email address, aur phone number."
    },
    {
      "title": "2. Data Usage",
      "text": "Aapke data ka use sirf account verification, notifications, aur aapke game progress track karne ke liye kiya jata hai. Hum aapke data ko kisi third party ko sell ya share nahi karte."
    },
    {
      "title": "3. Coins & Transactions",
      "text": "Wallet me jo bhi deposited, winning, aur bonus coins hain wo sirf in-app use ke liye hain. Transactions secure payment gateways ke through handle kiye jate hain."
    },
    {
      "title": "4. Security",
      "text": "Hum aapke account aur personal data ko secure rakhne ke liye strong encryption aur safety measures use karte hain."
    },
    {
      "title": "5. Updates",
      "text": "Privacy Policy kabhi bhi update ho sakti hai. Agar koi major change hoga to aapko Notifications section me inform kiya jayega."
    },
    {
      "title": "6. Contact Us",
      "text": "Agar aapko apne data ke baare me koi doubt hai to aap hume Contact Us section ke through reach kar sakte ho."
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1120), // 🌟 Premium Dark Theme
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text(
          "PRIVACY POLICY",
          style: TextStyle(
            color: Colors.white, 
            fontSize: 16, 
            fontWeight: FontWeight.w900, 
            letterSpacing: 1.5
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.white.withOpacity(0.05),
            height: 1.0,
          ),
        ),
      ),
      // 🌟 Extra yellow title aur column hata diya. Seedha ListView chalaya hai.
      body: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        itemCount: _policies.length,
        itemBuilder: (context, index) {
          final policy = _policies[index];
          
          return Container(
            margin: const EdgeInsets.only(bottom: 15),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withOpacity(0.8), // Dark Glassmorphic Card
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Policy Title 
                Text(
                  policy["title"]!,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3B82F6), // Light Blue for headings
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Policy Description
                Text(
                  policy["text"]!,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.6, // Thoda aur gap padhne me aasani ke liye
                    color: Colors.white70, // Dim White for description
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}