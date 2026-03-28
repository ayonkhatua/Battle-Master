import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:carousel_slider/carousel_slider.dart';

// Screens for navigation
import 'package:battle_master/screens/profile_screen.dart';
import 'package:battle_master/screens/wallet_screen.dart';
import 'package:battle_master/screens/statistics_screen.dart';
import 'package:battle_master/screens/ongoing_screen.dart'; // Path sahi se check kar lena
import 'package:battle_master/screens/completed_screen.dart';
import 'package:battle_master/screens/upcoming_screen.dart';
import 'package:battle_master/screens/game_screen.dart'; // TournamentScreen yahan se aayegi
import 'package:battle_master/screens/login_screen.dart';
import 'package:battle_master/pages/faq_page.dart';
import 'package:battle_master/pages/privacy_policy_page.dart';
import 'package:battle_master/pages/terms_page.dart';
import 'package:battle_master/screens/contact_screen.dart';
import 'package:battle_master/screens/notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 1; // Default to 'Play' tab
  Future<Map<String, dynamic>>? _userDataFuture;
  Future<List<Map<String, dynamic>>>? _bannersFuture;

  @override
  void initState() {
    super.initState();
    _userDataFuture = _fetchUserData();
    _bannersFuture = _fetchBanners();
  }

  Future<List<Map<String, dynamic>>> _fetchBanners() async {
    try {
      final response = await Supabase.instance.client
          .from('app_banners')
          .select('image_url, action_link')
          .eq('is_active', true)
          .order('created_at', ascending: false);
      debugPrint("Banners fetched successfully: $response");
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("Error fetching banners: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>> _fetchUserData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
      }
      throw Exception('User not logged in');
    }

    try {
      final response = await Supabase.instance.client
          .from('users')
          .select('''
            username,
            wallet_balance,
            user_tournaments ( count ),
            game_results ( kills, winnings )
          ''')
          .eq('id', user.id)
          .single();

      final tournaments = response['user_tournaments'] as List<dynamic>?;
      final results = response['game_results'] as List<dynamic>?;

      int totalKills = 0;
      int coinsWon = 0;
      if (results != null) {
        for (var result in results) {
          totalKills += (result['kills'] as int?) ?? 0;
          coinsWon += (result['winnings'] as int?) ?? 0;
        }
      }
      
      return {
        'username': response['username'] ?? 'Battle Master',
        'wallet_balance': response['wallet_balance'] ?? 0,
        'matches_played': tournaments?.isNotEmpty == true ? tournaments![0]['count'] : 0,
        'total_kills': totalKills,
        'coins_won': coinsWon,
      };

    } catch (e) {
       if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error fetching data. Please log in again.")));
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
      }
      return Future.error(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _userDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(backgroundColor: Color(0xFF111827), body: Center(child: CircularProgressIndicator(color: Color(0xFFfacc15))));
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const Scaffold(backgroundColor: Color(0xFF111827), body: Center(child: Text("Could not load data.", style: TextStyle(color: Colors.white))));
        }

        final userData = snapshot.data!;

        final List<Widget> screens = [
          _buildEarnTab(),
          _buildPlayTab(),
          _buildMeTab(userData),
        ];

        return Scaffold(
          backgroundColor: const Color(0xFF111827),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1f2937),
            elevation: 2,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Welcome back,", style: TextStyle(fontSize: 12, color: Colors.white)),
                Text(userData['username'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFfacc15))),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.white),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsScreen())),
              ),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const WalletScreen())),
                child: Container(
                  margin: const EdgeInsets.only(right: 15, left: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: const Color(0xFF374151), borderRadius: BorderRadius.circular(15)),
                  child: Row(
                    children: [
                      const Icon(Icons.monetization_on, color: Color(0xFFfacc15), size: 18),
                      const SizedBox(width: 5),
                      Text("${userData['wallet_balance']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          body: screens[_currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            backgroundColor: const Color(0xFF1f2937),
            selectedItemColor: const Color(0xFFfacc15),
            unselectedItemColor: Colors.grey,
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.attach_money), label: "Earn"),
              BottomNavigationBarItem(icon: Icon(Icons.gamepad), label: "Play"),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: "Me"),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEarnTab() {
    return const Center(child: Text("Coming Soon", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)));
  }

  Widget _buildPlayTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- BANNER SYSTEM ---
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _bannersFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: SizedBox(height: 160, child: Center(child: CircularProgressIndicator(color: Color(0xFFfacc15)))),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Container(
                  height: 160,
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: const Color(0xFF1f2937), borderRadius: BorderRadius.circular(12)),
                  child: const Center(
                    child: Text("No Active Banners Found", style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
                  ),
                );
              }
              
              final banners = snapshot.data!;
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: CarouselSlider(
                  options: CarouselOptions(
                    height: 160.0,
                    autoPlay: true,
                    enlargeCenterPage: true,
                    viewportFraction: 1.0, 
                    autoPlayInterval: const Duration(seconds: 4), 
                  ),
                  items: banners.map((banner) {
                    String imageUrl = banner['image_url'] ?? '';
                    if (!imageUrl.startsWith('http') && imageUrl.isNotEmpty) {
                      imageUrl = Supabase.instance.client.storage.from('Battle Master Banner').getPublicUrl(imageUrl);
                    }

                    return GestureDetector(
                      onTap: () {
                        final link = banner['action_link'];
                        if (link != null && link.toString().isNotEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Link Action: $link")));
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: const Color(0xFF1f2937)),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, color: Colors.white54, size: 40)),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
          // --- END BANNER SYSTEM ---

          const Center(
            child: Text("My Matches", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white))
          ),
          const SizedBox(height: 15),
         Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    // 1. Ongoing Matches ke liye
    _buildMatchCard(
      "Ongoing", 
      Icons.sync, 
      const Color(0xFF34d399), 
      const OngoingScreen(isMyMatches: true), // 🌟 Premium Ongoing Screen connect kar di
    ),
    
    // 2. Upcoming (Isko aise hi rehne do agar iski file hai tumhare paas)
    _buildMatchCard(
      "Upcoming", 
      Icons.calendar_today, 
      Colors.blue, 
      const UpcomingScreen(), 
    ),
    
    // 3. Completed Matches ke liye
    _buildMatchCard(
      "Completed", 
      Icons.check_circle, 
      const Color(0xFF10b981), 
      const CompletedScreen(), // 🌟 Premium Completed Screen connect kar di
    ),
  ],
),
          const SizedBox(height: 30),
          const Center(
            child: Text("Esports Games", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white))
          ),
          const SizedBox(height: 15),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: [
              _buildGameBox("BATTLE ROYALE", "assets/images/battle.png"),
              _buildGameBox("CLASH SQUAD", "assets/images/clash.png"),
              _buildGameBox("LONE WOLF", "assets/images/lone.png"),
              _buildGameBox("BR SURVIVAL", "assets/images/survival.png"),
              _buildGameBox("HS CLASH SQUAD", "assets/images/hsclash.png"),
              _buildGameBox("HS LONE WOLF", "assets/images/hslone.png"),
              _buildGameBox("DAILY SPECIAL", "assets/images/daily.png"),
              _buildGameBox("MEGA SPECIAL", "assets/images/mega.png"),
              _buildGameBox("GRAND SPECIAL", "assets/images/grand.png"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMeTab(Map<String, dynamic> userData) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 45, 
            backgroundColor: Colors.grey, 
            backgroundImage: AssetImage('assets/images/profile.png'),
          ),
          const SizedBox(height: 10),
          Text(userData['username'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          Container(
            margin: const EdgeInsets.only(top: 20),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: const Color(0xFF1f2937), borderRadius: BorderRadius.circular(10)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn("${userData['matches_played']}", "Matches"),
                _buildStatColumn("${userData['total_kills']}", "Kills"),
                _buildStatColumn("${userData['coins_won']}", "Coins Won"),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildMenuItem("My Profile", Icons.person, const ProfileScreen()),
          _buildMenuItem("My Wallet", Icons.account_balance_wallet, const WalletScreen()),
          _buildMenuItem("My Statistics", Icons.bar_chart, const StatisticsScreen()),
          _buildMenuItem("Notifications", Icons.notifications, const NotificationsScreen()),
          _buildMenuItem("Contact Us", Icons.contact_mail, const ContactScreen()),
          _buildMenuItem("FAQ", Icons.help, const FaqScreen()),
          _buildMenuItem("Privacy Policy", Icons.privacy_tip, const PrivacyPolicyPage()),
          _buildMenuItem("Terms & Conditions", Icons.description, const TermsPage()),
          const SizedBox(height: 10),
          
          // 🌟 THE HACKER-PROOF LOGOUT BUTTON 🌟
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFdc2626),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () async {
                try {
                  // Global scope destroys the session on all devices
                  await Supabase.instance.client.auth.signOut(scope: SignOutScope.global);
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("✅ Logged out securely from all devices.")),
                    );
                    Navigator.pushAndRemoveUntil(
                      context, 
                      MaterialPageRoute(builder: (context) => const LoginScreen()), 
                      (route) => false // Clear entire navigation stack
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("❌ Error during logout: $e")),
                    );
                  }
                }
              },
              child: const Text("Logout", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  // Helper Widgets

  Widget _buildMatchCard(String title, IconData icon, Color color, Widget destination) {
    return Expanded(
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => destination)),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
          child: Column(
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color, shape: BoxShape.circle), child: Icon(icon, color: Colors.white, size: 24)),
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameBox(String title, String imagePath) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TournamentScreen(mode: title))),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1f2937),
          borderRadius: BorderRadius.circular(10),
        ),
        child: ClipRRect(
           borderRadius: BorderRadius.circular(10),
          child: Column(
            children: [
              Expanded(
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover, 
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(child: Icon(Icons.games, color: Colors.white54, size: 40));
                  },
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 5),
                color: Colors.black.withOpacity(0.7),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFfacc15))),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildMenuItem(String title, IconData icon, Widget destination) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: const Color(0xFF1f2937), borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => destination)),
      ),
    );
  }
}