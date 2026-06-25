import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Admin activity log service backed by Firestore.
///
/// Each log entry is stored in `admin_logs/{logId}`.
/// Written automatically when admin actions occur (approve, reject, add gown, etc.)
/// and displayed in the admin Inbox → Notifications tab.
///
/// Schema:
///   type        String  — event category (see [AdminLogType])
///   title       String  — short heading
///   body        String  — detail message
///   targetType  String? — 'gown' | 'rental' | 'cleaning' | 'repair' | 'overdue' | 'customer'
///   targetId    String? — document ID for navigation
///   isRead      bool    — false until the admin taps/marks it
///   createdAt   Timestamp
class AdminLogService {
  static final _collection =
      FirebaseFirestore.instance.collection('admin_logs');

  // ── Write ──────────────────────────────────────────────────────────────────

  /// Creates a log entry in the admin_logs collection.
  static Future<bool> log({
    required String type,
    required String title,
    required String body,
    String? targetType,
    String? targetId,
  }) async {
    try {
      await _collection.add({
        'type': type,
        'title': title,
        'body': body,
        'targetType': targetType,
        'targetId': targetId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('[AdminLogService.log] $e');
      return false;
    }
  }

  // ── Read ───────────────────────────────────────────────────────────────────

  /// Real-time stream of all admin log entries, newest first.
  /// Sorted client-side to handle null createdAt gracefully
  /// (new docs have a server timestamp that arrives slightly after write).
  static Stream<List<Map<String, dynamic>>> logsStream() {
    return _collection
        .snapshots()
        .map((snapshot) {
      final docs = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Sort client-side: newest first. Handles null createdAt gracefully.
      docs.sort((a, b) {
        final aTs = a['createdAt'];
        final bTs = b['createdAt'];
        if (aTs == null && bTs == null) return 0;
        if (aTs == null) return -1; // null = just written = newest
        if (bTs == null) return 1;
        final aDate = (aTs as Timestamp).toDate();
        final bDate = (bTs as Timestamp).toDate();
        return bDate.compareTo(aDate);
      });

      return docs;
    });
  }

  /// Real-time count of unread logs — used for badge.
  static Stream<int> unreadCountStream() {
    return _collection
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // ── Mark read ──────────────────────────────────────────────────────────────

  /// Marks a single log entry as read.
  static Future<void> markRead(String logId) async {
    try {
      await _collection.doc(logId).update({'isRead': true});
    } catch (e) {
      debugPrint('[AdminLogService.markRead] $e');
    }
  }

  /// Marks all unread logs as read in a single batch.
  static Future<void> markAllRead() async {
    try {
      final snapshot = await _collection
          .where('isRead', isEqualTo: false)
          .get();

      if (snapshot.docs.isEmpty) return;

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('[AdminLogService.markAllRead] $e');
    }
  }

  // ── Delete ─────────────────────────────────────────────────────────────────

  /// Deletes a single log entry.
  static Future<bool> deleteLog(String logId) async {
    try {
      await _collection.doc(logId).delete();
      return true;
    } catch (e) {
      debugPrint('[AdminLogService.deleteLog] $e');
      return false;
    }
  }
}

/// Event type constants for admin logs.
class AdminLogType {
  // Rental events
  static const rentalRequested = 'rental_requested';
  static const rentalApproved = 'rental_approved';
  static const rentalRejected = 'rental_rejected';
  static const rentalPickedUp = 'rental_picked_up';
  static const rentalCompleted = 'rental_completed';
  static const rentalNoShow = 'rental_no_show';
  static const rentalCancelled = 'rental_cancelled';

  // Gown events
  static const gownAdded = 'gown_added';
  static const gownEdited = 'gown_edited';
  static const gownDeleted = 'gown_deleted';

  // Cleaning / Repair
  static const gownSentCleaning = 'gown_sent_cleaning';
  static const gownMarkedClean = 'gown_marked_clean';
  static const gownSentRepair = 'gown_sent_repair';
  static const gownRepairDone = 'gown_repair_done';

  // Overdue
  static const rentalOverdue = 'rental_overdue';
  static const cleaningOverdue = 'cleaning_overdue';
  static const repairOverdue = 'repair_overdue';
}
