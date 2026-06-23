import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Calculates revenue and analytics data from completed rentals.
///
/// Revenue sources:
/// - Rental price (gownPrice) from each completed rental
/// - Late penalty: ₱500 per extra day (returnDate vs completedAt)
class ReportsService {
  static final _rentals = FirebaseFirestore.instance.collection('rentals');

  static const double penaltyPerDay = 500.0;

  /// Fetches all completed rentals within a date range and calculates metrics.
  /// Filters client-side to avoid requiring a Firestore composite index
  /// and to handle legacy data where completedAt might be null.
  static Future<ReportData> getReport({
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final snapshot = await _rentals
          .where('status', isEqualTo: 'completed')
          .get();

      double totalRevenue = 0;
      double totalPenalties = 0;
      int completedCount = 0;

      final Map<String, double> revenueByDay = {};
      final Map<String, _GownAccumulator> gownMap = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final completedAt = (data['completedAt'] as Timestamp?)?.toDate();

        // Use completedAt if available, otherwise fall back to createdAt
        final effectiveDate = completedAt ??
            (data['createdAt'] as Timestamp?)?.toDate();

        // Filter by date range client-side
        if (effectiveDate == null) continue;
        if (effectiveDate.isBefore(from) || effectiveDate.isAfter(to)) continue;

        final price = (data['gownPrice'] ?? 0).toDouble();
        final returnDate = (data['returnDate'] as Timestamp?)?.toDate();

        // Calculate penalty
        double penalty = 0;
        if (returnDate != null && completedAt != null) {
          final lateDays = completedAt.difference(returnDate).inDays;
          if (lateDays > 0) {
            penalty = lateDays * penaltyPerDay;
          }
        }

        totalRevenue += price + penalty;
        totalPenalties += penalty;
        completedCount++;

        // Group by day for chart
        final dayKey =
            '${effectiveDate.year}-${effectiveDate.month.toString().padLeft(2, '0')}-${effectiveDate.day.toString().padLeft(2, '0')}';
        revenueByDay[dayKey] = (revenueByDay[dayKey] ?? 0) + price + penalty;

        // Track per-gown counts
        final gownId = data['gownId'] as String? ?? '';
        if (gownId.isNotEmpty) {
          final acc = gownMap.putIfAbsent(
            gownId,
            () => _GownAccumulator(
              gownId: gownId,
              gownName: data['gownName'] as String? ?? 'Unknown',
              gownImageUrl: data['gownImageUrl'] as String? ?? '',
              gownCategory: data['gownCategory'] as String? ?? '',
            ),
          );
          acc.count++;
          acc.totalEarnings += price;
        }
      }

      // Sort gowns by rental count descending
      final gownCounts = gownMap.values
          .map((a) => GownRentalCount(
                gownId: a.gownId,
                gownName: a.gownName,
                gownImageUrl: a.gownImageUrl,
                gownCategory: a.gownCategory,
                count: a.count,
                totalEarnings: a.totalEarnings,
              ))
          .toList()
        ..sort((a, b) => b.count.compareTo(a.count));

      return ReportData(
        totalRevenue: totalRevenue,
        totalPenalties: totalPenalties,
        completedRentals: completedCount,
        averageRentalValue:
            completedCount > 0 ? totalRevenue / completedCount : 0,
        revenueByDay: revenueByDay,
        gownRentalCounts: gownCounts,
      );
    } catch (e) {
      debugPrint('[ReportsService.getReport] $e');
      return ReportData.empty();
    }
  }

  /// Gets this month's summary for the dashboard analytics card.
  static Future<ReportData> getThisMonthSummary() async {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, 1);
    final to = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    return getReport(from: from, to: to);
  }

  /// Returns all dates of completed rentals (for building the month dropdown).
  static Future<List<DateTime>> getAllCompletedDates() async {
    try {
      final snapshot = await _rentals
          .where('status', isEqualTo: 'completed')
          .get();

      final List<DateTime> dates = [];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final completedAt = (data['completedAt'] as Timestamp?)?.toDate();
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
        final effectiveDate = completedAt ?? createdAt;
        if (effectiveDate != null) dates.add(effectiveDate);
      }
      return dates;
    } catch (e) {
      debugPrint('[ReportsService.getAllCompletedDates] $e');
      return [];
    }
  }
}

/// Holds calculated report metrics.
class ReportData {
  final double totalRevenue;
  final double totalPenalties;
  final int completedRentals;
  final double averageRentalValue;
  final Map<String, double> revenueByDay;
  final List<GownRentalCount> gownRentalCounts;

  const ReportData({
    required this.totalRevenue,
    required this.totalPenalties,
    required this.completedRentals,
    required this.averageRentalValue,
    required this.revenueByDay,
    this.gownRentalCounts = const [],
  });

  factory ReportData.empty() => const ReportData(
        totalRevenue: 0,
        totalPenalties: 0,
        completedRentals: 0,
        averageRentalValue: 0,
        revenueByDay: {},
        gownRentalCounts: [],
      );

  double get rentalRevenue => totalRevenue - totalPenalties;
}

/// Tracks how many times a specific gown was rented.
class GownRentalCount {
  final String gownId;
  final String gownName;
  final String gownImageUrl;
  final String gownCategory;
  final int count;
  final double totalEarnings;

  const GownRentalCount({
    required this.gownId,
    required this.gownName,
    required this.gownImageUrl,
    required this.gownCategory,
    required this.count,
    required this.totalEarnings,
  });
}

/// Internal accumulator for building gown counts.
class _GownAccumulator {
  final String gownId;
  final String gownName;
  final String gownImageUrl;
  final String gownCategory;
  int count = 0;
  double totalEarnings = 0;

  _GownAccumulator({
    required this.gownId,
    required this.gownName,
    required this.gownImageUrl,
    required this.gownCategory,
  });
}
