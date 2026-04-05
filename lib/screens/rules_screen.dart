import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:battle_master/screens/choose_slot_screen.dart'; 

class RulesScreen extends StatefulWidget {
  final int tournamentId;

  const RulesScreen({super.key, required this.tournamentId});

  @override
  _RulesScreenState createState() => _RulesScreenState();
}

class _RulesScreenState extends State<RulesScreen> {
  bool _isLoading = true;
  bool _hasJoined = false;
  
  // Tournament Data
  Map<String, dynamic> _tData = {};
  String _roomId = '';
  String _roomPass = '';
  String _matchStatus = ''; 
  
  // Slots Data
  List<Map<String, dynamic>> _mySlots = [];
  List<Map<String, dynamic>> _allParticipants = [];

  RealtimeChannel? _tournamentChannel;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
    _setupRealtimeTournament();
  }

  @override
  void dispose() {
    _tournamentChannel?.unsubscribe();
    super.dispose();
  }

  void _setupRealtimeTournament() {
    _tournamentChannel = Supabase.instance.client
        .channel('public:tournaments:${widget.tournamentId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'tournaments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: widget.tournamentId,
          ),
          callback: (payload) {
            if (mounted) {
              final updatedData = payload.newRecord;
              String newRoomId = updatedData['room_id']?.toString() ?? '';
              String newRoomPass = updatedData['room_password']?.toString() ?? '';

              bool roomJustUpdated = (newRoomId.isNotEmpty && newRoomId != _roomId) || 
                                     (newRoomPass.isNotEmpty && newRoomPass != _roomPass);

              setState(() {
                _roomId = newRoomId;
                _roomPass = newRoomPass;
                // 🔥 Realtime status update
                _matchStatus = updatedData['status']?.toString().toLowerCase() ?? 'upcoming';
                _tData['room_id'] = newRoomId;
                _tData['room_password'] = newRoomPass;
                _tData['status'] = updatedData['status'];
              });

              if (_hasJoined && roomJustUpdated) {
                _triggerRoomDetailsNotification(newRoomId, newRoomPass);
              }
            }
          }
        ).subscribe();
  }

  void _triggerRoomDetailsNotification(String rId, String rPass) {
    debugPrint("📢 NOTIFICATION TRIGGERED: Room ID: $rId | Pass: $rPass");
  }

  Future<void> _handleRefresh() async {
    await _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final tResponse = await Supabase.instance.client
          .from('tournaments')
          .select('*')
          .eq('id', widget.tournamentId)
          .single();

      final allParticipantsResponse = await Supabase.instance.client
          .from('user_tournaments')
          .select('id, user_id, slot_number, position, user_ign')
          .eq('tournament_id', widget.tournamentId)
          .order('slot_number', ascending: true);

      final participantsList = List<Map<String, dynamic>>.from(allParticipantsResponse);
      final myJoinedSlots = participantsList.where((p) => p['user_id'] == user.id).toList();

      if (mounted) {
        setState(() {
          _tData = tResponse;
          _roomId = _tData['room_id']?.toString() ?? '';
          _roomPass = _tData['room_password']?.toString() ?? '';
          _matchStatus = _tData['status']?.toString().toLowerCase() ?? 'upcoming'; 
          
          _allParticipants = participantsList;
          _mySlots = myJoinedSlots;
          _hasJoined = myJoinedSlots.isNotEmpty;
          
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching details: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _copyToClipboard(String text, String type) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("✅ $type Copied!"), backgroundColor: Colors.green),
    );
  }

  Future<void> _editIGN(int index, int recordId, String currentIgn) async {
    if (_matchStatus != 'upcoming') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Match has already started. You cannot change IGN now!"), backgroundColor: Colors.orange),
      );
      return;
    }

    TextEditingController ignController = TextEditingController(text: currentIgn);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Edit your IGN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ignController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF0F172A),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)),
            onPressed: () => Navigator.pop(context, ignController.text.trim()),
            child: const Text("SAVE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != currentIgn) {
      try {
        await Supabase.instance.client
            .from('user_tournaments')
            .update({'user_ign': result})
            .eq('id', recordId);

        setState(() {
          _mySlots[index]['user_ign'] = result;
          int pIndex = _allParticipants.indexWhere((p) => p['id'] == recordId);
          if (pIndex != -1) {
            _allParticipants[pIndex]['user_ign'] = result;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ IGN Updated!"), backgroundColor: Colors.green));
      } catch (e) {
        debugPrint("Update error: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B1120),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6))),
      );
    }

    int slots = _tData['slots'] ?? 0;
    String type = (_tData['type'] ?? '').toString().toLowerCase();
    int squadSize = type == 'squad' ? 4 : (type == 'duo' ? 2 : 1);

    int totalCapacity = slots * squadSize;
    int filledSlots = _tData['filled'] ?? 0;
    bool isFull = filledSlots >= totalCapacity;
    bool isMatchUpcoming = _matchStatus == 'upcoming'; 

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1120),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F172A),
          title: Text(_tData['title'] ?? "Match Details", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
          bottom: const TabBar(
            indicatorColor: Color(0xFF3B82F6),
            labelColor: Color(0xFF3B82F6),
            unselectedLabelColor: Colors.grey,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: "DETAILS & RULES"),
              Tab(text: "PARTICIPANTS"),
            ],
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: const Color(0xFF0B1120),
          backgroundColor: const Color(0xFF3B82F6),
          child: TabBarView(
            children: [
              _buildDetailsTab(isMatchUpcoming),
              _buildParticipantsTab(),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomActionBar(isFull, isMatchUpcoming),
      ),
    );
  }

  Widget _buildDetailsTab(bool isMatchUpcoming) {
    bool roomSet = _roomId.isNotEmpty && _roomPass.isNotEmpty;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(), 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_tData['image_url'] != null)
            Image.network(_tData['image_url'], width: double.infinity, height: 200, fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(height: 200, color: const Color(0xFF1E293B), child: const Icon(Icons.image, size: 50, color: Colors.grey)),
            ),

          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("MATCH INFO", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                const SizedBox(height: 15),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildStylizedDataBlock(Icons.groups, "Team", _tData['type']?.toString().toUpperCase() ?? 'SOLO', Colors.white),
                    _buildStylizedDataBlock(Icons.monetization_on, "Entry Fee", "🪙 ${_tData['entry_fee'] ?? 0}", Colors.amberAccent),
                    _buildStylizedDataBlock(Icons.map, "Map", _tData['map'] ?? 'BERMUDA', Colors.white),
                  ],
                ),
                const SizedBox(height: 35),

                const Text("PRIZE DETAILS", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(child: _buildStylizedDataBlock(Icons.emoji_events, "Prize Pool", "🪙 ${_tData['prize_pool'] ?? 0}", Colors.amberAccent)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStylizedDataBlock(Icons.ads_click, "Per Kill", "🪙 ${_tData['per_kill'] ?? 0}", Colors.amberAccent)),
                  ],
                ),
                const SizedBox(height: 40),

                if (_hasJoined) ...[
                  const Divider(color: Colors.white10, thickness: 1),
                  const SizedBox(height: 20),
                  
                  if (roomSet) ...[
                    const Text("ROOM DETAILS", style: TextStyle(color: Colors.greenAccent, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.greenAccent.withOpacity(0.5), width: 1.5)),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("ID: $_roomId", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              IconButton(onPressed: () => _copyToClipboard(_roomId, "Room ID"), icon: const Icon(Icons.copy, color: Colors.greenAccent, size: 20), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                            ],
                          ),
                          const Divider(color: Colors.white10, thickness: 1, height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Pass: $_roomPass", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              IconButton(onPressed: () => _copyToClipboard(_roomPass, "Password"), icon: const Icon(Icons.copy, color: Colors.greenAccent, size: 20), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
                      child: const Text("⏳ Room ID and Password will be updated here 5-10 minutes before the match starts.", style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4), textAlign: TextAlign.center),
                    ),
                  ],
                  const SizedBox(height: 35),

                  const Text("MY SLOTS", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  const SizedBox(height: 15),
                  Container(
                    decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: _mySlots.asMap().entries.map((entry) {
                        int idx = entry.key;
                        var slot = entry.value;
                        return Container(
                          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05)))),
                          child: ListTile(
                            leading: CircleAvatar(backgroundColor: const Color(0xFF0F172A), child: Text(slot['position'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                            title: Text("Slot ${slot['slot_number']}", style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                            subtitle: Text(slot['user_ign'], style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            trailing: (!roomSet && isMatchUpcoming) 
                                ? IconButton(icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 20), onPressed: () => _editIGN(idx, slot['id'], slot['user_ign']))
                                : const Icon(Icons.lock, color: Colors.white38, size: 20),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Divider(color: Colors.white10, thickness: 1),
                  const SizedBox(height: 30),
                ],

                const Text("REGULATIONS", style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                const SizedBox(height: 15),
                
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.05))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRuleSection("JOINING INSTRUCTIONS", [
                        "Enter Account Name: Ensure you copy your exact Free Fire MAX in-game name while joining.",
                        "Match Name Verification: If your registered name does not match your in-game name, you will be kicked from the room.",
                        "Slot Rules: Ensure you join your assigned slot only. Sitting in someone else's slot will lead to an instant kick.",
                        "Room Details: The Match Room ID & Password will be shared 5 to 10 minutes before the scheduled match time."
                      ]),
                      
                      _buildRuleSection("ELIGIBILITY RULES", [
                        "Level Requirement: Only players with Level 40+ IDs are eligible to participate.",
                        "Map Requirements: Ensure all required maps are downloaded before joining the custom room."
                      ]),
                      
                      _buildRuleSection("MATCH RULES", [
                        "Anti-Cheat: Any use of hacks, mods, or third-party applications will result in a permanent ban and prize forfeiture.",
                        "Recording Mandatory: All players MUST screen record their gameplay live from their phone. Replay videos are NOT accepted. Proof may be asked to claim prizes.",
                        "Teaming: Teaming up in Solo matches is strictly prohibited and will lead to an instant ban.",
                        "Weapon Rules: Double Vector is STRICTLY prohibited. However, Single Vector is allowed.",
                        "Punctuality: Match time will not be extended for any player. Please join the room exactly on time."
                      ]),
                      
                      _buildRuleSection("REFUND POLICY", [
                        "Missed Match: If you join a tournament but fail to enter the room or play for any reason, your entry coins will NOT be refunded.",
                        "Cancelled Match: If a match is cancelled from our side for any reason, your entry coins will be fully refunded to your wallet."
                      ], isLast: true),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleSection(String title, List<String> rules, {bool isLast = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.amberAccent, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
        const SizedBox(height: 10),
        ...rules.map((rule) {
          List<String> parts = rule.split(': ');
          String boldPart = parts[0] + (parts.length > 1 ? ':' : '');
          String normalPart = parts.length > 1 ? ' ${parts.sublist(1).join(': ')}' : '';

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("• ", style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5, fontFamily: 'Roboto'),
                      children: [
                        TextSpan(text: boldPart, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        TextSpan(text: normalPart),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        if (!isLast) ...[
          const SizedBox(height: 5),
          const Divider(color: Colors.white10, thickness: 1),
          const SizedBox(height: 15),
        ]
      ],
    );
  }

  Widget _buildParticipantsTab() {
    if (_allParticipants.isEmpty) {
      return const Center(
        child: Text(
          "No participants have joined yet.\nBe the first one!",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, fontSize: 14),
        ),
      );
    }

    final currentUser = Supabase.instance.client.auth.currentUser;

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(), 
      padding: const EdgeInsets.all(16),
      itemCount: _allParticipants.length,
      itemBuilder: (context, index) {
        final p = _allParticipants[index];
        bool isMe = p['user_id'] == currentUser?.id;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isMe ? const Color(0xFF3B82F6).withOpacity(0.15) : const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: isMe ? Border.all(color: const Color(0xFF3B82F6), width: 1) : Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isMe ? const Color(0xFF3B82F6) : const Color(0xFF0F172A),
              child: Text(
                p['position'].toString(), 
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
              ),
            ),
            title: Text(
              "Slot ${p['slot_number']}", 
              style: TextStyle(color: isMe ? Colors.white : Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)
            ),
            subtitle: Text(
              p['user_ign'], 
              style: TextStyle(color: isMe ? Colors.blueAccent : Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
            ),
            trailing: isMe 
                ? const Text("(You)", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w900))
                : const Icon(Icons.person, color: Colors.white24, size: 20),
          ),
        );
      },
    );
  }

  Widget _buildBottomActionBar(bool isFull, bool isMatchUpcoming) {
    int entryFee = _tData['entry_fee'] ?? 0;
    int filledSlots = _tData['filled'] ?? 0;
    
    int slots = _tData['slots'] ?? 0;
    String type = (_tData['type'] ?? '').toString().toLowerCase().trim();
    int squadSize = type == 'squad' ? 4 : (type == 'duo' ? 2 : 1);
    int totalCapacity = slots * squadSize;

    Color buttonColor = const Color(0xFF3B82F6);
    String buttonText = "JOIN NOW";
    bool isDisabled = false;

    if (_hasJoined) {
      buttonColor = const Color(0xFF1E293B);
      buttonText = "ALREADY JOINED";
      isDisabled = true;
    } 
    // 🔥 FIX: Match status ab strictly check hoga
    else if (_matchStatus != 'upcoming') {
      buttonColor = const Color(0xFF1E293B);
      buttonText = "MATCH STARTED";
      isDisabled = true;
    } 
    else if (isFull) {
      buttonColor = const Color(0xFF1E293B);
      buttonText = "MATCH FULL";
      isDisabled = true;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(top: BorderSide(color: Colors.white10, width: 1)),
      ),
      child: SizedBox(
        height: 55,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            disabledBackgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 20),
          ),
          // 🛡️ Extra Security: Double check inside onPressed
          onPressed: (isDisabled || _matchStatus != 'upcoming') ? null : () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ChooseSlotScreen(tournamentId: widget.tournamentId)),
            ).then((_) => _fetchDetails());
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                   Text(
                     "🪙 $entryFee", 
                     style: TextStyle(
                       color: isDisabled ? Colors.white38 : Colors.amberAccent, 
                       fontSize: 14, 
                       fontWeight: FontWeight.bold
                     )
                   ),
                ],
              ),
              Text(
                buttonText, 
                style: TextStyle(
                  color: isDisabled ? (buttonText == "MATCH STARTED" ? Colors.redAccent : Colors.white38) : Colors.white, 
                  fontSize: 14, 
                  fontWeight: FontWeight.w900, 
                  letterSpacing: 1.5
                )
              ),
              Text(
                "$filledSlots/$totalCapacity", 
                style: TextStyle(
                  color: isDisabled ? Colors.white38 : Colors.white, 
                  fontSize: 14, 
                  fontWeight: FontWeight.bold
                )
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStylizedDataBlock(IconData icon, String label, String value, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.05))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: accentColor, size: 24), 
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)), 
            ],
          ),
        ],
      ),
    );
  }
}