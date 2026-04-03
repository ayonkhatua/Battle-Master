import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:carousel_slider/carousel_slider.dart';

// Screens for navigation
import 'package:battle_master/screens/profile_screen.dart';
import 'package:battle_master/screens/wallet_screen.dart';
import 'package:battle_master/screens/statistics_screen.dart';
import 'package:battle_master/screens/ongoing_screen.dart'; 
import 'package:battle_master/screens/completed_screen.dart';
import 'package:battle_master/screens/upcoming_screen.dart';
import 'package:battle_master/screens/game_screen.dart'; 
import 'package:battle_master/screens/login_screen.dart';
import 'package:battle_master/pages/faq_page.dart';
import 'package:battle_master/pages/privacy_policy_page.dart';
import 'package:battle_master/pages/terms_page.dart';
import 'package:battle_master/screens/contact_screen.dart';
import 'package:battle_master/screens/notifications_screen.dart'; 

import 'package:battle_master/screens/refer_earn_screen.dart';
import 'package:battle_master/services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 1; // Default to 'Play' tab
  Future<Map<String, dynamic>>? _userDataFuture;
  Future<List<Map<String, dynamic>>>? _bannersFuture;
  
  // 🌟 Realtime wallet ke liye stream
  Stream<List<Map<String, dynamic>>>? _walletStream;

  @override
  void initState() {
    super.initState();
    
    NotificationService.initialize();

    _userDataFuture = _fetchUserData();
    _bannersFuture = _fetchBanners();

    // User id nikal kar stream chalu karo
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _walletStream = Supabase.instance.client
          .from('users')
          .stream(primaryKey: ['id'])
          .eq('id', user.id);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchBanners() async {
    try {
      final response = await Supabase.instance.client
          .from('app_banners')
          .select('image_url, action_link')
          .eq('is_active', true)
          .order('created_at', ascending: false);
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
            deposited,
            winning,
            bonus,
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
      
      // 🌟 MAGIC FIX: Exact calculation from actual fields instead of wallet_balance
      int dep = response['deposited'] ?? 0;
      int win = response['winning'] ?? 0;
      int bon = response['bonus'] ?? 0;

      return {
        'username': response['username'] ?? 'Battle Master',
        'wallet_balance': dep + win + bon, // Accurate calculation
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
          return const Scaffold(backgroundColor: Color(0xFF0B1120), body: Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6))));
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const Scaffold(backgroundColor: Color(0xFF0B1120), body: Center(child: Text("Could not load data.", style: TextStyle(color: Colors.white))));
        }

        final userData = snapshot.data!;

        final List<Widget> screens = [
          const ReferEarnScreen(), 
          _buildPlayTab(),
          _buildMeTab(userData),
        ];

        return Scaffold(
          backgroundColor: const Color(0xFF0B1120), 
          
          appBar: _currentIndex == 0 
            ? null 
            : AppBar(
                backgroundColor: const Color(0xFF0F172A),
                elevation: 2,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Welcome back,", style: TextStyle(fontSize: 12, color: Colors.white54)),
                    Text(userData['username'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.notifications_active_rounded, color: Color(0xFF3B82F6)), 
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsScreen())), 
                  ),
                  
                  if (_walletStream != null)
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _walletStream,
                      builder: (context, streamSnapshot) {
                        
                        int currentBalance = userData['wallet_balance'] ?? 0;
                        
                        if (streamSnapshot.hasData && streamSnapshot.data!.isNotEmpty) {
                          // 🌟 FIX IN STREAM TOO: Calculate total live when database updates
                          int liveDep = streamSnapshot.data!.first['deposited'] ?? 0;
                          int liveWin = streamSnapshot.data!.first['winning'] ?? 0;
                          int liveBon = streamSnapshot.data!.first['bonus'] ?? 0;
                          currentBalance = liveDep + liveWin + liveBon;
                        }

                        return GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const WalletScreen())),
                          child: Container(
                            margin: const EdgeInsets.only(right: 15, left: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.monetization_on, color: Colors.amberAccent, size: 18),
                                const SizedBox(width: 6),
                                Text("$currentBalance", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
              
          body: screens[_currentIndex],
          
          bottomNavigationBar: BottomNavigationBar(
            backgroundColor: const Color(0xFF0F172A),
            selectedItemColor: const Color(0xFF3B82F6), 
            unselectedItemColor: Colors.grey[600],
            type: BottomNavigationBarType.fixed,
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.redeem_rounded), label: "Refer & Earn"),
              BottomNavigationBarItem(icon: Icon(Icons.sports_esports_rounded), label: "Play"),
              BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: "Me"),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlayTab() {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
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
                  child: SizedBox(height: 210, child: Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Container(
                  height: 210,
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16)),
                  child: const Center(
                    child: Text("No Active Banners", style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
                  ),
                );
              }
              
              final banners = snapshot.data!;
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: CarouselSlider(
                  options: CarouselOptions(
                    height: 210.0,
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
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: const Color(0xFF1E293B)),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
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

          const Text("MY MATCHES", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white54, letterSpacing: 1.5)),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMatchCard("Ongoing", Icons.sync, const Color(0xFFF59E0B), const OngoingScreen(isMyMatches: true)),
              _buildMatchCard("Upcoming", Icons.calendar_today, const Color(0xFF3B82F6), const UpcomingScreen()), 
              _buildMatchCard("Completed", Icons.check_circle, const Color(0xFF10B981), const CompletedScreen()), 
            ],
          ),
          const SizedBox(height: 35),
          const Text("ESPORTS GAMES", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white54, letterSpacing: 1.5)),
          const SizedBox(height: 15),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
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
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.5), width: 2),
            ),
            child: const CircleAvatar(
              radius: 45, 
              backgroundColor: Color(0xFF1E293B),
              backgroundImage: AssetImage('assets/images/logo.png'), 
            ),
          ),
          const SizedBox(height: 12),
          Text(userData['username'].toString().toUpperCase(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.0)),
          
          Container(
            margin: const EdgeInsets.only(top: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn("${userData['matches_played']}", "Matches"),
                _buildStatColumn("${userData['total_kills']}", "Kills"),
                _buildStatColumn("${userData['coins_won']}", "Coins Won"),
              ],
            ),
          ),
          const SizedBox(height: 25),
          
          _buildMenuItem("My Profile", Icons.person_outline_rounded, const ProfileScreen()),
          _buildMenuItem("My Wallet", Icons.account_balance_wallet_outlined, const WalletScreen()),
          _buildMenuItem("My Statistics", Icons.bar_chart_rounded, const StatisticsScreen()),
          
          _buildMenuItem("Announcements", Icons.campaign_rounded, const NotificationsScreen()), 
          
          _buildMenuItem("Contact Us", Icons.support_agent_rounded, const ContactScreen()),
          _buildMenuItem("FAQ", Icons.help_outline_rounded, const FaqScreen()),
          _buildMenuItem("Privacy Policy", Icons.privacy_tip_outlined, const PrivacyPolicyPage()),
          _buildMenuItem("Terms & Conditions", Icons.description_outlined, const TermsPage()),
          
          const SizedBox(height: 20),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444).withOpacity(0.1),
                foregroundColor: const Color(0xFFEF4444),
                elevation: 0,
                side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.logout_rounded),
              label: const Text("SECURE LOGOUT", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.0)),
              onPressed: () async {
                try {
                  await Supabase.instance.client.auth.signOut(scope: SignOutScope.global);
                  if (mounted) {
                    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
                  }
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Error: $e")));
                }
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMatchCard(String title, IconData icon, Color color, Widget destination) {
    return Expanded(
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => destination)),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10), 
                decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle), 
                child: Icon(icon, color: color, size: 24)
              ),
              const SizedBox(height: 10),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.9), fontSize: 12)),
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
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 5)],
        ),
        child: ClipRRect(
           borderRadius: BorderRadius.circular(12),
          child: Column(
            children: [
              Expanded(
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover, 
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.gamepad_rounded, color: Colors.white38, size: 30)),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6),
                color: const Color(0xFF0F172A).withOpacity(0.9),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white),
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
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.amberAccent)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white54, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildMenuItem(String title, IconData icon, Widget destination) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFF3B82F6).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: const Color(0xFF3B82F6), size: 20)
        ),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 14),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => destination)),
      ),
    );
  }
}