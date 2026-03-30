import 'package:flutter/material.dart';
 
 class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1120), // 🌟 Deep Dark Esports Theme
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          "ANNOUNCEMENTS & RULES",
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF3B82F6)),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        physics: const BouncingScrollPhysics(),
        children: [
          // 🌟 TRUST & SUPPORT BADGE
          _buildNoticeCard(
            title: "100% SAFE & TRUSTED 🛡️",
            message: "Battle Master is a fully verified and secure platform. Your wallet balance and data are completely safe. If you face any issues with Add Coin or Withdrawals, directly contact our Customer Support from the 'Contact Us' page.",
            icon: Icons.verified_user_rounded,
            color: const Color(0xFF10B981), // Green
            isHighlight: true,
          ),
          
          const SizedBox(height: 25),
          const Padding(
            padding: EdgeInsets.only(left: 8.0, bottom: 10),
            child: Text("IMPORTANT RULES & LIMITS", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          ),

          // 🌟 RULE 1: Daily Match Limit
          _buildNoticeCard(
            title: "DAILY MATCH LIMIT (10/DAY)",
            message: "To maintain fair competition and healthy gaming habits, a single user can play a maximum of 10 tournament matches in a day. Choose your matches wisely!",
            icon: Icons.sports_esports_rounded,
            color: const Color(0xFFFACC15), // Yellow
          ),

          const SizedBox(height: 15),

          // 🌟 RULE 2: Health & Wellbeing (Break)
          _buildNoticeCard(
            title: "TAKE A BREAK! 🛑",
            message: "Continuous gaming is harmful to your health. You cannot play matches back-to-back all day. The system requires you to take mandatory breaks between continuous sessions. Play responsibly.",
            icon: Icons.health_and_safety_rounded,
            color: const Color(0xFFEF4444), // Red
          ),

          const SizedBox(height: 15),

          // 🌟 EXTRA RULE: Anti-Hack Policy
          _buildNoticeCard(
            title: "STRICT ANTI-HACK POLICY",
            message: "Use of hacks, scripts, aimbots, or teaming up in Solo matches is strictly prohibited. If caught, your account will be PERMANENTLY BANNED and your wallet balance will be zeroed out.",
            icon: Icons.gavel_rounded,
            color: const Color(0xFFF97316), // Orange
          ),

          const SizedBox(height: 25),
          const Padding(
            padding: EdgeInsets.only(left: 8.0, bottom: 10),
            child: Text("STAY CONNECTED", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          ),

          // 🌟 TELEGRAM CTA
          _buildNoticeCard(
            title: "JOIN OFFICIAL TELEGRAM 📢",
            message: "Room ID, Passwords, match updates, and instant giveaways are posted on our Telegram channel first! Go to the 'Contact Us' or 'Support' section and join our channel right now.",
            icon: Icons.telegram_rounded,
            color: const Color(0xFF0088CC), // Telegram Blue
          ),
          
          const SizedBox(height: 40), // Bottom padding
        ],
      ),
    );
  }

  // 🌟 Custom Widget for Premium Cards
  Widget _buildNoticeCard({
    required String title, 
    required String message, 
    required IconData icon, 
    required Color color,
    bool isHighlight = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Card background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(isHighlight ? 0.6 : 0.3), width: isHighlight ? 2 : 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Background subtle gradient/glow
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.1),
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(18.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon Box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const SizedBox(width: 16),
                  
                  // Text Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: isHighlight ? Colors.white : Colors.white, 
                            fontSize: 15, 
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          message,
                          style: const TextStyle(
                            color: Colors.white70, 
                            fontSize: 13, 
                            height: 1.5, // Line height for readability
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}