import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final ValueNotifier<int> _userListRefresher = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (_searchController.text.isEmpty && _searchQuery.isNotEmpty) {
        setState(() {
          _searchQuery = '';
          _userListRefresher.value++;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _userListRefresher.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchUsers() async {
    var queryBuilder = Supabase.instance.client.from('users').select('*');

    if (_searchQuery.isNotEmpty) {
      queryBuilder = queryBuilder.or(
        'username.ilike.%$_searchQuery%',
        referencedTable: 'mobile.ilike.%$_searchQuery%',
      );
    }

    final response = await queryBuilder.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // CORRECTED: Changed userId parameter from int to String to handle UUIDs
  Future<void> _updateUserStatus(String userId, String newStatus) async {
    try {
      final result = await Supabase.instance.client.rpc('update_user_status', params: {
        'p_user_id': userId, // Pass UUID as a string
        'p_action': newStatus,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result.toString()),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      final errorMsg = e is PostgrestException ? e.message : e.toString();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $errorMsg'),
          backgroundColor: Colors.red,
        ));
      }
    }
    _userListRefresher.value++;
  }

  void _onSearch() {
    setState(() {
      _searchQuery = _searchController.text;
      _userListRefresher.value++;
    });
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Manage User Status'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by username or number',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      filled: true,
                    ),
                    onSubmitted: (_) => _onSearch(),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _onSearch,
                  icon: const Icon(Icons.search),
                  label: const Text('Search'),
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16)),
                ),
              ],
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<int>(
              valueListenable: _userListRefresher,
              builder: (context, _, __) {
                return FutureBuilder<List<Map<String, dynamic>>>(
                  future: _fetchUsers(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No users found.'));
                    }

                    final users = snapshot.data!;
                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 20),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        final bool isActive = user['status'] == 'active';

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          child: ListTile(
                            title: Text(user['username'] ?? 'N/A'),
                            subtitle: Text(
                                'ID: ${user['id']} | Mobile: ${user['mobile'] ?? 'N/A'}'),
                            trailing: Wrap(
                              spacing: 12,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Chip(
                                  label: Text(
                                    isActive ? 'Active' : 'Blocked',
                                    style: const TextStyle(
                                        color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                  backgroundColor:
                                      isActive ? Colors.green[600] : Colors.red[600],
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                ),
                                ElevatedButton(
                                  // The call here is correct as user['id'] is already a string (UUID)
                                  onPressed: () => _updateUserStatus(
                                      user['id'], isActive ? 'blocked' : 'active'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isActive ? Colors.red : Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: Text(isActive ? 'Block' : 'Activate'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
