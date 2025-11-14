import 'package:flutter/material.dart';
import 'package:lamaplay/screens/home_screen_new.dart';
import 'package:lamaplay/screens/lobby_screen.dart';
import 'package:lamaplay/screens/round_intro_screen.dart';
import 'package:lamaplay/screens/game_shell_screen.dart';
import 'package:lamaplay/screens/results_screen.dart';
import 'package:lamaplay/screens/leaderboard_screen.dart';
import 'package:lamaplay/games/emoji_telepathy/emoji_telepathy_screen.dart';
import 'package:lamaplay/core/flags.dart';
import 'package:lamaplay/screens/session_lobby_screen.dart';
import 'package:lamaplay/screens/quiz_builder_screen_simple.dart';
import 'package:lamaplay/screens/question_host_screen.dart';
import 'package:lamaplay/screens/question_player_screen.dart';
import 'package:lamaplay/screens/question_reveal_screen.dart';
import 'package:lamaplay/screens/question_leaderboard_screen.dart';
import 'package:lamaplay/screens/podium_screen.dart';
import 'package:lamaplay/screens/global_leaderboard_screen.dart';

/// Centralized app routes.
class AppRouter {
  static const String home = '/';
  static const String lobby = '/lobby';
  static const String roundIntro = '/round-intro';
  static const String gameShell = '/game-shell';
  static const String results = '/results';
  static const String leaderboard = '/leaderboard';
  static const String emojiTelepathy = '/emoji-telepathy';
  static const String sessionLobby = '/sessionLobby';
  static const String quizBuilder = '/quizBuilder';
  static const String questionHost = '/questionHost';
  static const String questionPlayer = '/questionPlayer';
  static const String questionReveal = '/questionReveal';
  static const String questionLeaderboard = '/questionLeaderboard';
  static const String podium = '/podium';
  static const String globalLeaderboard = '/globalLeaderboard';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(
          builder: (_) => const HomeScreenNew(),
          settings: settings,
        );
      case quizBuilder:
        return MaterialPageRoute(
          builder: (_) => const QuizBuilderScreenSimple(),
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
        if (!enableLegacyGames) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text('Legacy games disabled')),
            ),
            settings: settings,
          );
        }
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
      case sessionLobby:
        return MaterialPageRoute(
          builder: (ctx) {
            final sessionId = settings.arguments as String?;
            if (sessionId == null) {
              return const Scaffold(
                body: Center(child: Text('Missing session id')),
              );
            }
            return SessionLobbyScreen(sessionId: sessionId);
          },
          settings: settings,
        );
      case questionHost:
        return MaterialPageRoute(
          builder: (ctx) {
            final sessionId = settings.arguments as String?;
            if (sessionId == null) {
              return const Scaffold(
                body: Center(child: Text('Missing session id')),
              );
            }
            return QuestionHostScreen(sessionId: sessionId);
          },
          settings: settings,
        );
      case questionPlayer:
        return MaterialPageRoute(
          builder: (ctx) {
            final sessionId = settings.arguments as String?;
            if (sessionId == null) {
              return const Scaffold(
                body: Center(child: Text('Missing session id')),
              );
            }
            return QuestionPlayerScreen(sessionId: sessionId);
          },
          settings: settings,
        );
      case questionReveal:
        return MaterialPageRoute(
          builder: (ctx) {
            final sessionId = settings.arguments as String?;
            if (sessionId == null) {
              return const Scaffold(
                body: Center(child: Text('Missing session id')),
              );
            }
            return QuestionRevealScreen(sessionId: sessionId);
          },
          settings: settings,
        );
      case questionLeaderboard:
        return MaterialPageRoute(
          builder: (ctx) {
            final args = settings.arguments as Map<String, dynamic>?;
            if (args == null || args['sessionId'] == null) {
              return const Scaffold(
                body: Center(
                  child: Text('Missing session id or question index'),
                ),
              );
            }
            return QuestionLeaderboardScreen(
              sessionId: args['sessionId'] as String,
              qIndex: args['qIndex'] as int,
            );
          },
          settings: settings,
        );
      case podium:
        return MaterialPageRoute(
          builder: (ctx) {
            final sessionId = settings.arguments as String?;
            if (sessionId == null) {
              return const Scaffold(
                body: Center(child: Text('Missing session id')),
              );
            }
            return PodiumScreen(sessionId: sessionId);
          },
          settings: settings,
        );
      case globalLeaderboard:
        return MaterialPageRoute(
          builder: (_) => const GlobalLeaderboardScreen(),
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
