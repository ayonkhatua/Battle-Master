import 'package:flutter/material.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  // Terms ka Data List 
  final List<Map<String, String>> _terms = const [
    {
      "title": "1. Acceptance of Terms",
      "text": "By using this app, you agree to follow these Terms & Conditions. Please read them carefully."
    },
    {
      "title": "2. User Responsibilities",
      "text": "Users are responsible for the accuracy of their account details and for keeping their login credentials safe."
    },
    {
      "title": "3. Coins & Rewards",
      "text": "All coins and rewards are virtual and have no real-world monetary value outside this app."
    },
    {
      "title": "4. Fair Play",
      "text": "Cheating, exploiting bugs, or using unauthorized tools may result in suspension or account termination."
    },
    {
      "title": "5. Updates",
      "text": "We may update these terms at any time. Continued use of the app means you accept the updated terms."
    },
    {
      "title": "6. Contact",
      "text": "If you have questions about these terms, please contact us through the official support section in the app."
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1120), // 🌟 Premium Dark Theme Background
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text(
          "TERMS & CONDITIONS", // 🌟 Caps lock aur spacing ke sath premium look
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
      // 🌟 Single bade dabe ko hatakar, smooth list view laga diya hai
      body: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        itemCount: _terms.length,
        itemBuilder: (context, index) {
          final term = _terms[index];
          
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
                // Term Title 
                Text(
                  term["title"]!,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3B82F6), // Light Blue for headings
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Term Description
                Text(
                  term["text"]!,
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