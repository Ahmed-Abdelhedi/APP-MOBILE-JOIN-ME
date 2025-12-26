import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile/core/providers/firebase_providers.dart';
import 'package:mobile/core/models/activity_model.dart';
import 'package:intl/intl.dart';

class MyActivitiesScreen extends ConsumerStatefulWidget {
  const MyActivitiesScreen({super.key});

  @override
  ConsumerState<MyActivitiesScreen> createState() => _MyActivitiesScreenState();
}

class _MyActivitiesScreenState extends ConsumerState<MyActivitiesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Activités'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Participations', icon: Icon(Icons.group_add)),
            Tab(text: 'Organisées', icon: Icon(Icons.event)),
            Tab(text: 'Passées', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildParticipatingList(),
          _buildHostedList(),
          _buildPastList(),
        ],
      ),
    );
  }

  Widget _buildParticipatingList() {
    final joinedActivitiesAsync = ref.watch(userJoinedActivitiesProvider);

    return joinedActivitiesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Erreur: $error'),
          ],
        ),
      ),
      data: (activities) {
        // Filtrer les activités futures
        final futureActivities = activities
            .where((a) => a.dateTime.isAfter(DateTime.now()))
            .toList();

        if (futureActivities.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Aucune participation',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: futureActivities.length,
          itemBuilder: (context, index) {
            final activity = futureActivities[index];
            return _buildActivityCard(activity, showStatus: true)
                .animate(delay: (100 * index).ms)
                .fadeIn()
                .slideX(begin: -0.2, end: 0);
          },
        );
      },
    );
  }

  Widget _buildHostedList() {
    final hostedActivitiesAsync = ref.watch(userCreatedActivitiesProvider);

    return hostedActivitiesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Erreur: $error'),
          ],
        ),
      ),
      data: (activities) {
        // Filtrer les activités futures
        final futureActivities = activities
            .where((a) => a.dateTime.isAfter(DateTime.now()))
            .toList();

        if (futureActivities.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Aucune activité organisée',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: futureActivities.length,
          itemBuilder: (context, index) {
            final activity = futureActivities[index];
            return _buildActivityCard(activity, isHosted: true)
                .animate(delay: (100 * index).ms)
                .fadeIn()
                .slideX(begin: -0.2, end: 0);
          },
        );
      },
    );
  }

  Widget _buildPastList() {
    final allActivitiesAsync = ref.watch(userCreatedActivitiesProvider);
    final joinedActivitiesAsync = ref.watch(userJoinedActivitiesProvider);

    return allActivitiesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Erreur: $error')),
      data: (createdActivities) {
        return joinedActivitiesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Erreur: $error')),
          data: (joinedActivities) {
            // Combiner les activités créées et celles auxquelles on a participé
            final allActivities = {...createdActivities, ...joinedActivities}.toList();
            
            // Filtrer les activités passées
            final pastActivities = allActivities
                .where((a) => a.dateTime.isBefore(DateTime.now()))
                .toList()
              ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

            if (pastActivities.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Aucune activité passée',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: pastActivities.length,
              itemBuilder: (context, index) {
                final activity = pastActivities[index];
                return _buildActivityCard(activity, isPast: true)
                    .animate(delay: (100 * index).ms)
                    .fadeIn()
                    .slideX(begin: -0.2, end: 0);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildActivityCard(
    ActivityModel activity, {
    bool showStatus = false,
    bool isHosted = false,
    bool isPast = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: activity.imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: activity.imageUrl!,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 150,
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 150,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported, size: 50),
                    ),
                  )
                : Container(
                    height: 150,
                    color: AppColors.primary.withOpacity(0.2),
                    child: Center(
                      child: Icon(
                        Icons.event,
                        size: 50,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        activity.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (showStatus)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Confirmé',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                
                Row(
                  children: [
                    Icon(Icons.category, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      activity.category,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('dd MMM yyyy', 'fr_FR').format(activity.dateTime),
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('HH:mm').format(activity.dateTime),
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        activity.location,
                        style: TextStyle(color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                if (isHosted) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.people, size: 20, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        '${activity.participants.length}/${activity.maxParticipants} participants',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
