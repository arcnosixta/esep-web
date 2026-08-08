import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../l10n/app_strings.dart';
import '../navigation/app_navigator.dart';
import '../providers/app_settings.dart';
import '../widgets/app_tour.dart';
import 'ai_chat_screen.dart';
import 'home_screen.dart';
import 'cases_list_screen.dart';
import 'document_upload_screen.dart';
import 'profile_screen.dart';

class AppShell extends StatefulWidget {
  /// Показывать ли экскурсию по интерфейсу при первом открытии.
  final bool startTour;

  const AppShell({super.key, this.startTour = false});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;
  bool _tourActive = false;

  // Цели экскурсии: ключи навигационных элементов.
  final _homeNewAppKey = GlobalKey();
  final _aiNavKey = GlobalKey();
  final _casesNavKey = GlobalKey();
  final _documentsNavKey = GlobalKey();

  late final List<Widget> _pages = [
    HomeScreen(
      onDocumentsTap: () => setState(() => _currentIndex = 2),
      newAppKey: _homeNewAppKey,
    ),
    const CasesListScreen(),
    const DocumentUploadScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.startTour) {
      // Ждём кадр, чтобы все цели отрисовались.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _tourActive = true);
      });
    }
  }

  void _finishTour() {
    setState(() => _tourActive = false);
    appSettings.setTourDone();
  }

  void _onNavTap(int index) {
    if (index == 4) {
      AppNavigator.push(context, const AiChatScreen());
      return;
    }
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final s = AppStrings.of(context);

    final navItems = [
      (index: 0, icon: Icons.home_rounded, label: s.navHome),
      (index: 1, icon: Icons.folder_rounded, label: s.navCases),
      (index: 4, icon: Icons.auto_awesome_rounded, label: s.navAi),
      (index: 2, icon: Icons.description_rounded, label: s.navDocuments),
      (index: 3, icon: Icons.person_rounded, label: s.navProfile),
    ];

    final shell = Scaffold(
      body: Stack(
        children: List.generate(_pages.length, (i) {
          final active = i == _currentIndex;
          return IgnorePointer(
            ignoring: !active,
            child: AnimatedSlide(
              offset: active ? Offset.zero : const Offset(0, 0.015),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: AnimatedOpacity(
                opacity: active ? 1 : 0,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                child: TickerMode(
                  enabled: active,
                  child: _pages[i],
                ),
              ),
            ),
          );
        }),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(
            top: BorderSide(color: c.borderLight, width: 1),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: navItems.map((item) => _navItem(
                item.index,
                item.icon,
                item.label,
              )).toList(),
            ),
          ),
        ),
      ),
    );

    // Поверх оболочки — экскурсия (затемнение с подсветкой целей).
    return Stack(
      children: [
        shell,
        if (_tourActive)
          AppTour(
            steps: [
              TourStep(
                targetKey: _homeNewAppKey,
                title: 'Новая заявка',
                description:
                    'Всё начинается здесь: выберите тип недвижимости, '
                    'укажите адрес и площадь — и отправьте заявку. '
                    'Чем больше деталей, тем точнее оценка.',
                icon: Icons.edit_note_rounded,
              ),
              TourStep(
                targetKey: _aiNavKey,
                title: 'ИИ-оценка',
                description:
                    'Не хотите заполнять форму? Напишите ИИ пару слов или '
                    'пришлите фото — он сам составит заявку и оценит объект.',
                icon: Icons.auto_awesome_rounded,
              ),
              TourStep(
                targetKey: _casesNavKey,
                title: 'Заявки',
                description:
                    'Здесь живут все ваши заявки. Статус обновляется '
                    'автоматически: от «Новой» до готового отчёта.',
                icon: Icons.folder_rounded,
              ),
              TourStep(
                targetKey: _documentsNavKey,
                title: 'Документы',
                description:
                    'Приложите документы по объекту — правоустанавливающие '
                    'бумаги, план или фото. Это ускоряет оценку.',
                icon: Icons.description_rounded,
              ),
            ],
            onFinished: _finishTour,
          ),
      ],
    );
  }

  GlobalKey? _navKeyFor(int index) => switch (index) {
        1 => _casesNavKey,
        2 => _documentsNavKey,
        4 => _aiNavKey,
        _ => null,
      };

  Widget _navItem(int index, IconData icon, String label) {
    final c = AppColors.of(context);
    final active = _currentIndex == index;
    final isAi = index == 4;

    return GestureDetector(
      onTap: () => _onNavTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        key: _navKeyFor(index),
        width: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: active ? 1.0 : 0.9,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutBack,
              child: isAi
                  ? const _AiNavButton()
                  : AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                      width: 44,
                      height: 32,
                      decoration: BoxDecoration(
                        color: active
                            ? c.accent.withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        icon,
                        size: 22,
                        color: active ? c.accent : c.textHint,
                      ),
                    ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              style: TextStyle(
                fontSize: 10,
                fontWeight: (active || isAi) ? FontWeight.w700 : FontWeight.w400,
                color: (active || isAi) ? c.accent : c.textHint,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

/// AI-кнопка в навбаре: градиент + пульсирующее свечение.
class _AiNavButton extends StatefulWidget {
  const _AiNavButton();

  @override
  State<_AiNavButton> createState() => _AiNavButtonState();
}

class _AiNavButtonState extends State<_AiNavButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _glow;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _glow = Tween<double>(begin: 0.35, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Transform.scale(
          scale: _scale.value,
          child: Container(
            width: 44,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [c.accent, c.accentLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: c.accent.withValues(alpha: 0.15 * _glow.value),
                  blurRadius: 6 + 10 * _glow.value,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 18,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}
