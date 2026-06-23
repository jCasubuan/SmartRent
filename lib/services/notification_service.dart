import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// In-app notification service backed by Firestore.
///
/// Each notification is stored in `users/{userId}/notifications/{notifId}`.
/// Documents are written by admin actions (approve / reject / complete) and
/// read in real-time by the client's NotificationsTab.
///
/// Schema:
///   title       String  — short heading
///   body        String  — detail message
///   type        String  — 'approved' | 'rejected' | 'completed'
///   rentalId    String  — links back to the rental document
///   gownName    String  — for display without a second Firestore read
///   isRead      bool    — false until the customer opens the notification
///   createdAt   Timestamp
class NotificationService {
  static final _users = FirebaseFirestore.instance.collection('users');

  // ── Write ──────────────────────────────────────────────────────────────────

  /// Creates a notification document inside the customer's subcollection.
  static Future<bool> sendNotification({
    required String customerId,
    required String title,
    required String body,
    required String type,
    required String rentalId,
    required String gownName,
  }) async {
    try {
      await _users
          .doc(customerId)
          .collection('notifications')
          .add({
        'title': title,
        'body': body,
        'type': type,
        'rentalId': rentalId,
        'gownName': gownName,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('[NotificationService.sendNotification] $e');
      return false;
    }
  }

  // ── Read ───────────────────────────────────────────────────────────────────

  /// Real-time stream of all notifications for a customer, newest first.
  static Stream<List<Map<String, dynamic>>> notificationsStream(
      String customerId) {
    return _users
        .doc(customerId)
        .collection('notifications')
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();

          // Sort client-side: newest first. Handles null createdAt gracefully
          // (new docs have a server timestamp that arrives slightly after write).
          docs.sort((a, b) {
            final aTs = a['createdAt'];
            final bTs = b['createdAt'];
            if (aTs == null && bTs == null) return 0;
            if (aTs == null) return 1;
            if (bTs == null) return -1;
            final aDate = (aTs as Timestamp).toDate();
            final bDate = (bTs as Timestamp).toDate();
            return bDate.compareTo(aDate);
          });

          return docs;
        });
  }

  /// Real-time count of unread notifications — used for the nav badge.
  static Stream<int> unreadCountStream(String customerId) {
    return _users
        .doc(customerId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // ── Mark read ──────────────────────────────────────────────────────────────

  /// Marks a single notification as read.
  static Future<void> markRead(String customerId, String notifId) async {
    try {
      await _users
          .doc(customerId)
          .collection('notifications')
          .doc(notifId)
          .update({'isRead': true});
    } catch (e) {
      debugPrint('[NotificationService.markRead] $e');
    }
  }

  /// Marks all notifications for a customer as read in a single batch.
  static Future<void> markAllRead(String customerId) async {
    try {
      final snapshot = await _users
          .doc(customerId)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      if (snapshot.docs.isEmpty) return;

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('[NotificationService.markAllRead] $e');
    }
  }

  // ── Delete ─────────────────────────────────────────────────────────────────

  /// Deletes a single notification document.
  static Future<bool> deleteNotification(
      String customerId, String notifId) async {
    try {
      await _users
          .doc(customerId)
          .collection('notifications')
          .doc(notifId)
          .delete();
      return true;
    } catch (e) {
      debugPrint('[NotificationService.deleteNotification] $e');
      return false;
    }
  }

  // ── Overdue reminder ───────────────────────────────────────────────────────

  /// Sends an overdue reminder notification if one hasn't already been sent
  /// for this rental. Uses rentalId + type='overdue' to deduplicate.
  static Future<void> sendOverdueReminderIfNeeded({
    required String customerId,
    required String rentalId,
    required String gownName,
    required DateTime returnDate,
  }) async {
    try {
      // Check if already sent
      final existing = await _users
          .doc(customerId)
          .collection('notifications')
          .where('rentalId', isEqualTo: rentalId)
          .where('type', isEqualTo: 'overdue')
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) return; // Already notified

      final overdueDays = DateTime.now().difference(returnDate).inDays;
      final dayText = overdueDays == 0
          ? 'today'
          : '$overdueDays day${overdueDays > 1 ? 's' : ''} ago';

      await _users
          .doc(customerId)
          .collection('notifications')
          .add({
        'title': 'Gown return overdue ⚠️',
        'body': 'Your rental of "$gownName" was due $dayText. '
            'Please return it to the shop as soon as possible to avoid additional charges (₱500/day).',
        'type': 'overdue',
        'rentalId': rentalId,
        'gownName': gownName,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[NotificationService.sendOverdueReminderIfNeeded] $e');
    }
  }
}
