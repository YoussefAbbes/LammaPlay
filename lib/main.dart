import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:lamaplay/firebase_options.dart';
import 'package:lamaplay/core/app_theme.dart';
import 'package:lamaplay/core/router.dart';
import 'package:lamaplay/services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Ensure an anonymous user is available on launch.
  await AuthService().ensureSignedInAnonymously();

  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LamaPlay',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      initialRoute: AppRouter.home,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
