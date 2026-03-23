import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeleteTournamentScreen extends StatefulWidget {
  const DeleteTournamentScreen({super.key});

  @override
  State<DeleteTournamentScreen> createState() => _DeleteTournamentScreenState();
}

class _DeleteTournamentScreenState extends State<DeleteTournamentScreen> {
  final _tidController = TextEditingController();
  String _message = '';
  bool _isLoading = false;

  Future<void> _deleteTournament() async {
    final tid = int.tryParse(_tidController.text);
    if (tid == null) {
      setState(() {
        _message = '❌ Please enter a valid Tournament ID.';
      });
      return;
    }

    // Confirmation Dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Confirm Deletion'),
        content: Text('Are you sure you want to delete Tournament #$tid? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      // First, check if tournament exists
      final tournament = await Supabase.instance.client
          .from('tournaments')
          .select('id, title')
          .eq('id', tid)
          .maybeSingle();

      if (tournament == null) {
        setState(() {
          _message = '❌ Tournament #$tid not found.';
          _isLoading = false;
        });
        return;
      }

      // If using cascading deletes in Supabase, this next step is not needed.
      // But for safety, we do it, just like the PHP code.
      await Supabase.instance.client
          .from('user_tournaments')
          .delete()
          .eq('tournament_id', tid);
      
      // Also delete from results and statistics
      await Supabase.instance.client.from('results').delete().eq('tournament_id', tid);
      await Supabase.instance.client.from('statistics').delete().eq('tournament_id', tid);

      // Finally, delete the tournament itself
      await Supabase.instance.client
          .from('tournaments')
          .delete()
          .eq('id', tid);

      setState(() {
        _message = "✅ Tournament #${tid} (${tournament['title']}) and all its data deleted successfully!";
        _tidController.clear();
      });

    } on PostgrestException catch (e) {
      setState(() {
        _message = '❌ Error: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _message = '❌ An unexpected error occurred: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: const Color(0xFF1E293B), // box color
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🗑 Delete Tournament', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.amberAccent)),
              const SizedBox(height: 20),
              TextField(
                controller: _tidController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Enter Tournament ID',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: _deleteTournament,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Delete Tournament'),
                ),
              if (_message.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  _message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _message.startsWith('✅') ? Colors.greenAccent : Colors.redAccent,
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
