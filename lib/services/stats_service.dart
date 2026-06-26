import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Fetches aggregate stats displayed on the admin dashboard.
class StatsService {
  static final _firestore = FirebaseFirestore.instance;

  static Future<int> getTotalGowns() async {
    try {
      final snapshot = await _firestore.collection('gowns').count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('[StatsService.getTotalGowns] $e');
      return 0;
    }
  }

  static Future<int> getTotalCustomers() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'client')
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('[StatsService.getTotalCustomers] $e');
      return 0;
    }
  }

  static Future<int> getTotalOverdue() async {
    try {
      final snapshot = await _firestore
          .collection('gowns')
          .where('status', isEqualTo: 'overdue')
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('[StatsService.getTotalOverdue] $e');
      return 0;
    }
  }

  /// Fetches all stats concurrently.
  static Future<Map<String, int>> getAllStats() async {
    final results = await Future.wait([
      getTotalGowns(),
      getTotalCustomers(),
      getTotalOverdue(),
    ]);

    return {
      'totalGowns': results[0],
      'totalCustomers': results[1],
      'totalOverdue': results[2],
    };
  }

  // ── Real-time streams ──────────────────────────────────────────────────────

  /// Live stream of total gown count.
  static Stream<int> totalGownsStream() {
    return _firestore
        .collection('gowns')
        .snapshots()
        .map((s) => s.docs.length);
  }

  /// Live stream of ongoing transaction count.
  /// Shows only gowns physically rented out (picked up by customer).
  static Stream<int> totalCustomersStream() {
    return _firestore
        .collection('rentals')
        .where('status', isEqualTo: 'picked_up')
        .snapshots()
        .map((s) => s.docs.length);
  }

  /// Live stream of overdue count across rentals, cleaning, and repair.
  /// A gown is overdue when:
  /// - Status 'rented' or rental status 'picked_up' with returnDate < now
  /// - Status 'cleaning' with cleaningExpectedDate < now
  /// - Status 'repair' with repairExpectedDate < now
  static Stream<int> totalOverdueStream() {
    return _firestore.collection('gowns').snapshots().map((snapshot) {
      final now = DateTime.now();
      int count = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String? ?? '';

        if (status == 'rented') {
          final returnDate =
              (data['rentalReturnDate'] as Timestamp?)?.toDate();
          if (returnDate != null) {
            final returnDay = DateTime(returnDate.year, returnDate.month, returnDate.day);
            final today = DateTime(now.year, now.month, now.day);
            if (today.isAfter(returnDay)) count++;
          }
        } else if (status == 'cleaning') {
          final expected =
              (data['cleaningExpectedDate'] as Timestamp?)?.toDate();
          if (expected != null && expected.isBefore(now)) count++;
        } else if (status == 'repair') {
          final expected =
              (data['repairExpectedDate'] as Timestamp?)?.toDate();
          if (expected != null && expected.isBefore(now)) count++;
        }
      }
      return count;
    });
  }
}
