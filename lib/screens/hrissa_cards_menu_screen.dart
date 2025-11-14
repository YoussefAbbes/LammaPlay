import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lamaplay/services/hrissa_cards_session_service.dart';
import 'package:lamaplay/services/auth_service.dart';
import 'package:lamaplay/services/sound_service.dart';
import 'package:lamaplay/screens/hrissa_cards_screen.dart';
import 'package:lamaplay/screens/hrissa_cards_host_lobby_screen.dart';
import 'package:lamaplay/screens/hrissa_cards_join_screen.dart';

/// Menu to select Hrissa Cards game mode: Solo or Multiplayer
class HrissaCardsMenuScreen extends StatefulWidget {
  const HrissaCardsMenuScreen({super.key});

  @override
  State<HrissaCardsMenuScreen> createState() => _HrissaCardsMenuScreenState();
}

class _HrissaCardsMenuScreenState extends State<HrissaCardsMenuScreen> {
  final HrissaCardsSessionService _sessionService = HrissaCardsSessionService();
  final AuthService _auth = AuthService();
  bool _isCreatingSession = false;

  Future<void> _playSolo() async {
    SoundService().play(SoundEffect.buttonTap);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HrissaCardsScreen()),
    );
  }

  Future<void> _hostMultiplayer() async {
    if (_isCreatingSession) return;

    setState(() => _isCreatingSession = true);

    try {
      SoundService().play(SoundEffect.buttonTap);

      // Show nickname dialog
      final nickname = await _showNicknameDialog();
      if (nickname == null || !mounted) {
        setState(() => _isCreatingSession = false);
        return;
      }

      // Create session
      final result = await _sessionService.createSession(
        hostId: _auth.uid!,
        hostNickname: nickname,
      );

      if (!mounted) return;

      // Navigate to lobby
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => HrissaCardsHostLobbyScreen(
            sessionId: result['sessionId']!,
            pin: result['pin']!,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isCreatingSession = false);
      }
    }
  }

  Future<void> _joinMultiplayer() async {
    SoundService().play(SoundEffect.buttonTap);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HrissaCardsJoinScreen()),
    );
  }

  Future<String?> _showNicknameDialog() async {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213e),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'اسمك',
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 20),
          decoration: InputDecoration(
            hintText: 'أدخل اسمك',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          textAlign: TextAlign.center,
          maxLength: 20,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              final nickname = controller.text.trim();
              if (nickname.isNotEmpty) {
                Navigator.pop(context, nickname);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5733),
            ),
            child: const Text('تأكيد', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Logo
                      const Text(
                        '🌶️',
                        style: TextStyle(fontSize: 100),
                      ).animate().scale(duration: 500.ms),

                      const SizedBox(height: 24),

                      const Text(
                        'الهريسة 2',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ).animate().fadeIn(delay: 200.ms),

                      const SizedBox(height: 8),

                      Text(
                        'اختار طريقة اللعب',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 18,
                        ),
                      ).animate().fadeIn(delay: 300.ms),

                      const SizedBox(height: 48),

                      // Solo button
                      _buildGameModeCard(
                        title: 'فردي',
                        subtitle: 'العب لوحدك',
                        icon: Icons.person,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                        ),
                        onTap: _playSolo,
                        delay: 400,
                      ),

                      const SizedBox(height: 20),

                      // Host multiplayer button
                      _buildGameModeCard(
                        title: 'استضف جلسة',
                        subtitle: 'العب مع أصدقائك',
                        icon: Icons.group_add,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF5733), Color(0xFFFF8C42)],
                        ),
                        onTap: _hostMultiplayer,
                        isLoading: _isCreatingSession,
                        delay: 500,
                      ),

                      const SizedBox(height: 20),

                      // Join multiplayer button
                      _buildGameModeCard(
                        title: 'انضم لجلسة',
                        subtitle: 'أدخل رمز الجلسة',
                        icon: Icons.login,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
                        ),
                        onTap: _joinMultiplayer,
                        delay: 600,
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameModeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
    bool isLoading = false,
    required int delay,
  }) {
    return GestureDetector(
          onTap: isLoading ? null : onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: isLoading
                ? const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: Colors.white, size: 32),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, color: Colors.white),
                    ],
                  ),
          ),
        )
        .animate()
        .fadeIn(delay: delay.ms, duration: 400.ms)
        .slideX(begin: -0.2, delay: delay.ms, duration: 400.ms);
  }
}
