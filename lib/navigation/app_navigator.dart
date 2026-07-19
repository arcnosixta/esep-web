import 'package:flutter/material.dart';

class AppNavigator {
  static void push(BuildContext context, Widget page) {
    Navigator.of(context).push(_SlideUpRoute(page));
  }

  static void pushReplacement(BuildContext context, Widget page) {
    Navigator.of(context).pushReplacement(_SlideUpRoute(page));
  }

  static void pop(BuildContext context) {
    Navigator.of(context).pop();
  }
}

class _SlideUpRoute extends PageRouteBuilder {
  final Widget page;

  _SlideUpRoute(this.page)
      : super(
          transitionDuration: const Duration(milliseconds: 350),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.08),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        );
}
