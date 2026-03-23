import 'package:battle_master/admin/screens/admin_users_screen.dart';
import 'package:battle_master/admin/screens/create_tournament_screen.dart';
import 'package:battle_master/admin/screens/manage_tournament_screen.dart';
import 'package:flutter/material.dart';


// ... (DashboardHomeWidget wahi rahega)
class DashboardHomeWidget extends StatelessWidget {
  const DashboardHomeWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Dashboard Home"));
  }
}


class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  bool _isExpanded = false;

  // Yahan par saari screens ki list hogi jo menu se select hongi
  static const List<Widget> _screens = [
    DashboardHomeWidget(),         // Index 0
    CreateTournamentScreen(),      // Index 1
    ManageTournamentScreen(),      // Index 2 (Naya)
    AdminUsersScreen(),            // Index 3
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
        ),
      ),
      body: Row(
        children: <Widget>[
          NavigationRail(
            selectedIndex: _selectedIndex,
            extended: _isExpanded,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            destinations: const <NavigationRailDestination>[
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.add_circle_outline),
                selectedIcon: Icon(Icons.add_circle),
                label: Text('Create Match'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.edit_document),
                selectedIcon: Icon(Icons.edit_document),
                label: Text('Manage Match'), // Naya Menu Item
              ),
              NavigationRailDestination(
                icon: Icon(Icons.group_outlined),
                selectedIcon: Icon(Icons.group),
                label: Text('Users'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // Content area
          Expanded(
            child: _screens[_selectedIndex],
          ),
        ],
      ),
    );
  }
}
