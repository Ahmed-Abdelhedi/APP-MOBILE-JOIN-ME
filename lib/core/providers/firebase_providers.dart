import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile/core/services/chat_service.dart';
import 'package:mobile/core/services/auth_service.dart';
import 'package:mobile/core/services/user_service.dart';
import 'package:mobile/core/models/activity_model.dart';
import 'package:mobile/core/models/user_model.dart';

// ============================================================================
// PROVIDERS FIREBASE - FRONTEND UNIQUEMENT
// ============================================================================
// Ces providers connectent le frontend à votre backend Firebase existant
// Votre backend gère la logique, le frontend utilise juste les données

/// Provider Firebase Auth instance
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Provider Firebase Firestore instance  
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// Provider de l'état d'authentification (Stream)
final authStateProvider = StreamProvider<User?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return auth.authStateChanges();
});

/// Provider de l'utilisateur actuel
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user,
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Provider pour vérifier si l'utilisateur est connecté
final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});

// ============================================================================
// PROVIDERS POUR LES COLLECTIONS FIRESTORE
// ============================================================================

/// Stream des activités (votre backend gère les règles et la structure)
final activitiesStreamProvider = StreamProvider.autoDispose<List<ActivityModel>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('activities')
      .where('status', isEqualTo: 'upcoming')
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) {
            final data = doc.data();
            return ActivityModel.fromFirestore(data, doc.id);
          })
          .toList());
});

/// Stream d'une activité spécifique
final activityStreamProvider = StreamProvider.autoDispose
    .family<Map<String, dynamic>?, String>((ref, activityId) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('activities')
      .doc(activityId)
      .snapshots()
      .map((doc) => doc.exists ? {...doc.data()!, 'id': doc.id} : null);
});

/// Stream des chats de l'utilisateur
final userChatsStreamProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('chats')
      .where('participants', arrayContains: user.uid)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => {...doc.data(), 'id': doc.id})
          .toList());
});

/// Stream des messages d'un chat
final chatMessagesStreamProvider = StreamProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, chatId) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('chats')
      .doc(chatId)
      .collection('messages')
      .orderBy('timestamp', descending: true)
      .limit(50)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => {...doc.data(), 'id': doc.id})
          .toList());
});

// ============================================================================
// PROVIDERS SERVICES
// ============================================================================

/// Provider pour AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Provider pour ChatService (sans Cloud Functions, version gratuite Firebase)
final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService();
});

/// Provider pour UserService
final userServiceProvider = Provider((ref) {
  return UserService();
});

// ============================================================================
// PROVIDERS UTILISATEUR
// ============================================================================

/// Stream du profil de l'utilisateur connecté
final currentUserProfileProvider = StreamProvider<UserModel?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);

  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((doc) {
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc.data()!, doc.id);
  });
});

/// Stream du profil d'un utilisateur spécifique par ID
final userProfileProvider = StreamProvider.autoDispose
    .family<UserModel?, String>((ref, userId) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('users')
      .doc(userId)
      .snapshots()
      .map((doc) {
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc.data()!, doc.id);
  });
});

/// Stream des activités créées par l'utilisateur
final userCreatedActivitiesProvider = StreamProvider<List<ActivityModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('activities')
      .where('creatorId', isEqualTo: user.uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => ActivityModel.fromFirestore(doc.data(), doc.id))
          .toList())
      .handleError((error) {
        print('❌ Erreur chargement activités créées: $error');
        return <ActivityModel>[];
      });
});

/// Stream des activités auxquelles l'utilisateur participe
final userJoinedActivitiesProvider = StreamProvider<List<ActivityModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('activities')
      .where('participants', arrayContains: user.uid)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => ActivityModel.fromFirestore(doc.data(), doc.id))
          .toList())
      .handleError((error) {
        print('❌ Erreur chargement activités participées: $error');
        return <ActivityModel>[];
      });
});

/// Stream des activités favorites de l'utilisateur
final userFavoriteActivitiesProvider = StreamProvider<List<ActivityModel>>((ref) {
  final userProfile = ref.watch(currentUserProfileProvider);
  
  return userProfile.when(
    data: (profile) {
      if (profile == null || profile.favorites.isEmpty) {
        return Stream.value([]);
      }

      final firestore = ref.watch(firestoreProvider);
      
      // Firestore whereIn limite à 10 éléments, on prend les 10 premiers favoris
      final favoritesToQuery = profile.favorites.take(10).toList();
      
      return firestore
          .collection('activities')
          .where(FieldPath.documentId, whereIn: favoritesToQuery)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => ActivityModel.fromFirestore(doc.data(), doc.id))
              .toList())
          .handleError((error) {
            print('❌ Erreur chargement favoris: $error');
            return <ActivityModel>[];
          });
    },
    loading: () => Stream.value([]),
    error: (error, _) {
      print('❌ Erreur profil utilisateur: $error');
      return Stream.value([]);
    },
  );
});

