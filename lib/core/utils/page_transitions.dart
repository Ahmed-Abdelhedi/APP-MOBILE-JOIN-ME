import 'package:flutter/material.dart';

/// Custom page transitions for smooth navigation
/// Modern animations with fade, slide, and scale effects
class PageTransitions {
  /// Fade and slide up transition (default for details screens)
  static Route<T> fadeSlideUp<T>(Widget page, {Duration? duration}) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 0.05);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        var fadeTween = Tween(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: FadeTransition(
            opacity: animation.drive(fadeTween),
            child: child,
          ),
        );
      },
      transitionDuration: duration ?? const Duration(milliseconds: 350),
    );
  }

  /// Fade transition only
  static Route<T> fade<T>(Widget page, {Duration? duration}) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation.drive(
            Tween(begin: 0.0, end: 1.0).chain(
              CurveTween(curve: Curves.easeOut),
            ),
          ),
          child: child,
        );
      },
      transitionDuration: duration ?? const Duration(milliseconds: 300),
    );
  }

  /// Scale and fade transition (for modals/popups)
  static Route<T> scaleFade<T>(Widget page, {Duration? duration}) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeOutCubic;

        var scaleTween = Tween(begin: 0.9, end: 1.0).chain(
          CurveTween(curve: curve),
        );

        var fadeTween = Tween(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: curve),
        );

        return ScaleTransition(
          scale: animation.drive(scaleTween),
          child: FadeTransition(
            opacity: animation.drive(fadeTween),
            child: child,
          ),
        );
      },
      transitionDuration: duration ?? const Duration(milliseconds: 300),
    );
  }

  /// Slide from right transition (for navigation flow)
  static Route<T> slideRight<T>(Widget page, {Duration? duration}) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: duration ?? const Duration(milliseconds: 350),
    );
  }

  /// Slide from bottom (for bottom sheets converted to pages)
  static Route<T> slideBottom<T>(Widget page, {Duration? duration}) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: duration ?? const Duration(milliseconds: 400),
    );
  }

  /// Shared axis horizontal (Material 3 style)
  static Route<T> sharedAxisHorizontal<T>(Widget page, {Duration? duration}) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeInOutCubic;

        // Entering page slides in from right
        var slideInTween = Tween(
          begin: const Offset(0.3, 0.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: curve));

        var fadeInTween = Tween(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: curve),
        );

        // Exiting page slides out to left
        var slideOutTween = Tween(
          begin: Offset.zero,
          end: const Offset(-0.3, 0.0),
        ).chain(CurveTween(curve: curve));

        var fadeOutTween = Tween(begin: 1.0, end: 0.0).chain(
          CurveTween(curve: curve),
        );

        return Stack(
          children: [
            // Outgoing page
            SlideTransition(
              position: secondaryAnimation.drive(slideOutTween),
              child: FadeTransition(
                opacity: secondaryAnimation.drive(fadeOutTween),
                child: const SizedBox.shrink(),
              ),
            ),
            // Incoming page
            SlideTransition(
              position: animation.drive(slideInTween),
              child: FadeTransition(
                opacity: animation.drive(fadeInTween),
                child: child,
              ),
            ),
          ],
        );
      },
      transitionDuration: duration ?? const Duration(milliseconds: 400),
    );
  }

  /// No animation (instant transition)
  static Route<T> none<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: Duration.zero,
    );
  }
}

/// Extension on Navigator for easier transitions
extension NavigatorTransitions on NavigatorState {
  /// Push with fade slide up transition
  Future<T?> pushFadeSlideUp<T>(Widget page) {
    return push<T>(PageTransitions.fadeSlideUp<T>(page));
  }

  /// Push with fade transition
  Future<T?> pushFade<T>(Widget page) {
    return push<T>(PageTransitions.fade<T>(page));
  }

  /// Push with scale fade transition
  Future<T?> pushScaleFade<T>(Widget page) {
    return push<T>(PageTransitions.scaleFade<T>(page));
  }

  /// Push with slide right transition
  Future<T?> pushSlideRight<T>(Widget page) {
    return push<T>(PageTransitions.slideRight<T>(page));
  }

  /// Push with slide bottom transition
  Future<T?> pushSlideBottom<T>(Widget page) {
    return push<T>(PageTransitions.slideBottom<T>(page));
  }
}
