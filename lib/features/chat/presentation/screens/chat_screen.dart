import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/services/activity_service.dart';
import 'package:mobile/core/providers/firebase_providers.dart';
import 'package:mobile/core/models/activity_model.dart';
import '../../../activities/presentation/screens/home_screen.dart';
import '../../../map/presentation/screens/map_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String? activityId; // Pour accéder directement à un chat

  const ChatScreen({
    super.key,
    this.activityId,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final int _selectedIndex = 2;

  @override
  void initState() {
    super.initState();
    // Si un activityId est fourni, naviguer directement au chat
    if (widget.activityId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConversationScreen(
              activityId: widget.activityId!,
            ),
          ),
        );
      });
    }
  }

  // Convertir emoji en IconData
  IconData _getIconFromEmoji(String emoji) {
    switch (emoji) {
      case '⚽':
        return Icons.sports_soccer;
      case '🎮':
        return Icons.sports_esports;
      case '🏃':
        return Icons.hiking;
      case '🧘':
        return Icons.self_improvement;
      case '🎨':
        return Icons.palette;
      case '🍕':
        return Icons.restaurant;
      case '🎵':
        return Icons.music_note;
      case '📚':
        return Icons.book;
      default:
        return Icons.groups;
    }
  }

  // Récupérer l'icône pour une catégorie
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'sport':
        return Icons.sports_soccer;
      case 'gaming':
        return Icons.sports_esports;
      case 'fitness':
        return Icons.fitness_center;
      case 'music':
        return Icons.music_note;
      case 'food':
        return Icons.restaurant;
      case 'outdoor':
        return Icons.nature;
      case 'culture':
        return Icons.museum;
      case 'education':
        return Icons.school;
      default:
        return Icons.event;
    }
  }

  /// Leave a conversation for an ended event (hides it only for current user)
  Future<void> _leaveConversation(ActivityModel activity) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la conversation'),
        content: Text(
          'Voulez-vous supprimer la conversation "${activity.title}" de votre liste de messages ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        final user = ref.read(currentUserProvider);
        if (user == null) return;
        
        final firestore = ref.read(firestoreProvider);
        
        // Add the activity ID to the user's hiddenConversations list
        await firestore.collection('users').doc(user.uid).update({
          'hiddenConversations': FieldValue.arrayUnion([activity.id]),
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Conversation supprimée'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final joinedActivitiesAsync = ref.watch(userJoinedActivitiesProvider);
    
    return joinedActivitiesAsync.when(
      loading: () => Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF7C4DFF), Color(0xFF6A3DE8), Color(0xFF00BCD4)],
            ),
          ),
          child: const Center(child: CircularProgressIndicator(color: Colors.white)),
        ),
      ),
      error: (error, stack) => Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF7C4DFF), Color(0xFF6A3DE8), Color(0xFF00BCD4)],
            ),
          ),
          child: Center(
            child: Text('Erreur: $error', style: const TextStyle(color: Colors.white)),
          ),
        ),
      ),
      data: (joinedActivities) {
        // Get hidden conversations from user profile
        final userProfileAsync = ref.watch(currentUserProfileProvider);
        final hiddenConversations = userProfileAsync.when(
          data: (profile) => profile?.hiddenConversations ?? [],
          loading: () => <String>[],
          error: (_, __) => <String>[],
        );
        
        // Filter out hidden conversations
        final visibleActivities = joinedActivities
            .where((activity) => !hiddenConversations.contains(activity.id))
            .toList();
        
        // Sort: upcoming events first, then ended events
        visibleActivities.sort((a, b) {
          // Upcoming events (not past) come first
          if (!a.isPast && b.isPast) return -1;
          if (a.isPast && !b.isPast) return 1;
          // Within same category, sort by date (newest first for upcoming, oldest first for past)
          if (!a.isPast && !b.isPast) {
            return a.dateTime.compareTo(b.dateTime); // Upcoming: soonest first
          }
          return b.dateTime.compareTo(a.dateTime); // Past: most recent first
        });
        
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.white.withOpacity(0.1),
            elevation: 0,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const HomeScreen(),
                  ),
                );
              },
            ),
            title: const Text(
              'Messages',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            centerTitle: true,
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF7C4DFF), Color(0xFF6A3DE8), Color(0xFF00BCD4)],
              ),
            ),
            child: Stack(
              children: [
                // Decorative background blobs
                Positioned(
                  top: 40,
                  right: 40,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 80,
                  left: -40,
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00BCD4).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                // Content
                SafeArea(
                  child: visibleActivities.isEmpty
                      ? _buildEmptyState()
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: ListView.builder(
                            padding: const EdgeInsets.only(top: 16, bottom: 16),
                            itemCount: visibleActivities.length,
                            itemBuilder: (context, index) {
                              final activity = visibleActivities[index];
                              return _buildConversationCard(activity, index);
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: Colors.grey,
            onTap: (index) {
              if (index != _selectedIndex) {
                Widget screen;
                switch (index) {
                  case 0:
                    screen = const HomeScreen();
                    break;
                  case 1:
                    screen = const MapScreen();
                    break;
                  case 2:
                    return;
                  case 3:
                    screen = const ProfileScreen();
                    break;
                  default:
                    return;
                }
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => screen),
                );
              }
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Accueil',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.map),
                label: 'Carte',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat),
                label: 'Messages',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profil',
              ),
            ],
          ),
        );
      },
    );
  }

  // Build modern conversation card matching reference UI
  Widget _buildConversationCard(ActivityModel activity, int index) {
    final unreadCount = 0; // TODO: Integrate with real unread message count
    final isEnded = activity.isPast; // Check if event has ended
    
    Widget card = AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isEnded ? Colors.grey.shade100.withOpacity(0.9) : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ConversationScreen(
                  activityId: activity.id,
                ),
              ),
            );
          },
          onLongPress: isEnded ? () => _leaveConversation(activity) : null,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isEnded ? Colors.grey.shade300 : Colors.white.withOpacity(0.5),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Event photo with badge
                Stack(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: isEnded 
                                ? Colors.grey.withOpacity(0.2)
                                : AppColors.primary.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: ColorFiltered(
                          colorFilter: isEnded 
                              ? ColorFilter.mode(Colors.grey.shade400, BlendMode.saturation)
                              : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                          child: activity.imageUrl != null && activity.imageUrl!.isNotEmpty
                              ? Image.network(
                                  activity.imageUrl!,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          const Color(0xFFE1BEE7),
                                          const Color(0xFFCE93D8),
                                        ],
                                      ),
                                    ),
                                    child: Icon(
                                      _getCategoryIcon(activity.category),
                                      color: const Color(0xFF7C4DFF),
                                      size: 24,
                                    ),
                                  );
                                },
                              )
                            : activity.imageAssetPath != null
                                ? Image.asset(
                                    activity.imageAssetPath!,
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              const Color(0xFFE1BEE7),
                                              const Color(0xFFCE93D8),
                                            ],
                                          ),
                                        ),
                                        child: Icon(
                                          _getCategoryIcon(activity.category),
                                          color: const Color(0xFF7C4DFF),
                                          size: 24,
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          const Color(0xFFE1BEE7),
                                          const Color(0xFFCE93D8),
                                        ],
                                      ),
                                    ),
                                    child: Icon(
                                      _getCategoryIcon(activity.category),
                                      color: const Color(0xFF7C4DFF),
                                      size: 24,
                                    ),
                                  ),
                        ),
                      ),
                    ),
                    // Badge for ended events
                    if (isEnded)
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade600,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.lock,
                            color: Colors.white,
                            size: 10,
                          ),
                        ),
                      ),
                    if (unreadCount > 0)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7C4DFF), Color(0xFF00BCD4)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF7C4DFF).withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                          child: Center(
                            child: Text(
                              unreadCount > 99 ? '99+' : unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              activity.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: unreadCount > 0 ? FontWeight.w700 : FontWeight.w600,
                                color: unreadCount > 0 ? Colors.grey[900] : Colors.grey[700],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _getRelativeTime(activity.dateTime),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                              color: unreadCount > 0 ? const Color(0xFF7C4DFF) : Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isEnded 
                            ? '🔒 Événement terminé - Appui long pour supprimer'
                            : 'Appuyez pour ouvrir le chat',
                        style: TextStyle(
                          fontSize: 14,
                          color: isEnded 
                              ? Colors.grey.shade600
                              : (unreadCount > 0 ? const Color(0xFF7C4DFF) : Colors.grey[500]),
                          fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Delete button for ended events or chevron
                if (isEnded)
                  IconButton(
                    onPressed: () => _leaveConversation(activity),
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.red.shade400,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                    ),
                    tooltip: 'Supprimer la conversation',
                  )
                else
                  Icon(
                    Icons.chevron_right,
                    color: unreadCount > 0 ? const Color(0xFF7C4DFF) : Colors.grey[400],
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    
    // Wrap with Dismissible for swipe-to-delete on ended events
    if (isEnded) {
      return Dismissible(
        key: Key('conversation_${activity.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.red.shade400,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: const Icon(
            Icons.delete,
            color: Colors.white,
            size: 28,
          ),
        ),
        confirmDismiss: (direction) async {
          return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Supprimer la conversation'),
              content: Text(
                'Voulez-vous supprimer la conversation "${activity.title}" de votre liste de messages ?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Annuler'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Supprimer'),
                ),
              ],
            ),
          );
        },
        onDismissed: (direction) async {
          try {
            final user = ref.read(currentUserProvider);
            if (user == null) return;
            
            final firestore = ref.read(firestoreProvider);
            
            // Add the activity ID to the user's hiddenConversations list
            await firestore.collection('users').doc(user.uid).update({
              'hiddenConversations': FieldValue.arrayUnion([activity.id]),
            });
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Conversation masquée'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          } catch (e) {
            // Error handling
          }
        },
        child: card,
      );
    }
    
    return card;
  }

  // Get relative time string
  String _getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays == 0) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      final weekdays = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
      return weekdays[dateTime.weekday - 1];
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }

  // État vide quand aucune activité rejointe
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 100,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 20),
          Text(
            'Aucune conversation',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Rejoignez une activité pour\ncommencer à discuter',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            },
            icon: const Icon(Icons.explore),
            label: const Text('Explorer les activités'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
          ),
        ],
      ),
    );
  }
}

