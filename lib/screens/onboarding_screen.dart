import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';

/// Интерактивная инструкция для новых пользователей.
/// Показывается один раз после первого входа: 4 слайда
/// объясняют, как устроено приложение и где что писать.
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;

  /// Вызывается при нажатии «Пропустить» (без экскурсии по интерфейсу).
  final VoidCallback onSkip;

  const OnboardingScreen({
    super.key,
    required this.onDone,
    required this.onSkip,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  static const _slideCount = 4;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _slideCount - 1) {
      _controller.animateToPage(
        _page + 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      widget.onDone();
    }
  }

  void _skip() => widget.onSkip();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            // Верхняя панель: логотип + «Пропустить».
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ESEP',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                      color: c.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: _skip,
                    child: Text(
                      'Пропустить',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: c.textHint,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slideCount,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, index) => _Slide(data: _slides[index]),
              ),
            ),
            // Индикатор + кнопка.
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slideCount,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == _page ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _page
                              ? c.accent
                              : c.muted.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: PrimaryButtonCta(
                      label: _page == _slideCount - 1
                          ? 'Начать работу'
                          : 'Далее',
                      icon: _page == _slideCount - 1
                          ? Icons.rocket_launch_rounded
                          : Icons.arrow_forward_rounded,
                      onPressed: _next,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Кнопка «Далее / Начать работу» — с анимацией нажатия.
class PrimaryButtonCta extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const PrimaryButtonCta({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  State<PrimaryButtonCta> createState() => _PrimaryButtonCtaState();
}

class _PrimaryButtonCtaState extends State<PrimaryButtonCta> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 110),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          height: 54,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [c.accent, c.accentLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: c.accent.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlideData {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _SlideData({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}

const _slides = [
  _SlideData(
    icon: Icons.home_work_rounded,
    title: 'Добро пожаловать в ESEP',
    description:
        'Онлайн-оценка недвижимости в Казахстане. Опишите объект — '
        'получите стоимость и официальный отчёт, не выходя из дома.',
    color: Color(0xFF2D6CDF),
  ),
  _SlideData(
    icon: Icons.edit_note_rounded,
    title: 'Опишите объект',
    description:
        'Нажмите «Новая заявка» и укажите, что за недвижимость: квартира, '
        'дом или участок. Адрес, площадь, состояние — чем подробнее, тем '
        'точнее оценка.',
    color: Color(0xFF0FA47A),
  ),
  _SlideData(
    icon: Icons.auto_awesome_rounded,
    title: 'ИИ поможет',
    description:
        'Не знаете, как описать? Откройте ИИ-чат: напишите пару слов или '
        'пришлите фото — ИИ сам составит заявку и сделает предварительную '
        'оценку.',
    color: Color(0xFF7C4DFF),
  ),
  _SlideData(
    icon: Icons.task_alt_rounded,
    title: 'Документы, оплата и отчёт',
    description:
        'Приложите документы, оплатите онлайн и следите за статусом заявки. '
        'Готовый отчёт появится прямо в приложении.',
    color: Color(0xFFE8A33D),
  ),
];

class _Slide extends StatelessWidget {
  final _SlideData data;

  const _Slide({required this.data});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Иконка в градиентном «пузыре» с мягким свечением.
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  data.color.withValues(alpha: 0.16),
                  data.color.withValues(alpha: 0.03),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      data.color.withValues(alpha: 0.9),
                      data.color,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: data.color.withValues(alpha: 0.35),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Icon(data.icon, size: 48, color: Colors.white),
              ),
            ),
          ).animate().scale(
                begin: const Offset(0.7, 0.7),
                duration: 550.ms,
                curve: Curves.easeOutBack,
              ),
          const SizedBox(height: 40),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: c.textPrimary,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.15),
          const SizedBox(height: 14),
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: c.textSecondary,
              height: 1.55,
            ),
          ).animate(delay: 120.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),
        ],
      ),
    );
  }
}
