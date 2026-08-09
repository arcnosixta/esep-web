import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Плавное появление карточки, когда она впервые попадает во вьюпорт.
///
/// Слушает позицию родительского [Scrollable] и один раз запускает
/// fadeIn + slideY — так элементы «выплывают» по мере прокрутки,
/// а не все сразу при загрузке страницы. Если родительского
/// [Scrollable] нет — показывается сразу.
class ScrollReveal extends StatefulWidget {
  final Widget child;

  /// Длительность появления.
  final Duration duration;

  /// Дополнительная задержка (для каскада соседних карточек).
  final Duration delay;

  /// Начальный сдвиг по вертикали (0.12 = снизу, -0.12 = сверху).
  final double slideFrom;

  final Curve curve;

  const ScrollReveal({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 450),
    this.delay = Duration.zero,
    this.slideFrom = 0.12,
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<ScrollReveal> createState() => _ScrollRevealState();
}

class _ScrollRevealState extends State<ScrollReveal> {
  ScrollPosition? _position;
  bool _revealed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scrollable = Scrollable.maybeOf(context);
    if (scrollable == null) {
      // Нет скролла (диалог, оверлей) — показываем без ожидания.
      if (!_revealed) setState(() => _revealed = true);
      return;
    }
    if (_position != scrollable.position) {
      _position?.removeListener(_onScroll);
      _position = scrollable.position;
      _position!.addListener(_onScroll);
    }
    _check();
  }

  void _onScroll() => _check();

  void _check() {
    if (_revealed || _position == null || !mounted) return;
    final render = context.findRenderObject();
    if (render is! RenderBox || !render.hasSize) {
      // Первый кадр ещё не отрисован — проверим после него.
      WidgetsBinding.instance.addPostFrameCallback((_) => _check());
      return;
    }
    final viewport = _position!.viewportDimension;
    final top = render.localToGlobal(Offset.zero).dy;
    // Элемент считается «появившимся», когда его верх пересекает
    // нижнюю границу вьюпорта (с небольшим буфером на app bar).
    if (top < viewport * 0.95 + 60) {
      _revealed = true;
      _position!.removeListener(_onScroll);
      setState(() {});
    }
  }

  @override
  void dispose() {
    _position?.removeListener(_onScroll);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_revealed) {
      return widget.child
          .animate(delay: widget.delay)
          .fadeIn(duration: widget.duration, curve: widget.curve)
          .slideY(
            begin: widget.slideFrom,
            end: 0,
            duration: widget.duration,
            curve: widget.curve,
          );
    }
    // До появления во вьюпорте держим невидимым, но на месте.
    return Opacity(opacity: 0, child: widget.child);
  }
}
