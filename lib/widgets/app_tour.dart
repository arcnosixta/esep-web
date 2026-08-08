import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Один шаг экскурсии: цель (виджет с GlobalKey) + подпись.
class TourStep {
  final GlobalKey targetKey;
  final String title;
  final String description;
  final IconData icon;

  const TourStep({
    required this.targetKey,
    required this.title,
    required this.description,
    required this.icon,
  });
}

/// Интерактивная экскурсия по интерфейсу (coach marks).
/// Затемняет экран, оставляет «окно» над целевым виджетом
/// и показывает карточку с пояснением. Тап по экрану или
/// кнопка «Далее» — следующий шаг.
class AppTour extends StatefulWidget {
  final List<TourStep> steps;
  final VoidCallback onFinished;

  const AppTour({
    super.key,
    required this.steps,
    required this.onFinished,
  });

  @override
  State<AppTour> createState() => _AppTourState();
}

class _AppTourState extends State<AppTour> {
  OverlayEntry? _entry;

  @override
  void initState() {
    super.initState();
    // Ждём кадр, чтобы целевые виджеты успели отрисоваться.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _entry = OverlayEntry(
        builder: (_) => _TourOverlayView(
          steps: widget.steps,
          onFinished: widget.onFinished,
        ),
      );
      Overlay.of(context).insert(_entry!);
    });
  }

  @override
  void dispose() {
    _entry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _TourOverlayView extends StatefulWidget {
  final List<TourStep> steps;
  final VoidCallback onFinished;

  const _TourOverlayView({required this.steps, required this.onFinished});

  @override
  State<_TourOverlayView> createState() => _TourOverlayViewState();
}

class _TourOverlayViewState extends State<_TourOverlayView>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  late final AnimationController _entrance;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..forward();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _entrance.dispose();
    _pulse.dispose();
    super.dispose();
  }

  void _advance() {
    if (_index < widget.steps.length - 1) {
      setState(() {
        _index++;
        _entrance.forward(from: 0);
      });
    } else {
      widget.onFinished();
    }
  }

  Rect? _targetRect() {
    final ctx = widget.steps[_index].targetKey.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final topLeft = box.localToGlobal(Offset.zero);
    return topLeft & box.size;
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final step = widget.steps[_index];
    final target = _targetRect();
    if (target == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
      return const SizedBox.shrink();
    }

    final screen = MediaQuery.of(context).size;
    final hole = target.inflate(10);

    return Stack(
      children: [
        // Затемнение с «окном» над целью.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _advance,
            child: CustomPaint(
              painter: _SpotlightPainter(
                hole: hole,
                pulse: _pulse,
                accent: c.accent,
              ),
            ),
          ),
        ),
        // Карточка-подсказка.
        Positioned(
          left: 24,
          right: 24,
          top: _cardTop(target, screen),
          child: _buildCard(c, step),
        ),
      ],
    );
  }

  double _cardTop(Rect target, Size screen) {
    const cardHeight = 190.0;
    if (target.bottom + 16 + cardHeight < screen.height) {
      return target.bottom + 16;
    }
    return (target.top - 16 - cardHeight).clamp(12.0, screen.height - cardHeight - 12);
  }

  Widget _buildCard(AppColors c, TourStep step) {
    return ScaleTransition(
      scale: CurvedAnimation(parent: _entrance, curve: Curves.easeOutBack),
      child: FadeTransition(
        opacity: _entrance,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: c.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: c.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(step.icon, color: c.accent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      step.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '${_index + 1} из ${widget.steps.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: c.textHint,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                step.description,
                style: TextStyle(
                  fontSize: 14,
                  color: c.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: _advance,
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [c.accent, c.accentLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        _index == widget.steps.length - 1
                            ? 'Всё понятно!'
                            : 'Далее',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Рисует затемнение с вырезом под целью и пульсирующей рамкой.
class _SpotlightPainter extends CustomPainter {
  final Rect hole;
  final Animation<double> pulse;
  final Color accent;

  _SpotlightPainter({
    required this.hole,
    required this.pulse,
    required this.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scrim = Path()
      ..addRect(Offset.zero & size)
      ..fillType = PathFillType.evenOdd;
    final holePath = Path()..addRRect(RRect.fromRectAndRadius(hole, const Radius.circular(16)));
    final cut = Path.combine(PathOperation.difference, scrim, holePath);
    canvas.drawPath(cut, Paint()..color = Colors.black.withValues(alpha: 0.55));

    // Пульсирующее кольцо вокруг цели.
    final ring = Path()..addRRect(RRect.fromRectAndRadius(hole.inflate(4 + 4 * pulse.value), const Radius.circular(18)));
    canvas.drawPath(
      ring,
      Paint()
        ..color = accent.withValues(alpha: 0.25 + 0.5 * pulse.value)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(hole, const Radius.circular(16)),
      Paint()
        ..color = accent.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) =>
      old.hole != hole || old.pulse != pulse || old.accent != accent;
}
