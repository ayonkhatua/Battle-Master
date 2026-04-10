import 'package:flutter/material.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

   // FAQ ka Data List (App ka naam 'Battle Master' kar diya hai)
  final List<Map<String, String>> _faqs = const [
    {
      "question": "Battle Master app kya hai?",
      "answer": "Battle Master ek premium eSports & gaming platform hai jahan aap matches join karke khel sakte hain aur real cash/coins earn kar sakte hain."
    },
    {
      "question": "Main apne account me coins kaise add kar sakta hoon?",
      "answer": "Aap 'My Wallet' section me jaake 'Add Coins' button par click karke UPI ke through asani se coins add kar sakte hain."
    },
    {
      "question": "Main apne jeete hue coins withdraw kaise karun?",
      "answer": "Aap 'My Wallet' section me jaake 'Withdraw' option chunein. Apna UPI ID ya Number daalein aur request submit karein. Minimum withdrawal 50 coins hai."
    },
    {
      "question": "Mujhe naye matches ki update kahan milegi?",
      "answer": "Aapko saare important updates, naye tournaments, aur announcements app ke 'Notifications' ya 'Announcements' section me milenge."
    },
    {
      "question": "Agar main password bhool jaun to kya karun?",
      "answer": "Aap Login screen par 'Forgot Password' ka option use karke apni registered email id par reset link mangwa sakte hain."
    },
    {
      "question": "Agar mujhe app me koi problem aaye to kya karun?",
      "answer": "Aap 'Contact Us' section me jaake hume directly Email, Telegram, ya Instagram par message kar sakte hain. Humari team jaldi se jaldi aapki madad karegi."
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1120), // 🌟 Premium Dark Theme
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text(
          "FAQ",
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
      body: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        itemCount: _faqs.length,
        itemBuilder: (context, index) {
          final faq = _faqs[index];
          
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withOpacity(0.8), // Dark Glassmorphic Card
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent), // Hides the inner divider line
              child: ExpansionTile(
                iconColor: const Color(0xFF3B82F6), // Blue drop-down arrow
                collapsedIconColor: Colors.white54,
                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                title: Text(
                  faq["question"]!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // White Question Text
                  ),
                ),
                children: [
                  Text(
                    faq["answer"]!,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.5, 
                      color: Colors.white54, // Dim white Answer Text
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}