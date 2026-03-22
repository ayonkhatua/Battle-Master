import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  // Policy ka Data List (Tumhara actual PHP wala text)
  final List<Map<String, String>> _policies = const [
    {
      "title": "1. Data Collection",
      "text": "Battle Boom sirf wahi data collect karta hai jo aap account create karte waqt dete ho, jaise username, email address, aur phone number."
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
      backgroundColor: const Color(0xFF111827), // Dark Background
      appBar: AppBar(
        backgroundColor: const Color(0xFF1f2937),
        title: const Text(
          "Privacy Policy",
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 2,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            "Privacy Policy",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFFfacc15), // Yellow Title
            ),
          ),
          const SizedBox(height: 15),
          
          // Expanded zaroori hai taaki ListView bachi hui jagah le sake
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: _policies.length,
              itemBuilder: (context, index) {
                final policy = _policies[index];
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white, // White Box
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Policy Title (e.g., "1. Data Collection")
                      Text(
                        policy["title"]!,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1f2937), // Dark Gray
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Policy Description
                      Text(
                        policy["text"]!,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5, // Line height for easy reading
                          color: Color(0xFF374151), // Medium Gray
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}