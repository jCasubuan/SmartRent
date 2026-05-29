import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:smart_rent/core/models/rental_model.dart';

/// A lightweight model representing a unique customer derived from rental data.
/// All fields come from the rental document — no users collection lookup needed.
class CustomerEntry {
  final String customerId;
  final String customerName;
  final String phone;
  final String? photoUrl; // from users collection if available, else null
  final int totalRentals;

  const CustomerEntry({
    required this.customerId,
    required this.customerName,
    required this.phone,
    this.photoUrl,
    required this.totalRentals,
  });
}

/// Provides customer-related queries derived from the rentals collection.
class CustomerService {
  static final _rentals =
      FirebaseFirestore.instance.collection('rentals');
  static final _users =
      FirebaseFirestore.instance.collection('users');

  // ── Customer list ──────────────────────────────────────────────────────────

  /// Returns unique customers who have at least one approved or completed rental.
  /// Results are deduplicated by customerId and sorted by name.
  /// Optionally fetches profile photo URLs from the users collection.
  static Future<List<CustomerEntry>> getApprovedCustomers() async {
    try {
      // Fetch all approved + completed rentals in one query each, then merge.
      final results = await Future.wait([
        _rentals.where('status', isEqualTo: 'approved').get(),
        _rentals.where('status', isEqualTo: 'completed').get(),
      ]);

      final allDocs = [...results[0].docs, ...results[1].docs];

      // Deduplicate by customerId, keeping the latest name/phone and counting rentals.
      final Map<String, Map<String, dynamic>> byCustomer = {};
      for (final doc in allDocs) {
        final data = doc.data();
        final cid = '${data['customerId'] ?? ''}';
        if (cid.isEmpty) continue;

        if (byCustomer.containsKey(cid)) {
          byCustomer[cid]!['count'] = (byCustomer[cid]!['count'] as int) + 1;
        } else {
          byCustomer[cid] = {
            'customerId': cid,
            'customerName': '${data['customerName'] ?? ''}',
            'phone': '${data['phone'] ?? ''}',
            'count': 1,
          };
        }
      }

      if (byCustomer.isEmpty) return [];

      // Fetch profile photos from users collection in parallel.
      final photoFutures = byCustomer.keys.map((uid) async {
        try {
          final doc = await _users.doc(uid).get();
          return MapEntry(uid, doc.data()?['photoUrl'] as String?);
        } catch (_) {
          return MapEntry(uid, null);
        }
      });
      final photoEntries = await Future.wait(photoFutures);
      final photoMap = Map<String, String?>.fromEntries(photoEntries);

      final entries = byCustomer.values.map((m) {
        return CustomerEntry(
          customerId: m['customerId'] as String,
          customerName: m['customerName'] as String,
          phone: m['phone'] as String,
          photoUrl: photoMap[m['customerId']],
          totalRentals: m['count'] as int,
        );
      }).toList();

      // Sort alphabetically by name.
      entries.sort((a, b) =>
          a.customerName.toLowerCase().compareTo(b.customerName.toLowerCase()));

      return entries;
    } catch (e) {
      debugPrint('[CustomerService.getApprovedCustomers] $e');
      return [];
    }
  }

  // ── Customer rental history ────────────────────────────────────────────────

  /// Returns all approved + completed rentals for a specific customer,
  /// sorted by approvedAt (or createdAt) descending — newest first.
  static Future<List<RentalModel>> getCustomerHistory(
      String customerId) async {
    try {
      final results = await Future.wait([
        _rentals
            .where('customerId', isEqualTo: customerId)
            .where('status', isEqualTo: 'approved')
            .get(),
        _rentals
            .where('customerId', isEqualTo: customerId)
            .where('status', isEqualTo: 'completed')
            .get(),
      ]);

      final allDocs = [...results[0].docs, ...results[1].docs];
      final rentals =
          allDocs.map((doc) => RentalModel.fromFirestore(doc)).toList();

      // Sort newest first using approvedAt if available, else createdAt.
      rentals.sort((a, b) {
        final aDate = a.approvedAt ?? a.createdAt ?? DateTime(2000);
        final bDate = b.approvedAt ?? b.createdAt ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });

      return rentals;
    } catch (e) {
      debugPrint('[CustomerService.getCustomerHistory] $e');
      return [];
    }
  }
}
