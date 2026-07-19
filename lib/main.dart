import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0A0A0F),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const EsepApp());
}

class EsepApp extends StatelessWidget {
  const EsepApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ESEP',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const SplashScreen(),
    );
  }
}
