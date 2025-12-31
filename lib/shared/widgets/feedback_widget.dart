import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Centralized feedback widget for success and error states
/// Displays centered, animated feedback with auto-dismiss
class FeedbackWidget {
  /// Show success feedback with celebratory animations
  /// - Displays in center of screen
  /// - Green/accent colors for positive reinforcement
  /// - Auto-dismisses after 2-3 seconds
  /// - Optional confetti effect
  static void showSuccess(
    BuildContext context, {
    required String message,
    String? subtitle,
    bool showConfetti = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _FeedbackOverlay(
        message: message,
        subtitle: subtitle,
        type: FeedbackType.success,
        showConfetti: showConfetti,
        onDismiss: () => overlayEntry.remove(),
      ),
    );

    overlay.insert(overlayEntry);

    // Auto-dismiss after duration
    Future.delayed(duration, () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  /// Show error feedback with attention-grabbing animations
  /// - Displays in center of screen
  /// - Red/warning colors
  /// - Subtle shake animation
  /// - Auto-dismisses after 2-3 seconds
  static void showError(
    BuildContext context, {
    required String message,
    String? subtitle,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _FeedbackOverlay(
        message: message,
        subtitle: subtitle,
        type: FeedbackType.error,
        onDismiss: () => overlayEntry.remove(),
      ),
    );

    overlay.insert(overlayEntry);

    // Auto-dismiss after duration
    Future.delayed(duration, () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  /// Show info feedback for neutral messages
  static void showInfo(
    BuildContext context, {
    required String message,
    String? subtitle,
    Duration duration = const Duration(seconds: 2),
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _FeedbackOverlay(
        message: message,
        subtitle: subtitle,
        type: FeedbackType.info,
        onDismiss: () => overlayEntry.remove(),
      ),
    );

    overlay.insert(overlayEntry);

    // Auto-dismiss after duration
    Future.delayed(duration, () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }
}

enum FeedbackType { success, error, info }

class _FeedbackOverlay extends StatelessWidget {
  final String message;
  final String? subtitle;
  final FeedbackType type;
  final bool showConfetti;
  final VoidCallback onDismiss;

  const _FeedbackOverlay({
    required this.message,
    this.subtitle,
    required this.type,
    this.showConfetti = false,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    // Get colors based on type
    Color backgroundColor;
    Color iconColor;
    IconData icon;
    List<Color> gradientColors;

    switch (type) {
      case FeedbackType.success:
        backgroundColor = Colors.green;
        iconColor = Colors.white;
        icon = Icons.check_circle;
        gradientColors = [Colors.green.shade400, Colors.green.shade700];
        break;
      case FeedbackType.error:
        backgroundColor = Colors.red;
        iconColor = Colors.white;
        icon = Icons.error;
        gradientColors = [Colors.red.shade400, Colors.red.shade700];
        break;
      case FeedbackType.info:
        backgroundColor = Colors.blue;
        iconColor = Colors.white;
        icon = Icons.info;
        gradientColors = [Colors.blue.shade400, Colors.blue.shade700];
        break;
    }

    return Material(
      color: Colors.black54, // Semi-transparent backdrop
      child: Stack(
        children: [
          // Backdrop - tap to dismiss
          Positioned.fill(
            child: GestureDetector(
              onTap: onDismiss,
              child: Container(color: Colors.transparent),
            ),
          ),

          // Centered feedback card
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: backgroundColor.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 5,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon with animation
                  Icon(
                    icon,
                    size: 64,
                    color: iconColor,
                  )
                      .animate()
                      .fadeIn(duration: 300.ms)
                      .scale(
                        delay: 100.ms,
                        duration: 400.ms,
                        begin: const Offset(0.5, 0.5),
                        end: const Offset(1, 1),
                        curve: Curves.elasticOut,
                      )
                      .then() // Add shake for errors
                      .shake(
                        hz: type == FeedbackType.error ? 4 : 0,
                        duration: type == FeedbackType.error ? 400.ms : 0.ms,
                      ),

                  const SizedBox(height: 16),

                  // Message
                  Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  )
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 400.ms)
                      .slideY(begin: 0.3, end: 0, duration: 400.ms),

                  // Subtitle (optional)
                  if (subtitle != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    )
                        .animate()
                        .fadeIn(delay: 300.ms, duration: 400.ms)
                        .slideY(begin: 0.3, end: 0, duration: 400.ms),
                  ],
                ],
              ),
            )
                .animate()
                .fadeIn(duration: 300.ms)
                .scale(
                  duration: 400.ms,
                  curve: Curves.elasticOut,
                ),
          ),

          // Confetti effect for success (optional)
          if (showConfetti && type == FeedbackType.success)
            ..._buildConfettiParticles(context),
        ],
      ),
    );
  }

  /// Build confetti particles for celebration effect
  List<Widget> _buildConfettiParticles(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final colors = [
      Colors.yellow,
      Colors.orange,
      Colors.pink,
      Colors.purple,
      Colors.blue,
      Colors.green,
    ];

    return List.generate(20, (index) {
      final color = colors[index % colors.length];
      final left = (index % 5) * (screenSize.width / 5);
      
      return Positioned(
        left: left,
        top: -20,
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        )
            .animate(
              delay: (index * 50).ms,
              onComplete: (controller) => controller.repeat(),
            )
            .moveY(
              begin: -20,
              end: screenSize.height + 20,
              duration: (2000 + index * 100).ms,
              curve: Curves.easeIn,
            )
            .fadeOut(begin: 0.8, duration: 500.ms),
      );
    });
  }
}

/// Inline feedback banner (alternative to overlay)
/// Use this for less intrusive feedback at the top/bottom of screen
class FeedbackBanner extends StatelessWidget {
  final String message;
  final FeedbackType type;
  final VoidCallback? onTap;

  const FeedbackBanner({
    super.key,
    required this.message,
    required this.type,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    IconData icon;

    switch (type) {
      case FeedbackType.success:
        backgroundColor = Colors.green.shade600;
        icon = Icons.check_circle;
        break;
      case FeedbackType.error:
        backgroundColor = Colors.red.shade600;
        icon = Icons.error;
        break;
      case FeedbackType.info:
        backgroundColor = Colors.blue.shade600;
        icon = Icons.info;
        break;
    }

    return Material(
      color: backgroundColor,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(Icons.close, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: -1, end: 0, duration: 400.ms, curve: Curves.easeOut)
        .then()
        .shake(
          hz: type == FeedbackType.error ? 2 : 0,
          duration: type == FeedbackType.error ? 300.ms : 0.ms,
        );
  }
}
