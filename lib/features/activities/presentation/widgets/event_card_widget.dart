import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/models/activity_model.dart';
import 'package:mobile/core/services/activity_service.dart';
import 'package:mobile/core/services/notification_service.dart';
import '../../../../shared/widgets/feedback_widget.dart';
import '../screens/activity_details_screen.dart';
import 'activity_image_widget.dart';

/// Enhanced event card widget with modern design
/// - Vibrant colors and gradients
/// - Smooth animations
/// - Navigation to details
/// - Join/leave with feedback
class EventCardWidget extends ConsumerStatefulWidget {
  final ActivityModel activity;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onChatOpen;
  final int index; // For staggered animations

  const EventCardWidget({
    super.key,
    required this.activity,
    this.onFavoriteToggle,
    this.onChatOpen,
    this.index = 0,
  });

  @override
  ConsumerState<EventCardWidget> createState() => _EventCardWidgetState();
}

class _EventCardWidgetState extends ConsumerState<EventCardWidget> {
  bool _isLoading = false;

  /// Navigate to event details with smooth transition
  void _navigateToDetails() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ActivityDetailsScreen(activity: widget.activity.toMap()),
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
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  /// Join event with feedback
  Future<void> _joinEvent() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final activityService = ref.read(activityServiceProvider);
      final notificationService = NotificationService();

      await activityService.joinActivity(widget.activity.id);

      // Schedule notification
      await notificationService.scheduleEventNotification(
        activityId: widget.activity.id,
        activityTitle: widget.activity.title,
        eventDateTime: widget.activity.dateTime,
        description: widget.activity.description,
      );

      if (mounted) {
        FeedbackWidget.showSuccess(
          context,
          message: '🎉 Inscrit !',
          subtitle: widget.activity.title,
          showConfetti: true,
        );
      }
    } catch (e) {
      if (mounted) {
        String message = 'Erreur d\'inscription';
        if (e.toString().contains('full')) {
          message = 'Événement complet';
        }
        FeedbackWidget.showError(
          context,
          message: message,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Leave event with feedback
  Future<void> _leaveEvent() async {
    if (_isLoading) return;

    // Confirm dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.exit_to_app, color: Colors.orange.shade700),
            const SizedBox(width: 8),
            const Text('Quitter ?'),
          ],
        ),
        content: Text('Voulez-vous quitter "${widget.activity.title}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final activityService = ref.read(activityServiceProvider);
      final notificationService = NotificationService();

      await activityService.leaveActivity(widget.activity.id);
      await notificationService.cancelEventNotification(widget.activity.id);

      if (mounted) {
        FeedbackWidget.showInfo(
          context,
          message: 'Vous avez quitté',
          subtitle: 'Notification annulée',
        );
      }
    } catch (e) {
      if (mounted) {
        FeedbackWidget.showError(
          context,
          message: 'Erreur',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activity = widget.activity;
    final isPast = activity.isPast;
    final isFull = activity.isFull;

    // Get category color
    final categoryColor = AppColors.categoryColors[activity.category.toLowerCase()] ??
        AppColors.primary;

    return StreamBuilder<bool>(
      stream: ref.read(activityServiceProvider).hasJoinedStream(activity.id),
      builder: (context, snapshot) {
        final hasJoined = snapshot.data ?? false;

        return GestureDetector(
          onTap: _navigateToDetails,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: categoryColor.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image with overlay
                Stack(
                  children: [
                    // Event image
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      child: Hero(
                        tag: 'activity_${activity.title}',
                        child: ActivityImageWidget(
                          imageUrl: activity.imageUrl,
                          imageAssetPath: activity.imageAssetPath,
                          width: double.infinity,
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    // Gradient overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.6),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Category badge
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              categoryColor,
                              categoryColor.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: categoryColor.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          activity.category,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),

                    // Status badges (Past/Full)
                    if (isPast || isFull)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isPast ? Colors.grey : Colors.red,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isPast ? 'Terminé' : 'Complet',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),

                    // Price badge
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: activity.isFree
                              ? Colors.green.shade600
                              : Colors.orange.shade600,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          activity.isFree
                              ? 'Gratuit'
                              : '${activity.cost?.toStringAsFixed(2)}€',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),

                    // Joined indicator
                    if (hasJoined)
                      Positioned(
                        bottom: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check, color: Colors.white, size: 16),
                              SizedBox(width: 4),
                              Text(
                                'Inscrit',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        activity.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 8),

                      // Date & Time row
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: categoryColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${activity.dateTime.day}/${activity.dateTime.month}/${activity.dateTime.year}',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: categoryColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${activity.dateTime.hour.toString().padLeft(2, '0')}:${activity.dateTime.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Location row
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: categoryColor,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              activity.location,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Participants & Actions row
                      Row(
                        children: [
                          // Participants counter
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: categoryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.people,
                                  size: 18,
                                  color: categoryColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${activity.currentParticipants}/${activity.maxParticipants}',
                                  style: TextStyle(
                                    color: categoryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Spacer(),

                          // Info button
                          _ActionButton(
                            icon: Icons.info_outline,
                            color: categoryColor,
                            onTap: _navigateToDetails,
                            tooltip: 'Détails',
                          ),

                          const SizedBox(width: 8),

                          // Favorite button
                          if (widget.onFavoriteToggle != null)
                            _ActionButton(
                              icon: Icons.favorite_border,
                              color: Colors.pink,
                              onTap: widget.onFavoriteToggle!,
                              tooltip: 'Favoris',
                            ),

                          const SizedBox(width: 8),

                          // Join/Leave/Chat button
                          if (!isPast)
                            _isLoading
                                ? const SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : hasJoined
                                    ? Row(
                                        children: [
                                          if (widget.onChatOpen != null)
                                            _ActionButton(
                                              icon: Icons.chat_bubble_outline,
                                              color: AppColors.secondary,
                                              onTap: widget.onChatOpen!,
                                              tooltip: 'Chat',
                                            ),
                                          const SizedBox(width: 8),
                                          _ActionButton(
                                            icon: Icons.exit_to_app,
                                            color: Colors.orange,
                                            onTap: _leaveEvent,
                                            tooltip: 'Quitter',
                                          ),
                                        ],
                                      )
                                    : ElevatedButton.icon(
                                        onPressed: isFull ? null : _joinEvent,
                                        icon: Icon(
                                          isFull
                                              ? Icons.block
                                              : Icons.add_circle_outline,
                                          size: 18,
                                        ),
                                        label: Text(
                                          isFull ? 'Complet' : 'Rejoindre',
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isFull
                                              ? Colors.grey
                                              : categoryColor,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
              .animate(delay: (widget.index * 100).ms)
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.1, end: 0, duration: 400.ms),
        );
      },
    );
  }
}

/// Small action button for card actions
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            child: Icon(icon, color: color, size: 20),
          ),
        ),
      ),
    );
  }
}
