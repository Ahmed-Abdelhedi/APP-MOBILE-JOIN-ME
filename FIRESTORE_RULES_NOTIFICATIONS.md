# Firestore Rules for Notifications

## Required Firestore Security Rules

Add these rules to your Firebase Console → Firestore Database → Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Activities collection
    match /activities/{activityId} {
      allow read: if true; // Everyone can read activities
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
                              (request.auth.uid == resource.data.creatorId);
    }
    
    // Users collection
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
      
      // Notifications subcollection
      match /notifications/{notificationId} {
        // Users can read their own notifications
        allow read: if request.auth != null && request.auth.uid == userId;
        
        // Users can write to their own notifications
        allow write: if request.auth != null && request.auth.uid == userId;
        
        // System (event creators) can create notifications for other users
        allow create: if request.auth != null;
        
        // Users can delete their own notifications
        allow delete: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    // Chats collection
    match /chats/{chatId} {
      allow read: if request.auth != null && 
                    request.auth.uid in resource.data.participants;
      allow create: if request.auth != null;
      allow update: if request.auth != null && 
                      request.auth.uid in resource.data.participants;
      
      // Messages subcollection
      match /messages/{messageId} {
        allow read: if request.auth != null;
        allow create: if request.auth != null;
      }
    }
  }
}
```

## How to Apply Rules

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to **Firestore Database** → **Rules**
4. Copy the rules above
5. Click **Publish**

## Notification Structure

Notifications are stored in: `users/{userId}/notifications/{notificationId}`

### Notification Document Fields:
```javascript
{
  "type": "event_cancelled" | "event_updated" | "event_reminder" | "event_joined" | "chat_message",
  "title": "Notification title",
  "body": "Notification message body",
  "activityId": "ID of related activity",
  "activityTitle": "Title of the activity",
  "read": false,
  "createdAt": Timestamp
}
```

## Notification Types

1. **event_cancelled** - When an event is cancelled by the creator
   - Icon: Cancel (red)
   - Example: "❌ Événement annulé - L'événement '[titre]' a été annulé par l'organisateur"

2. **event_updated** - When an event is modified by the creator
   - Icon: Edit (blue)
   - Example: "L'événement '[titre]' a été mis à jour par l'organisateur"

3. **event_reminder** - Reminder notification before event starts
   - Icon: Notifications Active (orange)
   - Example: "Rappel: L'événement '[titre]' commence dans 1 heure"

4. **event_joined** - When someone joins your event
   - Icon: Person Add (green)
   - Example: "[User] a rejoint votre événement '[titre]'"

5. **chat_message** - New message in event chat
   - Icon: Chat Bubble (blue)
   - Example: "Nouveau message dans '[titre]'"

## Testing Notifications

### Test Event Cancellation:
1. Create an event as User A
2. Have User B join the event
3. As User A, cancel the event
4. User B should receive a notification

### Test Event Updates:
1. Create an event as User A
2. Have User B join the event
3. As User A, click "Modifier" and change event details
4. User B should receive a notification

### Check Notifications:
- Click the bell icon (🔔) in the top right of the home screen
- Notifications appear with color-coded icons
- Swipe left to delete a notification
- Tap to mark as read
