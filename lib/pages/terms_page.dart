import 'package:flutter/material.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  // Terms ka Data List (Tumhara actual PHP wala text)
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
      backgroundColor: const Color(0xFF111827), // Dark Background
      appBar: AppBar(
        backgroundColor: const Color(0xFF1f2937),
        title: const Text(
          "Terms & Conditions",
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            // Page Title
            const Text(
              "Terms & Conditions",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFFfacc15), // Yellow Title
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            
            // Main Box containing all terms (Tumhara .box CSS)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1f2937), // Dark grey box
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              // Generate column of terms dynamically
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _terms.map((term) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Term Title (e.g., "1. Acceptance of Terms")
                        Text(
                          term["title"]!,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFfacc15), // Yellow
                          ),
                        ),
                        const SizedBox(height: 6),
                        
                        // Term Description
                        Text(
                          term["text"]!,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.6, // Line height for readability
                            color: Color(0xFFd1d5db), // Light Grey
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}