class ConversationScreen extends ConsumerStatefulWidget {
  final String activityId;

  const ConversationScreen({
    super.key,
    required this.activityId,
  });

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    try {
      final chatAsync = ref.read(chatByActivityProvider(widget.activityId));
      
      await chatAsync.when(
        data: (chatData) async {
          if (chatData == null) {
            throw Exception('Chat non trouvé');
          }
          
          final chatService = ref.read(chatServiceProvider);
          await chatService.sendMessage(
            chatId: chatData['id'] as String,
            text: text,
          );
          
          _messageController.clear();
          
          // Scroll to bottom après l'envoi
          Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
        },
        loading: () => throw Exception('Chargement en cours'),
        error: (error, _) => throw error,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur envoi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatAsync = ref.watch(chatByActivityProvider(widget.activityId));
    final currentUser = ref.watch(currentUserProvider);
    final activityAsync = ref.watch(activityStreamProvider(widget.activityId));

    return Scaffold(
      appBar: AppBar(
        title: chatAsync.when(
          data: (chatData) => Text(chatData?['activityTitle'] ?? 'Chat'),
          loading: () => const Text('Chargement...'),
          error: (_, __) => const Text('Erreur'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {},
          ),
        ],
      ),
      body: chatAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 64, color: Colors.orange),
                const SizedBox(height: 24),
                const Text(
                  'Configuration Firebase requise',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  error.toString().contains('permission')
                      ? 'Les Security Rules Firebase ne sont pas configurées.\n\nConsultez le fichier FIREBASE_CHAT_RULES.md pour les instructions.'
                      : 'Erreur: $error',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Retour'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
        data: (chatData) {
          if (chatData == null) {
            // Le chat n'existe pas, proposer de le créer
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'Chat non disponible',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Le chat n\'a pas été créé pour cette activité',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () async {
                        // Essayer de créer le chat
                        try {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );

                          // Récupérer les infos de l'activité
                          final activityDoc = await ref.read(firestoreProvider)
                              .collection('activities')
                              .doc(widget.activityId)
                              .get();
                          
                          if (!activityDoc.exists) {
                            throw Exception('Activité introuvable');
                          }

                          final activityData = activityDoc.data()!;
                          final chatService = ref.read(chatServiceProvider);
                          
                          await chatService.createChatForActivity(
                            activityId: widget.activityId,
                            activityTitle: activityData['title'] ?? 'Activité',
                            creatorId: currentUser!.uid,
                            creatorName: currentUser.displayName ?? currentUser.email ?? 'Utilisateur',
                          );

                          if (mounted) Navigator.pop(context); // Fermer le loading
                          
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ Chat créé avec succès !'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) Navigator.pop(context); // Fermer le loading
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('❌ Erreur: ${e.toString()}'),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 5),
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Créer le chat'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Retour'),
                    ),
                  ],
                ),
              ),
            );
          }

          final chatId = chatData['id'] as String;
          final messagesAsync = ref.watch(chatMessagesProvider(chatId));

          return Column(
            children: [
              Expanded(
                child: messagesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: Text('Erreur messages: $error'),
                  ),
                  data: (messages) {
                    if (messages.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'Aucun message',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Soyez le premier à envoyer un message !',
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }

                    // Scroll automatiquement au dernier message
                    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isMe = message['senderId'] == currentUser?.uid;
                        final isSystem = message['type'] == 'system';
                        
                        if (isSystem) {
                          return _buildSystemMessage(message);
                        }
                        
                        return _buildMessage(message, isMe);
                      },
                    );
                  },
                ),
              ),
              activityAsync.when(
                data: (activityData) {
                  if (activityData == null) return _buildMessageInput(isPast: false);
                  final activity = ActivityModel.fromFirestore(activityData, activityData['id'] as String);
                  return _buildMessageInput(isPast: activity.isPast);
                },
                loading: () => _buildMessageInput(isPast: false),
                error: (_, __) => _buildMessageInput(isPast: false),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSystemMessage(Map<String, dynamic> message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message['text'] ?? '',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildMessage(Map<String, dynamic> message, bool isMe) {
    final timestamp = message['timestamp'] as Timestamp?;
    final time = timestamp != null
        ? '${timestamp.toDate().hour.toString().padLeft(2, '0')}:${timestamp.toDate().minute.toString().padLeft(2, '0')}'
        : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundImage: message['senderPhotoUrl'] != null
                  ? (message['senderPhotoUrl'].toString().startsWith('assets/')
                      ? AssetImage(message['senderPhotoUrl'])
                      : NetworkImage(message['senderPhotoUrl'])) as ImageProvider
                  : null,
              backgroundColor: AppColors.secondary.withOpacity(0.3),
              child: message['senderPhotoUrl'] == null
                  ? Text(
                      (message['senderName'] ?? 'U')[0].toUpperCase(),
                      style: TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 4),
                    child: Text(
                      message['senderName'] ?? 'Utilisateur',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isMe ? AppColors.primary : Colors.grey[200],
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                  ),
                  child: Text(
                    message['text'] ?? '',
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (time.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                    child: Text(
                      time,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput({bool isPast = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPast ? Colors.grey.shade100 : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: isPast
          ? Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 18,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Chat fermé - Événement terminé',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Écrivez un message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
    );
  }
}
