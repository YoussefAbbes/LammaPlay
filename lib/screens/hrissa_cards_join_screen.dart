import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lamaplay/services/hrissa_cards_session_service.dart';
import 'package:lamaplay/services/auth_service.dart';
import 'package:lamaplay/services/sound_service.dart';
import 'package:lamaplay/screens/hrissa_cards_multiplayer_screen.dart';

/// Player screen to join Hrissa Cards multiplayer session via PIN
class HrissaCardsJoinScreen extends StatefulWidget {
  const HrissaCardsJoinScreen({super.key});

  @override
  State<HrissaCardsJoinScreen> createState() => _HrissaCardsJoinScreenState();
}

class _HrissaCardsJoinScreenState extends State<HrissaCardsJoinScreen> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final HrissaCardsSessionService _sessionService = HrissaCardsSessionService();
  final AuthService _auth = AuthService();

  bool _isJoining = false;
  String? _errorMessage;

  @override
  void dispose() {
    _pinController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _joinSession() async {
    final pin = _pinController.text.trim();
    final nickname = _nicknameController.text.trim();

    if (pin.isEmpty || pin.length != 6) {
      setState(() => _errorMessage = 'أدخل رمز من 6 أرقام');
      return;
    }

    if (nickname.isEmpty) {
      setState(() => _errorMessage = 'أدخل اسمك');
      return;
    }

    setState(() {
      _isJoining = true;
      _errorMessage = null;
    });

    try {
      SoundService().play(SoundEffect.buttonTap);

      final sessionId = await _sessionService.joinSessionByPin(
        pin: pin,
        playerId: _auth.uid!,
        nickname: nickname,
      );

      if (sessionId == null) {
        setState(() {
          _errorMessage = 'جلسة غير موجودة أو مغلقة';
          _isJoining = false;
        });
        return;
      }

      if (!mounted) return;

      // Navigate to game screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              HrissaCardsMultiplayerScreen(sessionId: sessionId, isHost: false),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'خطأ: $e';
        _isJoining = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Back button
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),

                const SizedBox(height: 32),

                // Title
                const Text(
                  '🌶️',
                  style: TextStyle(fontSize: 80),
                  textAlign: TextAlign.center,
                ).animate().scale(duration: 500.ms),

                const SizedBox(height: 16),

                const Text(
                  'انضم للعبة الهريسة',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 48),

                // Nickname input
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'اسمك',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _nicknameController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                        ),
                        decoration: InputDecoration(
                          hintText: 'أدخل اسمك',
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.3),
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: const Icon(
                            Icons.person,
                            color: Colors.white,
                          ),
                        ),
                        textAlign: TextAlign.center,
                        maxLength: 20,
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.2),

                const SizedBox(height: 24),

                // PIN input
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'رمز الجلسة',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _pinController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 8,
                        ),
                        decoration: InputDecoration(
                          hintText: '000000',
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.3),
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          counterText: '',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.2),

                const SizedBox(height: 16),

                // Error message
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red, width: 2),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().shake(),

                const SizedBox(height: 32),

                // Join button
                SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isJoining ? null : _joinSession,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5733),
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 8,
                        ),
                        child: _isJoining
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'انضم الآن',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 500.ms)
                    .slideY(begin: 0.2)
                    .shimmer(
                      delay: 1000.ms,
                      duration: 2000.ms,
                      color: Colors.white.withOpacity(0.3),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
