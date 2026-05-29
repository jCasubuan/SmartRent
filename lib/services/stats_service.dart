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

  /// Live stream of total customer (role == 'client') count.
  /// Shows ongoing transactions — rentals with status 'approved' (currently rented out).
  static Stream<int> totalCustomersStream() {
    return _firestore
        .collection('rentals')
        .where('status', isEqualTo: 'approved')
        .snapshots()
        .map((s) => s.docs.length);
  }

  /// Live stream of overdue gown count.
  static Stream<int> totalOverdueStream() {
    return _firestore
        .collection('gowns')
        .where('status', isEqualTo: 'overdue')
        .snapshots()
        .map((s) => s.docs.length);
  }
}
