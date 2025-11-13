import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lamaplay/services/firestore_refs.dart';
import 'package:lamaplay/services/presence_service.dart';
import 'package:lamaplay/services/round_controller.dart';
import 'package:lamaplay/services/playlist_controller.dart';
import 'package:lamaplay/core/router.dart';
import 'package:lamaplay/services/auth_service.dart';

/// Lobby screen: shows room info and players list.
class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final _presence = PresenceService();
  String? _roomId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final roomId = ModalRoute.of(context)?.settings.arguments as String?;
    if (roomId != null && roomId != _roomId) {
      _roomId = roomId;
      _presence.joinRoom(roomId);
    }
  }

  @override
  void dispose() {
    final roomId = _roomId;
    if (roomId != null) {
      _presence.leaveRoom(roomId);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roomId =
        _roomId ?? ModalRoute.of(context)?.settings.arguments as String?;
    return Scaffold(
      appBar: AppBar(title: const Text('Lobby')),
      body: roomId == null
          ? const Center(child: Text('No room provided'))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Room header + host controls
                StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: FirestoreRefs.roomDoc(roomId).snapshots(),
                  builder: (context, rs) {
                    final room = rs.data?.data();
                    final hostId = room?['hostId'] as String?;
                    final playlist =
                        (room?['playlist'] as List?)?.cast<String>() ??
                        const [];
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Room: $roomId'),
                          const SizedBox(height: 8),
                          Text(
                            'Playlist: ${playlist.isEmpty ? '(empty)' : playlist.join(', ')}',
                          ),
                          const SizedBox(height: 12),
                          // For non-host clients, auto-navigate when a round starts
                          _RoundAutoNavigator(roomId: roomId, hostId: hostId),
                          const SizedBox(height: 12),
                          _HostControls(
                            roomId: roomId,
                            hostId: hostId,
                            playlist: playlist,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirestoreRefs.players(roomId).snapshots(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final docs = snap.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return const Center(child: Text('No players yet'));
                      }
                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, i) {
                          final d = docs[i].data();
                          return ListTile(
                            title: Text(d['nickname'] ?? 'Player'),
                            subtitle: Text('Score: ${d['score'] ?? 0}'),
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

class _HostControls extends StatefulWidget {
  final String roomId;
  final String? hostId; // compare to current user id
  final List<String> playlist;
  const _HostControls({
    required this.roomId,
    required this.hostId,
    required this.playlist,
  });

  @override
  State<_HostControls> createState() => _HostControlsState();
}

class _HostControlsState extends State<_HostControls> {
  late List<String> _draft;
  bool _saving = false;

  static const Map<String, String> _gameLabels = {
    'emoji_telepathy': 'Emoji Telepathy',
    'speed_categories': 'Speed Categories',
    'odd_one_out': 'Odd One Out',
    'bluff_trivia': 'Bluff Trivia',
  };

  @override
  void initState() {
    super.initState();
    _draft = List<String>.from(widget.playlist);
  }

  @override
  void didUpdateWidget(covariant _HostControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playlist != widget.playlist) {
      _draft = List<String>.from(widget.playlist);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await PlaylistController().updatePlaylist(widget.roomId, _draft);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Playlist saved')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _moveUp(int i) {
    if (i <= 0) return;
    setState(() {
      final tmp = _draft[i - 1];
      _draft[i - 1] = _draft[i];
      _draft[i] = tmp;
    });
  }

  void _moveDown(int i) {
    if (i >= _draft.length - 1) return;
    setState(() {
      final tmp = _draft[i + 1];
      _draft[i + 1] = _draft[i];
      _draft[i] = tmp;
    });
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService().uid;
    final isHost = uid != null && uid == widget.hostId;
    if (!isHost) return const SizedBox.shrink();

    final available = _gameLabels.keys.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Add games:'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final key in available)
              ActionChip(
                label: Text(_gameLabels[key] ?? key),
                onPressed: () {
                  setState(() => _draft.add(key));
                },
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text('Current playlist (${_draft.length}):'),
        const SizedBox(height: 8),
        if (_draft.isEmpty)
          const Text('(empty)')
        else
          Column(
            children: [
              for (int i = 0; i < _draft.length; i++)
                Card(
                  child: ListTile(
                    title: Text(_gameLabels[_draft[i]] ?? _draft[i]),
                    leading: Text('#${i + 1}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_upward),
                          onPressed: i == 0 ? null : () => _moveUp(i),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_downward),
                          onPressed: i == _draft.length - 1
                              ? null
                              : () => _moveDown(i),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => setState(() => _draft.removeAt(i)),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving…' : 'Save Playlist'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: _saving ? null : () => setState(() => _draft.clear()),
              child: const Text('Clear'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: _saving
                  ? null
                  : () => setState(
                      () => _draft = [
                        'emoji_telepathy',
                        'speed_categories',
                        'odd_one_out',
                        'bluff_trivia',
                      ],
                    ),
              child: const Text('Use Default'),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () async {
                try {
                  final roundId = await RoundController().startRound(
                    widget.roomId,
                  );
                  if (!context.mounted) return;
                  Navigator.pushNamed(
                    context,
                    AppRouter.roundIntro,
                    arguments: {'roomId': widget.roomId, 'roundId': roundId},
                  );
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Start failed: $e')));
                }
              },
              child: const Text('Start Game (Host)'),
            ),
          ],
        ),
      ],
    );
  }
}

/// Listens to latest round in a room and auto-navigates non-host clients
/// into the appropriate screen when a round exists/changes.
class _RoundAutoNavigator extends StatefulWidget {
  final String roomId;
  final String? hostId;
  const _RoundAutoNavigator({required this.roomId, required this.hostId});

  @override
  State<_RoundAutoNavigator> createState() => _RoundAutoNavigatorState();
}

class _RoundAutoNavigatorState extends State<_RoundAutoNavigator> {
  String? _lastRoundId;
  String? _lastState;
  @override
  Widget build(BuildContext context) {
    final uid = AuthService().uid;
    final isHost = uid != null && uid == widget.hostId;
    if (isHost) return const SizedBox.shrink();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirestoreRefs.rounds(
        widget.roomId,
      ).orderBy('createdAt').snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final docs = snap.data!.docs;
        if (docs.isEmpty) return const SizedBox.shrink();
        final last = docs.last;
        final roundId = last.id;
        final state = (last.data()['state'] as String?) ?? 'intro';
        if (_lastRoundId != roundId) {
          _lastRoundId = roundId;
          _lastState = state;
          // New round appeared — send guest to intro
          Future.microtask(() {
            if (!context.mounted) return;
            Navigator.pushReplacementNamed(
              context,
              AppRouter.roundIntro,
              arguments: {
                'roomId': widget.roomId,
                'roundId': roundId,
                // pass hostId to help intro decide host-only button
                'hostId': widget.hostId ?? '',
              },
            );
          });
        } else if (state != 'intro' && _lastState != state) {
          _lastState = state;
          // If same round but state advanced, make sure we're not stuck in lobby
          final route = state == 'results'
              ? AppRouter.results
              : AppRouter.gameShell;
          Future.microtask(() {
            if (!context.mounted) return;
            Navigator.pushReplacementNamed(
              context,
              route,
              arguments: {
                'roomId': widget.roomId,
                'roundId': roundId,
                'hostId': widget.hostId ?? '',
              },
            );
          });
        }
        return const SizedBox.shrink();
      },
    );
  }
}