// ============================================================================
// PROVIDERS CHAT
// ============================================================================

/// Stream des messages d'un chat
final chatMessagesProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, chatId) {
  final firestore = ref.watch(firestoreProvider);
  
  return firestore
      .collection('chats')
      .doc(chatId)
      .collection('messages')
      .orderBy('timestamp', descending: false)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      return {...doc.data(), 'id': doc.id};
    }).toList();
  }).handleError((error) {
    print('❌ Erreur chargement messages: $error');
    return <Map<String, dynamic>>[];
  });
});

/// Stream d'un chat spécifique par activityId
final chatByActivityProvider = StreamProvider.family<Map<String, dynamic>?, String>((ref, activityId) {
  print('🔍 Recherche chat pour activité: $activityId');
  final firestore = ref.watch(firestoreProvider);
  
  return firestore
      .collection('chats')
      .where('activityId', isEqualTo: activityId)
      .limit(1)
      .snapshots()
      .map((snapshot) {
    print('📊 Résultat query chats: ${snapshot.docs.length} document(s) trouvé(s)');
    if (snapshot.docs.isEmpty) {
      print('⚠️ Aucun chat trouvé pour activityId: $activityId');
      return null;
    }
    final doc = snapshot.docs.first;
    final chatData = {...doc.data(), 'id': doc.id};
    print('✅ Chat trouvé: ${doc.id} pour activité: $activityId');
    return chatData;
  }).handleError((error) {
    print('❌ Erreur chargement chat: $error');
    throw error; // Propager l'erreur pour l'afficher dans l'UI
  });
});

// ============================================================================
// PROVIDERS STATISTIQUES PROFIL
// ============================================================================

/// Provider pour le nombre total d'activités de l'utilisateur (créées + participées)
final userActivitiesCountProvider = StreamProvider.autoDispose<int>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(0);

  final firestore = ref.watch(firestoreProvider);
  
  // Stream combiné: activités créées + participées
  final createdStream = firestore
      .collection('activities')
      .where('creatorId', isEqualTo: user.uid)
      .snapshots();
  
  final participatedStream = firestore
      .collection('activities')
      .where('participants', arrayContains: user.uid)
      .snapshots();
  
  return createdStream.asyncMap((createdSnapshot) async {
    final participatedSnapshot = await participatedStream.first;
    
    // Compter en évitant les doublons
    final allActivityIds = <String>{};
    
    for (var doc in createdSnapshot.docs) {
      allActivityIds.add(doc.id);
    }
    
    for (var doc in participatedSnapshot.docs) {
      allActivityIds.add(doc.id);
    }
    
    final count = allActivityIds.length;
    print('📊 Activités totales: $count (créées: ${createdSnapshot.docs.length}, participées: ${participatedSnapshot.docs.length})');
    return count;
  }).handleError((error) {
    print('❌ Erreur comptage activités: $error');
    return 0;
  });
});

/// Provider pour le nombre d'amis (utilisateurs avec qui on partage des activités)
final userFriendsCountProvider = StreamProvider.autoDispose<int>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(0);

  final firestore = ref.watch(firestoreProvider);
  
  return firestore
      .collection('activities')
      .where('participants', arrayContains: user.uid)
      .snapshots()
      .map((snapshot) {
        final Set<String> friends = {};
        for (var doc in snapshot.docs) {
          final data = doc.data();
          final participants = (data['participants'] as List?)?.cast<String>() ?? [];
          final creatorId = data['creatorId'] as String?;
          
          // Ajouter tous les participants sauf l'utilisateur lui-même
          friends.addAll(participants.where((id) => id != user.uid));
          
          // Ajouter le créateur s'il est différent
          if (creatorId != null && creatorId != user.uid) {
            friends.add(creatorId);
          }
        }
        print('👥 Amis: ${friends.length}');
        return friends.length;
      })
      .handleError((error) {
        print('❌ Erreur comptage amis: $error');
        return 0;
      });
});

/// Provider pour la note moyenne de l'utilisateur (calculée depuis les reviews)
final userAverageRatingProvider = StreamProvider.autoDispose<double>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(0.0);

  final firestore = ref.watch(firestoreProvider);
  
  // Si vous avez une collection 'reviews', utilisez-la
  // Sinon, retourner 4.8 par défaut (à implémenter avec votre système de notation)
  return firestore
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((doc) {
        if (!doc.exists) return 4.8;
        final data = doc.data();
        final rating = data?['rating'] as num?;
        final result = rating?.toDouble() ?? 4.8;
        print('⭐ Note: $result');
        return result;
      })
      .handleError((error) {
        print('❌ Erreur récupération note: $error');
        return 4.8;
      });
});
