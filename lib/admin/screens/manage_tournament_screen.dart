import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ParticipantState {
  final Map<String, dynamic> participantData;
  final TextEditingController killsController;
  final TextEditingController coinsController;
  bool isWinner;

  ParticipantState(this.participantData)
      : killsController = TextEditingController(text: (participantData['kills'] ?? 0).toString()),
        coinsController = TextEditingController(text: (participantData['coins_won'] ?? 0).toString()),
        isWinner = false;

  String get ign => participantData['users']?['ign'] ?? participantData['ign'] ?? 'N/A';
  int get joinId => participantData['id'];
  int get userId => participantData['user_id'];
}

class ManageTournamentScreen extends StatefulWidget {
  const ManageTournamentScreen({super.key});

  @override
  State<ManageTournamentScreen> createState() => _ManageTournamentScreenState();
}

class _ManageTournamentScreenState extends State<ManageTournamentScreen> {
  final _searchController = TextEditingController();
  final _roomIdController = TextEditingController();
  final _roomPassController = TextEditingController();

  Map<String, dynamic>? _tournament;
  List<ParticipantState> _participants = [];
  bool _isLoading = false;
  String _message = "";

  Future<void> _loadTournament() async {
    final tid = int.tryParse(_searchController.text);
    if (tid == null) {
      setState(() => _message = "⚠️ Please enter a valid Tournament ID.");
      return;
    }

    setState(() {
      _isLoading = true;
      _message = "";
      _tournament = null;
      _participants = [];
    });

    try {
      final tResponse = await Supabase.instance.client.from('tournaments').select().eq('id', tid).single();
      final pResponse = await Supabase.instance.client
          .from('user_tournaments')
          .select('*, users(ign)')
          .eq('tournament_id', tid)
          .order('id', ascending: true);
      
      setState(() {
        _tournament = tResponse;
        _participants = pResponse.map((p) => ParticipantState(p)).toList();
        _roomIdController.text = _tournament!['room_id'] ?? '';
        _roomPassController.text = _tournament!['room_password'] ?? '';
      });

    } catch (e) {
      setState(() => _message = "❌ Error loading tournament: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _setRoomDetails() async { /* ... Wahi logic ... */ }

  Future<void> _saveResults() async {
    if (_tournament == null) return;
    final tid = _tournament!['id'];
    setState(() { _isLoading = true; _message = "🔄 Saving results..."; });

    try {
      // Step 1: Upsert results for all participants
      final resultsToUpsert = _participants.map((p) => {
        'tournament_id': tid,
        'participant_id': p.userId,
        'ign': p.ign,
        'kills': int.tryParse(p.killsController.text) ?? 0,
        'won': int.tryParse(p.coinsController.text) ?? 0,
        'winner': p.isWinner ? 1 : 0,
      }).toList();
      
      await Supabase.instance.client.from('results').upsert(resultsToUpsert, onConflict: 'tournament_id, participant_id, ign');

      // Step 2: Update tournament status and winner names
      final winners = _participants.where((p) => p.isWinner).map((p) => p.ign).toList();
      final winnerNames = winners.join(", ");
      
      await Supabase.instance.client.from('tournaments').update({
        'status': 'completed',
        'winner': winnerNames,
        'end_time': DateTime.now().toIso8601String(),
      }).eq('id', tid);

      // Step 3: Calculate and upsert statistics (PHP logic)
      await _updateStatistics(tid);

      setState(() => _message = "🏆 Results saved successfully! Winners: $winnerNames");

    } on PostgrestException catch (e) {
      setState(() => _message = "❌ Database Error: ${e.message}");
    } catch (e) {
      setState(() => _message = "❌ An unexpected error occurred: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  // PHP code se statistics update karne wali logic
  Future<void> _updateStatistics(int tid) async {
    final entryFeeString = _tournament!['entry_fee']?.toString() ?? '0';
    final entryFee = double.tryParse(entryFeeString.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    final title = _tournament!['title'];
    final startTime = _tournament!['time'];

    // Fetch results data to aggregate
    final resultsData = await Supabase.instance.client
        .from('results')
        .select('participant_id, won')
        .eq('tournament_id', tid);

    // Group by user_id in Dart
    final Map<int, Map<String, dynamic>> userStats = {};
    for (var row in resultsData) {
        final userId = row['participant_id'] as int;
        final won = (row['won'] ?? 0) as num;

        if (userStats.containsKey(userId)) {
            userStats[userId]!['ign_count'] += 1;
            userStats[userId]!['total_won'] += won;
        } else {
            userStats[userId] = {'ign_count': 1, 'total_won': won.toDouble()};
        }
    }

    // Prepare data for statistics upsert
    final statsToUpsert = [];
    userStats.forEach((userId, stats) {
        statsToUpsert.add({
            'user_id': userId,
            'tournament_id': tid,
            'title': title,
            'start_time': startTime,
            'paid': entryFee * stats['ign_count'],
            'won': stats['total_won'],
        });
    });

    if (statsToUpsert.isNotEmpty) {
        await Supabase.instance.client.from('statistics').upsert(statsToUpsert, onConflict: 'user_id, tournament_id');
    }
  }

  @override
  Widget build(BuildContext context) { /* ... Wahi build logic ... */ return const SizedBox.shrink();}
  Widget _buildRoomBox() { /* ... Wahi UI ... */ return const SizedBox.shrink();}
  Widget _buildParticipantsTable() { /* ... Wahi UI ... */ return const SizedBox.shrink();}
}
