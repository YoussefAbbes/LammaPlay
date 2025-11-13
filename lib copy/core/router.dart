import 'package:flutter/material.dart';
import 'package:lamaplay/screens/home_screen.dart';
import 'package:lamaplay/screens/lobby_screen.dart';
import 'package:lamaplay/screens/round_intro_screen.dart';
import 'package:lamaplay/screens/game_shell_screen.dart';
import 'package:lamaplay/screens/results_screen.dart';
import 'package:lamaplay/screens/leaderboard_screen.dart';
import 'package:lamaplay/games/emoji_telepathy/emoji_telepathy_screen.dart';

/// Centralized app routes.
class AppRouter {
  static const String home = '/';
  static const String lobby = '/lobby';
  static const String roundIntro = '/round-intro';
  static const String gameShell = '/game-shell';
  static const String results = '/results';
  static const String leaderboard = '/leaderboard';
  static const String emojiTelepathy = '/emoji-telepathy';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
          settings: settings,
        );
      case lobby:
        return MaterialPageRoute(
          builder: (_) => const LobbyScreen(),
          settings: settings,
        );
      case roundIntro:
        return MaterialPageRoute(
          builder: (_) => const RoundIntroScreen(),
          settings: settings,
        );
      case gameShell:
        return MaterialPageRoute(
          builder: (_) => const GameShellScreen(),
          settings: settings,
        );
      case results:
        return MaterialPageRoute(
          builder: (_) => const ResultsScreen(),
          settings: settings,
        );
      case leaderboard:
        return MaterialPageRoute(
          builder: (_) => const LeaderboardScreen(),
          settings: settings,
        );
      case emojiTelepathy:
        // Expecting args {'roomId':..., 'roundId':...}
        return MaterialPageRoute(
          builder: (ctx) {
            final args =
                ModalRoute.of(ctx)?.settings.arguments as Map<String, String>?;
            final roomId = args?['roomId'];
            final roundId = args?['roundId'];
            if (roomId == null || roundId == null) {
              return const Scaffold(body: Center(child: Text('Missing args')));
            }
            return EmojiTelepathyScreen(roomId: roomId, roundId: roundId);
          },
          settings: settings,
        );
      default:
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('Route not found'))),
          settings: settings,
        );
    }
  }
}
