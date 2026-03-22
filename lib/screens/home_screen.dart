import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 1; // Default to 'Play' tab (Index 1)

  // User Data Variables
  String _username = "Loading...";
  int _walletBalance = 0;
  int _matchesPlayed = 0;
  int _totalKills = 0;
  int _coinsWon = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // Supabase se data fetch karne ka logic (PHP backend ka replacement)
  Future<void> _fetchUserData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      // User is not logged in, redirect to login
      // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
      return;
    }

    try {
      // Fetching Profile Data
      final profileResponse = await Supabase.instance.client
          .from('users')
          .select('username, wallet_balance')
          .eq('id', user.id)
          .single();

      // Fetching Statistics Data
      final statsResponse = await Supabase.instance.client
          .from('statistics')
          .select('id') // We just need the count
          .eq('user_id', user.id);

      // Fetching Results Data
      final resultsResponse = await Supabase.instance.client
          .from('results')
          .select('kills, won')
          .eq('participant_id', user.id);

      // Calculating Totals
      int tempKills = 0;
      int tempWon = 0;
      for (var result in resultsResponse) {
        tempKills += (result['kills'] as int?) ?? 0;
        tempWon += (result['won'] as int?) ?? 0;
      }

      setState(() {
        _username = profileResponse['username'] ?? "Battle Master";
        _walletBalance = profileResponse['wallet_balance'] ?? 0;
        _matchesPlayed = (statsResponse as List).length;
        _totalKills = tempKills;
        _coinsWon = tempWon;
      });
    } catch (e) {
      print("Error fetching data: $e");
      // Handle error (maybe show a snackbar)
    }
  }

  // List of screens for the Bottom Navigation
  List<Widget> get _screens => [
        _buildEarnTab(),
        _buildPlayTab(),
        _buildMeTab(),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF111827), // Dark background from your CSS
      appBar: AppBar(
        backgroundColor: Color(0xFF1f2937),
        elevation: 2,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Welcome back,", style: TextStyle(fontSize: 12, color: Colors.white70)),
            Text(
              _username,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFfacc15)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              // TODO: Navigate to Notifications
            },
          ),
          Container(
            margin: EdgeInsets.only(right: 15, left: 10),
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Color(0xFF374151),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                Icon(Icons.monetization_on, color: Color(0xFFfacc15), size: 18), // Coin Icon
                SizedBox(width: 5),
                Text("$_walletBalance", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Color(0xFF1f2937),
        selectedItemColor: Color(0xFFfacc15),
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.attach_money), label: "Earn"),
          BottomNavigationBarItem(icon: Icon(Icons.gamepad), label: "Play"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Me"),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: EARN
  // ==========================================
  Widget _buildEarnTab() {
    return Center(
      child: Text(
        "Coming Soon",
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }

  // ==========================================
  // TAB 2: PLAY
  // ==========================================
  Widget _buildPlayTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("My Matches", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMatchCard("Ongoing", Icons.sync, Color(0xFF34d399)),
              _buildMatchCard("Upcoming", Icons.calendar_today, Colors.blue),
              _buildMatchCard("Completed", Icons.check_circle, Color(0xFF10b981)),
            ],
          ),
          SizedBox(height: 30),
          Text("Esports Games", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          SizedBox(height: 15),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: [
              _buildGameBox("BATTLE ROYALE", "assets/battle.png"),
              _buildGameBox("CLASH SQUAD", "assets/clash.png"),
              _buildGameBox("LONE WOLF", "assets/lone.png"),
              _buildGameBox("BR SURVIVAL", "assets/survival.png"),
              _buildGameBox("HS CLASH SQUAD", "assets/hsclash.png"),
              _buildGameBox("HS LONE WOLF", "assets/hslone.png"),
              _buildGameBox("DAILY SPECIAL", "assets/daily.png"),
              _buildGameBox("MEGA SPECIAL", "assets/mega.png"),
              _buildGameBox("GRAND SPECIAL", "assets/grand.png"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCard(String title, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 5),
        padding: EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            SizedBox(height: 10),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
          ],
        ),
      ),
    );
  }

  Widget _buildGameBox(String title, String imagePath) {
    return GestureDetector(
      onTap: () {
        // Navigate to Game Screen
      },
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xFF1f2937),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Expanded(
              // Assuming you will add these images to your assets folder
              // If not, use an Icon or placeholder for now
              child: Container(color: Colors.grey[800], child: Center(child: Icon(Icons.image, color: Colors.white54))), 
            ),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 5),
              color: Colors.black,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 3: ME (PROFILE)
  // ==========================================
  Widget _buildMeTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          CircleAvatar(
            radius: 45,
            backgroundColor: Colors.grey,
            // backgroundImage: AssetImage('assets/profile.png'), // Add profile image
            child: Icon(Icons.person, size: 50, color: Colors.white),
          ),
          SizedBox(height: 10),
          Text(_username, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          
          // Stats Box
          Container(
            margin: EdgeInsets.only(top: 20),
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Color(0xFF1f2937),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn("$_matchesPlayed", "Matches"),
                _buildStatColumn("$_totalKills", "Kills"),
                _buildStatColumn("$_coinsWon", "Coins Won"),
              ],
            ),
          ),

          SizedBox(height: 20),
          
          // Profile Menu Items
          _buildMenuItem("My Profile", Icons.person),
          _buildMenuItem("My Wallet", Icons.account_balance_wallet),
          _buildMenuItem("My Statistics", Icons.bar_chart),
          _buildMenuItem("Notifications", Icons.notifications),
          _buildMenuItem("Contact Us", Icons.contact_mail),
          _buildMenuItem("FAQ", Icons.help),
          _buildMenuItem("Privacy Policy", Icons.privacy_tip),
          _buildMenuItem("Terms & Conditions", Icons.description),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFfacc15))),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildMenuItem(String title, IconData icon) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Color(0xFF1f2937),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(title, style: TextStyle(color: Colors.white)),
        trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
        onTap: () {
          // Handle navigation
        },
      ),
    );
  }
}