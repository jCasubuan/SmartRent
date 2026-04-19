import 'package:cloud_firestore/cloud_firestore.dart';

// this class is to fetch all the data from database
// and will display in the admin dashboard
class StatsService {
  static final _firestore = FirebaseFirestore.instance;

  static Future<int> getTotalGowns() async {
    try {
      final snapshot = await _firestore.collection('gowns').count().get();
      return snapshot.count ?? 0;
    } catch (_) {
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
    } catch (_) {
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
    } catch (_) {
      return 0;
    }
  }

  // Fetch all stats at once
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
}