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

  // ── All customers ──────────────────────────────────────────────────────────

  /// Returns all unique customers who have any rental record (any status).
  /// Deduplicated by customerId, sorted alphabetically by name.
  static Future<List<CustomerEntry>> getAllCustomers() async {
    try {
      final snapshot = await _rentals.get();

      final Map<String, Map<String, dynamic>> byCustomer = {};
      for (final doc in snapshot.docs) {
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

      entries.sort((a, b) =>
          a.customerName.toLowerCase().compareTo(b.customerName.toLowerCase()));

      return entries;
    } catch (e) {
      debugPrint('[CustomerService.getAllCustomers] $e');
      return [];
    }
  }

  // ── Delete customer rental records ─────────────────────────────────────────

  /// Deletes ALL rental records for the given customer IDs.
  /// Returns true if all deletions succeeded.
  static Future<bool> deleteCustomerRecords(
      List<String> customerIds) async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      for (final cid in customerIds) {
        final snapshot = await _rentals
            .where('customerId', isEqualTo: cid)
            .get();

        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
      }

      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('[CustomerService.deleteCustomerRecords] $e');
      return false;
    }
  }

  // ── Customer approved/completed history ────────────────────────────────────

  /// Returns all approved, picked_up, and completed rentals for a specific customer,
  /// sorted by approvedAt (or createdAt) descending — newest first.
  static Future<List<RentalModel>> getCustomerApprovedHistory(
      String customerId) async {
    try {
      final results = await Future.wait([
        _rentals
            .where('customerId', isEqualTo: customerId)
            .where('status', isEqualTo: 'approved')
            .get(),
        _rentals
            .where('customerId', isEqualTo: customerId)
            .where('status', isEqualTo: 'picked_up')
            .get(),
        _rentals
            .where('customerId', isEqualTo: customerId)
            .where('status', isEqualTo: 'completed')
            .get(),
      ]);

      final allDocs = [...results[0].docs, ...results[1].docs, ...results[2].docs];
      final rentals =
          allDocs.map((doc) => RentalModel.fromFirestore(doc)).toList();

      rentals.sort((a, b) {
        final aDate = a.approvedAt ?? a.createdAt ?? DateTime(2000);
        final bDate = b.approvedAt ?? b.createdAt ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });

      return rentals;
    } catch (e) {
      debugPrint('[CustomerService.getCustomerApprovedHistory] $e');
      return [];
    }
  }

  // ── Customer declined history ──────────────────────────────────────────────

  /// Returns all rejected rentals for a specific customer,
  /// sorted by createdAt descending — newest first.
  static Future<List<RentalModel>> getCustomerDeclinedHistory(
      String customerId) async {
    try {
      final snapshot = await _rentals
          .where('customerId', isEqualTo: customerId)
          .where('status', isEqualTo: 'rejected')
          .get();

      final rentals =
          snapshot.docs.map((doc) => RentalModel.fromFirestore(doc)).toList();

      rentals.sort((a, b) {
        final aDate = a.createdAt ?? DateTime(2000);
        final bDate = b.createdAt ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });

      return rentals;
    } catch (e) {
      debugPrint('[CustomerService.getCustomerDeclinedHistory] $e');
      return [];
    }
  }

  // ── Customer cancelled history ─────────────────────────────────────────────

  /// Returns all cancelled rentals for a specific customer,
  /// sorted by createdAt descending — newest first.
  static Future<List<RentalModel>> getCustomerCancelledHistory(
      String customerId) async {
    try {
      final snapshot = await _rentals
          .where('customerId', isEqualTo: customerId)
          .where('status', isEqualTo: 'cancelled')
          .get();

      final rentals =
          snapshot.docs.map((doc) => RentalModel.fromFirestore(doc)).toList();

      rentals.sort((a, b) {
        final aDate = a.createdAt ?? DateTime(2000);
        final bDate = b.createdAt ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });

      return rentals;
    } catch (e) {
      debugPrint('[CustomerService.getCustomerCancelledHistory] $e');
      return [];
    }
  }

  // ── Customer pending history ───────────────────────────────────────────────

  /// Returns all pending rentals for a specific customer,
  /// sorted by createdAt descending — newest first.
  static Future<List<RentalModel>> getCustomerPendingHistory(
      String customerId) async {
    try {
      final snapshot = await _rentals
          .where('customerId', isEqualTo: customerId)
          .where('status', isEqualTo: 'pending')
          .get();

      final rentals =
          snapshot.docs.map((doc) => RentalModel.fromFirestore(doc)).toList();

      rentals.sort((a, b) {
        final aDate = a.createdAt ?? DateTime(2000);
        final bDate = b.createdAt ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });

      return rentals;
    } catch (e) {
      debugPrint('[CustomerService.getCustomerPendingHistory] $e');
      return [];
    }
  }
}
