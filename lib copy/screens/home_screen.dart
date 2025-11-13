import 'package:flutter/material.dart';
import 'package:lamaplay/core/router.dart';
import 'package:lamaplay/services/room_controller.dart';

/// Home screen: create/join a room minimal UI.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _nickCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _rooms = RoomController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _nickCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _createRoom() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final roomId = await _rooms.createRoom(nickname: _nickCtrl.text.trim());
      if (!mounted) return;
      Navigator.pushNamed(context, AppRouter.lobby, arguments: roomId);
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _busy = false;
      });
    }
  }

  Future<void> _joinRoom() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final roomId = await _rooms.joinRoom(
        code: _codeCtrl.text.trim(),
        nickname: _nickCtrl.text.trim(),
      );
      if (roomId == null) throw Exception('Room not found');
      if (!mounted) return;
      Navigator.pushNamed(context, AppRouter.lobby, arguments: roomId);
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('LamaPlay — Home')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nickCtrl,
              decoration: const InputDecoration(labelText: 'Nickname'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codeCtrl,
                    decoration: const InputDecoration(labelText: 'Room Code'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _busy ? null : _joinRoom,
                  child: const Text('Join'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _busy ? null : _createRoom,
              child: const Text('Create Room'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }
}
