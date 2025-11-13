import 'package:flutter/material.dart';

class SessionSettings {
  final bool enableScoring;
  final int? timeLimit; // null means use question default
  final bool showCorrectAnswers;
  final bool showLeaderboard;

  const SessionSettings({
    this.enableScoring = true,
    this.timeLimit,
    this.showCorrectAnswers = true,
    this.showLeaderboard = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'enableScoring': enableScoring,
      if (timeLimit != null) 'timeLimit': timeLimit,
      'showCorrectAnswers': showCorrectAnswers,
      'showLeaderboard': showLeaderboard,
    };
  }
}

class SessionSettingsDialog extends StatefulWidget {
  final SessionSettings initialSettings;

  const SessionSettingsDialog({
    super.key,
    this.initialSettings = const SessionSettings(),
  });

  @override
  State<SessionSettingsDialog> createState() => _SessionSettingsDialogState();
}

class _SessionSettingsDialogState extends State<SessionSettingsDialog> {
  late bool _enableScoring;
  late int? _timeLimit;
  late bool _showCorrectAnswers;
  late bool _showLeaderboard;
  bool _useCustomTimeLimit = false;

  @override
  void initState() {
    super.initState();
    _enableScoring = widget.initialSettings.enableScoring;
    _timeLimit = widget.initialSettings.timeLimit;
    _showCorrectAnswers = widget.initialSettings.showCorrectAnswers;
    _showLeaderboard = widget.initialSettings.showLeaderboard;
    _useCustomTimeLimit = _timeLimit != null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.settings, color: Colors.blue),
          SizedBox(width: 12),
          Text('Session Settings'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Scoring toggle
            SwitchListTile(
              title: const Text('Enable Scoring'),
              subtitle: const Text('Track player scores and show leaderboard'),
              value: _enableScoring,
              onChanged: (value) => setState(() => _enableScoring = value),
            ),
            const Divider(),

            // Time limit
            SwitchListTile(
              title: const Text('Custom Time Limit'),
              subtitle: Text(
                _useCustomTimeLimit
                    ? 'Override question time limits'
                    : 'Use default time from questions',
              ),
              value: _useCustomTimeLimit,
              onChanged: (value) {
                setState(() {
                  _useCustomTimeLimit = value;
                  if (!value) _timeLimit = null;
                });
              },
            ),
            if (_useCustomTimeLimit) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Time per question: ${_timeLimit ?? 30} seconds',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Slider(
                      value: (_timeLimit ?? 30).toDouble(),
                      min: 5,
                      max: 120,
                      divisions: 23,
                      label: '${_timeLimit ?? 30}s',
                      onChanged: (value) {
                        setState(() => _timeLimit = value.toInt());
                      },
                    ),
                  ],
                ),
              ),
            ],
            const Divider(),

            // Show correct answers
            SwitchListTile(
              title: const Text('Show Correct Answers'),
              subtitle: const Text(
                'Display the right answer after each question',
              ),
              value: _showCorrectAnswers,
              onChanged: (value) => setState(() => _showCorrectAnswers = value),
            ),
            const Divider(),

            // Show leaderboard
            SwitchListTile(
              title: const Text('Show Leaderboard'),
              subtitle: const Text('Display rankings after each question'),
              value: _showLeaderboard,
              onChanged: (value) => setState(() => _showLeaderboard = value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final settings = SessionSettings(
              enableScoring: _enableScoring,
              timeLimit: _timeLimit,
              showCorrectAnswers: _showCorrectAnswers,
              showLeaderboard: _showLeaderboard,
            );
            Navigator.pop(context, settings);
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
