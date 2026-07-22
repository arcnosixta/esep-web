import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/border_icon.dart';
import 'home_screen.dart';
import 'my_applications_screen.dart';
import 'document_upload_screen.dart';
import 'ai_assistant_screen.dart';
import 'profile_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  final _pages = const [
    HomeScreen(),
    AiAssistantScreen(),
    MyApplicationsScreen(),
    DocumentUploadScreen(),
    ProfileScreen(),
  ];

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
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(0, Icons.home_rounded),
                _navItem(1, Icons.chat_bubble_rounded),
                _navItem(2, Icons.description_rounded),
                _navItem(3, Icons.folder_rounded),
                _navItem(4, Icons.person_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon) {
    final active = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: BorderIcon(
        width: 44,
        height: 38,
        padding: EdgeInsets.zero,
        borderRadius: 12,
        backgroundColor: active
            ? AppColors.accent.withValues(alpha: 0.08)
            : Colors.transparent,
        borderColor: Colors.transparent,
        child: Icon(
          icon,
          size: 22,
          color: active ? AppColors.accent : AppColors.textHint,
        ),
      ),
    );
  }
}
