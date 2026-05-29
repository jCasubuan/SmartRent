import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:smart_rent/core/models/rental_model.dart';
import 'package:smart_rent/services/notification_service.dart';

/// Handles rental request operations in Firestore.
class RentalService {
  static final _collection =
      FirebaseFirestore.instance.collection('rentals');
  static final _gowns =
      FirebaseFirestore.instance.collection('gowns');

  // ── Customer — submit ──────────────────────────────────────────────────────

  static Future<bool> submitRequest({
    required String gownId,
    required String gownName,
    required String gownCode,
    required String gownImageUrl,
    required String gownCategory,
    required String gownColor,
    required double gownPrice,
    required String customerId,
    required String customerName,
    required String phone,
    required DateTime pickupDate,
    required DateTime returnDate,
  }) async {
    try {
      await _collection.add({
        'gownId': gownId,
        'gownName': gownName,
        'gownCode': gownCode,
        'gownImageUrl': gownImageUrl,
        'gownCategory': gownCategory,
        'gownColor': gownColor,
        'gownPrice': gownPrice,
        'customerId': customerId,
        'customerName': customerName,
        'phone': phone,
        'pickupDate': Timestamp.fromDate(pickupDate),
        'returnDate': Timestamp.fromDate(returnDate),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('[RentalService.submitRequest] $e');
      return false;
    }
  }

  // ── Customer — streams ─────────────────────────────────────────────────────

  /// Real-time stream of all rentals for a specific customer, newest first.
  static Stream<List<RentalModel>> customerRentalsStream(String customerId) {
    return _collection
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => RentalModel.fromFirestore(doc))
              .toList();
          list.sort((a, b) {
            if (a.createdAt == null && b.createdAt == null) return 0;
            if (a.createdAt == null) return 1;
            if (b.createdAt == null) return -1;
            return b.createdAt!.compareTo(a.createdAt!);
          });
          return list;
        });
  }

  // ── Customer — modify ──────────────────────────────────────────────────────

  /// Updates an existing pending rental request (Option A — in-place update).
  /// Only allowed when status is still `pending`.
  static Future<bool> updateRequest({
    required String rentalId,
    required String customerName,
    required String phone,
    required DateTime pickupDate,
    required DateTime returnDate,
  }) async {
    try {
      await _collection.doc(rentalId).update({
        'customerName': customerName,
        'phone': phone,
        'pickupDate': Timestamp.fromDate(pickupDate),
        'returnDate': Timestamp.fromDate(returnDate),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('[RentalService.updateRequest] $e');
      return false;
    }
  }

  // ── Customer — cancel ──────────────────────────────────────────────────────

  /// Cancels a pending rental request with a required reason.
  /// Sets status to `cancelled` and stores the cancellation reason.
  static Future<bool> cancelRequest({
    required String rentalId,
    required String reason,
  }) async {
    try {
      await _collection.doc(rentalId).update({
        'status': 'cancelled',
        'cancellationReason': reason,
        'cancelledAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('[RentalService.cancelRequest] $e');
      return false;
    }
  }

  // ── Admin — streams ────────────────────────────────────────────────────────

  /// Real-time stream of all pending rental requests, newest first.
  static Stream<List<RentalModel>> pendingRequestsStream() {
    return _collection
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => RentalModel.fromFirestore(doc))
              .toList();
          list.sort((a, b) {
            if (a.createdAt == null && b.createdAt == null) return 0;
            if (a.createdAt == null) return 1;
            if (b.createdAt == null) return -1;
            return b.createdAt!.compareTo(a.createdAt!);
          });
          return list;
        });
  }

  /// Real-time count of pending requests — used for the inbox badge.
  static Stream<int> pendingCountStream() {
    return _collection
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // ── Admin — actions ────────────────────────────────────────────────────────

  /// Approves a rental request, marks the gown as rented, and notifies the customer.
  static Future<bool> approveRequest(String rentalId, String gownId) async {
    try {
      // Fetch the rental first so we have customerId + gownName for the notification.
      final rentalDoc = await _collection.doc(rentalId).get();
      final data = rentalDoc.data();
      final customerId = '${data?['customerId'] ?? ''}';
      final gownName = '${data?['gownName'] ?? 'your gown'}';
      final pickupDate = (data?['pickupDate'] as Timestamp?)?.toDate();
      final pickupStr = pickupDate != null
          ? '${_monthName(pickupDate.month)} ${pickupDate.day}, ${pickupDate.year}'
          : '';

      final batch = FirebaseFirestore.instance.batch();
      batch.update(_collection.doc(rentalId), {
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
      });
      batch.update(_gowns.doc(gownId), {'status': 'rented'});
      await batch.commit();

      // Send in-app notification to the customer.
      if (customerId.isNotEmpty) {
        await NotificationService.sendNotification(
          customerId: customerId,
          title: 'Your booking is confirmed! 🎉',
          body: pickupStr.isNotEmpty
              ? 'Great news! Your request for "$gownName" has been approved. Please come to the shop to pick it up on $pickupStr.'
              : 'Great news! Your request for "$gownName" has been approved. Please come to the shop to pick it up.',
          type: 'approved',
          rentalId: rentalId,
          gownName: gownName,
        );
      }

      return true;
    } catch (e) {
      debugPrint('[RentalService.approveRequest] $e');
      return false;
    }
  }

  /// Rejects a rental request, gown remains available, and notifies the customer.
  static Future<bool> rejectRequest(String rentalId) async {
    try {
      // Fetch rental for notification data.
      final rentalDoc = await _collection.doc(rentalId).get();
      final data = rentalDoc.data();
      final customerId = '${data?['customerId'] ?? ''}';
      final gownName = '${data?['gownName'] ?? 'your gown'}';

      await _collection.doc(rentalId).update({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
      });

      // Send in-app notification to the customer.
      if (customerId.isNotEmpty) {
        await NotificationService.sendNotification(
          customerId: customerId,
          title: 'Request not approved',
          body: 'Unfortunately, your request for "$gownName" wasn\'t approved this time. Feel free to browse our other available gowns.',
          type: 'rejected',
          rentalId: rentalId,
          gownName: gownName,
        );
      }

      return true;
    } catch (e) {
      debugPrint('[RentalService.rejectRequest] $e');
      return false;
    }
  }

  /// Marks a rental as completed and sets the gown status.
  /// [nextGownStatus] can be 'available', 'cleaning', or 'repair'.
  static Future<bool> completeRental(
    String rentalId,
    String gownId, {
    String nextGownStatus = 'available',
  }) async {
    try {
      final rentalDoc = await _collection.doc(rentalId).get();
      final data = rentalDoc.data();
      final customerId = '${data?['customerId'] ?? ''}';
      final gownName = '${data?['gownName'] ?? 'your gown'}';

      final batch = FirebaseFirestore.instance.batch();
      batch.update(_collection.doc(rentalId), {
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });
      batch.update(_gowns.doc(gownId), {'status': nextGownStatus});
      await batch.commit();

      // Notify the customer that the rental is closed.
      if (customerId.isNotEmpty) {
        await NotificationService.sendNotification(
          customerId: customerId,
          title: 'Rental closed — thank you!',
          body: 'Your rental of "$gownName" has been marked as returned. We hope you had a great experience!',
          type: 'completed',
          rentalId: rentalId,
          gownName: gownName,
        );
      }

      return true;
    } catch (e) {
      debugPrint('[RentalService.completeRental] $e');
      return false;
    }
  }

  // ── Streams — approved rentals (for admin "Active" view) ───────────────────

  /// Real-time stream of all approved (active) rentals, newest first.
  static Stream<List<RentalModel>> approvedRentalsStream() {
    return _collection
        .where('status', isEqualTo: 'approved')
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => RentalModel.fromFirestore(doc))
              .toList();
          list.sort((a, b) {
            if (a.createdAt == null && b.createdAt == null) return 0;
            if (a.createdAt == null) return 1;
            if (b.createdAt == null) return -1;
            return b.createdAt!.compareTo(a.createdAt!);
          });
          return list;
        });
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static String _monthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return months[month - 1];
  }
}
