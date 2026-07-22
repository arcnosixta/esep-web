import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../navigation/app_navigator.dart';
import 'ai_chat_screen.dart';
import 'home_screen.dart';
import 'cases_list_screen.dart';
import 'document_upload_screen.dart';
import 'profile_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  late final List<Widget> _pages = [
    HomeScreen(onDocumentsTap: () => setState(() => _currentIndex = 2)),
    const CasesListScreen(),
    const DocumentUploadScreen(),
    const ProfileScreen(),
  ];

  void _onNavTap(int index) {
    if (index == 4) {
      AppNavigator.push(context, const AiChatScreen());
      return;
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(0, Icons.home_rounded, 'Главная'),
                _navItem(1, Icons.folder_rounded, 'Заявки'),
                _navItem(4, Icons.auto_awesome_rounded, 'AI'),
                _navItem(2, Icons.description_rounded, 'Документы'),
                _navItem(3, Icons.person_rounded, 'Профиль'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final active = _currentIndex == index;
    final isAi = index == 4;

    return GestureDetector(
      onTap: () => _onNavTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            isAi
                ? Container(
                    width: 44,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.accent, AppColors.accentLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  )
                : Container(
                    width: 44,
                    height: 32,
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.accent.withValues(alpha: 0.08)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      size: 22,
                      color: active ? AppColors.accent : AppColors.textHint,
                    ),
                  ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: (active || isAi) ? FontWeight.w600 : FontWeight.w400,
                color: isAi
                    ? AppColors.accent
                    : active
                        ? AppColors.accent
                        : AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
