import 'package:flutter/material.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  // FAQ ka Data List (Yahan naye questions add karna bohot asaan hai)
  final List<Map<String, String>> _faqs = const [
    {
      "question": "Battle Boom app kya hai?",
      "answer": "Battle Boom ek eSports & gaming platform hai jisme aap matches join karke play kar sakte ho aur coins earn kar sakte ho."
    },
    {
      "question": "Main apne account me coins kaise add kar sakta hoon?",
      "answer": "Aap 'My Wallet' section me jaake Add Coins option se coins add kar sakte ho."
    },
    {
      "question": "Main apne coins ko withdraw kaise karun?",
      "answer": "Aap 'My Wallet' section me jaake Withdraw Coins option se coins withdraw kar sakte ho."
    },
    {
      "question": "Mujhe notification kahan milenge?",
      "answer": "Aapko saare important updates aur announcements Notifications section me milenge."
    },
    {
      "question": "Agar main password bhool jaun to kya karun?",
      "answer": "Aap 'My Profile' section me jaake Reset Password option use karke apna password reset kar sakte ho."
    },
    {
      "question": "Agar mujhe koi problem aaye to support se kaise contact karun?",
      "answer": "Aap 'Contact Us' section se hume directly email, Telegram, ya Instagram par contact kar sakte ho."
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827), // Dark Background
      appBar: AppBar(
        backgroundColor: const Color(0xFF1f2937),
        title: const Text(
          "FAQ",
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
            "Frequently Asked Questions",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFFfacc15), // Yellow Title
            ),
          ),
          const SizedBox(height: 15),
          
          // Expanded zaroori hai taaki ListView poori bachi hui jagah le sake
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: _faqs.length,
              itemBuilder: (context, index) {
                final faq = _faqs[index];
                
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
                      // Question
                      Text(
                        faq["question"]!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1f2937), // Dark Gray
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Answer
                      Text(
                        faq["answer"]!,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.4, // Line height for readability
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