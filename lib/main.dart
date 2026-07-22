import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/app_shell.dart';
import 'providers/app_settings.dart';
import 'l10n/app_strings.dart';

const openRouterApiKey = 'YOUR_OPENROUTER_API_KEY';

const supabaseUrl = 'https://rphsqxhwfrkavvxzvnuv.supabase.co';
const supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJwaHNxeGh3ZnJrYXZ2eHp2bnV2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ0NTQ4ODcsImV4cCI6MjEwMDAzMDg4N30.dFa8Py2xK0Jw7OSCJSRlPwAgwRGlTYzq8JfSBUkh_TU';

final appSettings = AppSettings();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabaseAnonKey,
  );

  await appSettings.load();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFFAF8F5),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const EsepApp());
}

final supabase = Supabase.instance.client;

class EsepApp extends StatelessWidget {
  const EsepApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appSettings,
      builder: (context, _) {
        return MaterialApp(
          title: 'ESEP',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: appSettings.themeMode,
          locale: appSettings.locale,
          supportedLocales: const [
            Locale('ru'),
            Locale('kk'),
            Locale('en'),
          ],
          localizationsDelegates: const [
            AppStringsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const AuthGate(),
        );
      },
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Stream<AuthState> _authStream;

  @override
  void initState() {
    super.initState();
    _authStream = Supabase.instance.client.auth.onAuthStateChange;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _authStream,
      builder: (context, snapshot) {
        final session = snapshot.data?.session;
        if (session != null) {
          return const AppShell();
        }
        return const SplashScreen();
      },
    );
  }
}
