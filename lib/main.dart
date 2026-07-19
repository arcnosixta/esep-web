import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/registration_screen.dart';
import 'screens/ai_assistant_screen.dart';
import 'screens/document_upload_screen.dart';
import 'screens/application_card_screen.dart';
import 'screens/my_applications_screen.dart';
import 'screens/payment_screen.dart';
import 'screens/report_screen.dart';
import 'screens/appraiser_cabinet_screen.dart';
import 'screens/admin_panel_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0D0D0F),
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

/// Quick navigation hub — tap any screen to open it.
/// This is a dev-only launcher; in production, replace with proper routing.
class ScreenLauncher extends StatelessWidget {
  const ScreenLauncher({super.key});

  @override
  Widget build(BuildContext context) {
    final screens = <Map<String, dynamic>>[
      {'title': 'Splash', 'widget': const SplashScreen()},
      {'title': 'Регистрация', 'widget': const RegistrationScreen()},
      {'title': 'AI-ассистент', 'widget': const AiAssistantScreen()},
      {'title': 'Загрузка документов', 'widget': const DocumentUploadScreen()},
      {'title': 'Карточка заявки', 'widget': const ApplicationCardScreen()},
      {'title': 'Мои заявки', 'widget': const MyApplicationsScreen()},
      {'title': 'Оплата', 'widget': const PaymentScreen()},
      {'title': 'Отчёт', 'widget': const ReportScreen()},
      {'title': 'Кабинет оценщика', 'widget': const AppraiserCabinetScreen()},
      {'title': 'Админ-панель', 'widget': const AdminPanelScreen()},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('ESEP — Все экраны')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: screens.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final entry = screens[index];
          return ListTile(
            title: Text(entry['title'] as String),
            subtitle: Text('Экран ${index + 1}'),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF7C3AED).withValues(alpha: 0.15),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Color(0xFF7C3AED),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF5C5C66),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            tileColor: const Color(0xFF1A1A1F),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => entry['widget'] as Widget),
              );
            },
          );
        },
      ),
    );
  }
}
