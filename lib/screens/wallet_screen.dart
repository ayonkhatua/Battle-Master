import 'package:flutter/material.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  _WalletPageState createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  // TODO: Ye data aapko apni PHP API se fetch karna hoga
  final String userCoins = "1,500";
  final String deposited = "500";
  final String winning = "800";
  final String bonus = "200";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827), // Dark background
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        elevation: 0,
        title: const Text('My Wallet', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 🔝 Coin Balance Section
              const SizedBox(height: 10),
              Center(
                child: Column(
                  children: [
                    Image.network('https://img.icons8.com/emoji/48/coin-emoji.png', width: 45, height: 45),
                    const SizedBox(height: 8),
                    Text(
                      '$userCoins Coins',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFACC15), // Yellow color
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // 🔹 Deposited / Winning / Bonus Stats Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: _buildStatBox('Deposited', deposited)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildStatBox('Winning', winning)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildStatBox('Bonus', bonus)),
                ],
              ),
              const SizedBox(height: 30),

              // 🔹 Wallet Actions Section
              const Text(
                'My Wallet Actions',
                style: TextStyle(fontSize: 18, color: Color(0xFFFACC15), fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _buildActionBox(
                      'Add Coin',
                      'https://img.icons8.com/fluency/48/money-bag.png',
                      () {
                        // TODO: Add Coin Page par navigate karein
                        print("Navigate to Add Coin");
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildActionBox(
                      'Withdraw',
                      'https://img.icons8.com/fluency/48/cash-in-hand.png',
                      () {
                        // TODO: Withdraw Page par navigate karein
                        print("Navigate to Withdraw");
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildActionBox(
                      'Transactions',
                      'https://img.icons8.com/fluency/48/bill.png',
                      () {
                        // TODO: Transactions Page par navigate karein
                        print("Navigate to Transactions");
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🛠️ Widget for Stat Box (Deposited, Winning, Bonus)
  Widget _buildStatBox(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.network('https://img.icons8.com/emoji/48/coin-emoji.png', width: 16, height: 16),
              const SizedBox(width: 4),
              Text(title, style: const TextStyle(fontSize: 12, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFACC15)),
          ),
          const SizedBox(height: 2),
          const Text('Coins', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
        ],
      ),
    );
  }

  // 🛠️ Widget for Action Box (Add, Withdraw, History)
  Widget _buildActionBox(String title, String iconUrl, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF2563EB), // Blue Action Color
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(iconUrl, width: 26, height: 26),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}