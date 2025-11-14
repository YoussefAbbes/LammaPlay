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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.purple[50]!.withOpacity(0.3)],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Gradient header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Row(
                children: const [
                  Icon(Icons.tune, color: Colors.white, size: 28),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Session Settings',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Scoring toggle
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: SwitchListTile(
                        title: const Text(
                          'Enable Scoring',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: const Text(
                          'Track player scores and show leaderboard',
                        ),
                        value: _enableScoring,
                        onChanged: (value) =>
                            setState(() => _enableScoring = value),
                        activeColor: const Color(0xFF667eea),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Time limit
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: SwitchListTile(
                        title: const Text(
                          'Custom Time Limit',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
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
                        activeColor: const Color(0xFF667eea),
                      ),
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
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: SwitchListTile(
                        title: const Text(
                          'Show Correct Answers',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: const Text(
                          'Display the right answer after each question',
                        ),
                        value: _showCorrectAnswers,
                        onChanged: (value) =>
                            setState(() => _showCorrectAnswers = value),
                        activeColor: const Color(0xFF667eea),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Show leaderboard
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: SwitchListTile(
                        title: const Text(
                          'Show Leaderboard',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: const Text(
                          'Display rankings after each question',
                        ),
                        value: _showLeaderboard,
                        onChanged: (value) =>
                            setState(() => _showLeaderboard = value),
                        activeColor: const Color(0xFF667eea),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Action buttons
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF667eea).withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        final settings = SessionSettings(
                          enableScoring: _enableScoring,
                          timeLimit: _timeLimit,
                          showCorrectAnswers: _showCorrectAnswers,
                          showLeaderboard: _showLeaderboard,
                        );
                        Navigator.pop(context, settings);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Apply Settings',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
