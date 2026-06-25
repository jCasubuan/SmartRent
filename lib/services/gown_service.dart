import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:smart_rent/services/admin_log_service.dart';
import 'package:smart_rent/services/cloudinary_service.dart';
import '../core/models/gown_model.dart';

class GownService {
  static final _collection = FirebaseFirestore.instance.collection('gowns');

  static Future<String> _generateCode() async {
    final snapshot = await _collection.get();
    final count = snapshot.docs.length + 1;
    return 'GWN-${count.toString().padLeft(3, '0')}';
  }

  static Future<bool> addGown({
    required String name,
    required String category,
    required String color,
    required Map<String, String> measurements,
    required double rentalPrice,
    required String description,
    required List<File> images,
  }) async {
    try {
      final code = await _generateCode();

      final imageUrls = images.isNotEmpty
          ? await CloudinaryService.uploadImages(images, code)
          : <String>[];

      await _collection.add({
        'code': code,
        'name': name,
        'category': category,
        'color': color,
        'measurements': measurements,
        'rentalPrice': rentalPrice,
        'status': 'available',
        'imageUrls': imageUrls,
        'description': description,
        'addedAt': FieldValue.serverTimestamp(),
      });

      // Admin log
      AdminLogService.log(
        type: AdminLogType.gownAdded,
        title: 'Gown added',
        body: '"$name" ($code) added to inventory',
        targetType: 'gown',
        targetId: code,
      );

      return true;
    } catch (e) {
      debugPrint('[GownService.addGown] $e');
      return false;
    }
  }

  /// Updates an existing gown. Uploads any new local images, keeps retained URLs.
  static Future<bool> updateGown({
    required String gownId,
    required String code,
    required String name,
    required String category,
    required String color,
    required Map<String, String> measurements,
    required double rentalPrice,
    required String description,
    required String status,
    required List<String> retainedImageUrls,
    required List<File> newImages,
  }) async {
    try {
      final newUrls = newImages.isNotEmpty
          ? await CloudinaryService.uploadImages(newImages, code)
          : <String>[];

      final allImageUrls = [...retainedImageUrls, ...newUrls];

      await _collection.doc(gownId).update({
        'name': name,
        'category': category,
        'color': color,
        'measurements': measurements,
        'rentalPrice': rentalPrice,
        'description': description,
        'status': status,
        'imageUrls': allImageUrls,
      });

      // Admin log
      AdminLogService.log(
        type: AdminLogType.gownEdited,
        title: 'Gown updated',
        body: '"$name" ($code) was edited',
        targetType: 'gown',
        targetId: gownId,
      );

      return true;
    } catch (e) {
      debugPrint('[GownService.updateGown] $e');
      return false;
    }
  }

  /// Deletes a gown document from Firestore only.
  /// Note: Cloudinary images become orphaned and must be removed manually
  /// from the Cloudinary dashboard. Client-side deletion is intentionally
  /// omitted to avoid exposing the api_secret in the app bundle.
  static Future<bool> deleteGown(String gownId) async {
    try {
      // Fetch name before deleting for the log
      final doc = await _collection.doc(gownId).get();
      final name = doc.data()?['name'] ?? 'Unknown';
      final code = doc.data()?['code'] ?? '';

      await _collection.doc(gownId).delete();

      // Admin log
      AdminLogService.log(
        type: AdminLogType.gownDeleted,
        title: 'Gown deleted',
        body: '"$name" ($code) was removed from inventory',
        targetType: null,
        targetId: null,
      );

      return true;
    } catch (e) {
      debugPrint('[GownService.deleteGown] $e');
      return false;
    }
  }

  static Future<List<GownModel>> getGowns() async {
    try {
      final snapshot =
          await _collection.orderBy('addedAt', descending: true).get();
      return snapshot.docs.map((doc) => GownModel.fromFirestore(doc)).toList();
    } on FirebaseException catch (e) {
      debugPrint('[GownService.getGowns] $e');
      if (e.code == 'unavailable') rethrow;
      return [];
    } catch (e) {
      debugPrint('[GownService.getGowns] $e');
      return [];
    }
  }

  static Future<List<GownModel>> getGownsByStatus(String status) async {
    try {
      final snapshot =
          await _collection.where('status', isEqualTo: status).get();
      return snapshot.docs.map((doc) => GownModel.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('[GownService.getGownsByStatus] $e');
      return [];
    }
  }

  static Future<bool> updateStatus(String gownId, String status) async {
    try {
      await _collection.doc(gownId).update({'status': status});
      return true;
    } catch (e) {
      debugPrint('[GownService.updateStatus] $e');
      return false;
    }
  }

  /// Fetches gowns with optional search and sort.
  static Future<List<GownModel>> getGownsFiltered({
    String searchQuery = '',
    String sortBy = 'addedAt',
    bool descending = true,
  }) async {
    try {
      final query = _collection.orderBy(sortBy, descending: descending);
      final snapshot = await query.get();
      List<GownModel> gowns =
          snapshot.docs.map((doc) => GownModel.fromFirestore(doc)).toList();

      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        gowns = gowns.where((g) {
          return g.name.toLowerCase().contains(q) ||
              g.category.toLowerCase().contains(q) ||
              g.color.toLowerCase().contains(q) ||
              g.code.toLowerCase().contains(q);
        }).toList();
      }

      return gowns;
    } on FirebaseException catch (e) {
      debugPrint('[GownService.getGownsFiltered] $e');
      if (e.code == 'unavailable') rethrow;
      return [];
    } catch (e) {
      debugPrint('[GownService.getGownsFiltered] $e');
      return [];
    }
  }

  static Future<int> getAvailableCount() async {
    try {
      final snapshot =
          await _collection.where('status', isEqualTo: 'available').get();
      return snapshot.docs.length;
    } catch (e) {
      debugPrint('[GownService.getAvailableCount] $e');
      return 0;
    }
  }

  /// Checks if a gown with the same name already exists (case-insensitive).
  /// Returns the existing gown's code if found, or null if no duplicate.
  /// [excludeId] can be passed when editing — to exclude the gown being edited.
  static Future<String?> checkDuplicateName(String name, {String? excludeId}) async {
    try {
      final snapshot = await _collection.get();
      final normalized = name.trim().toLowerCase();

      for (final doc in snapshot.docs) {
        if (excludeId != null && doc.id == excludeId) continue;
        final existingName = (doc.data()['name'] as String? ?? '').trim().toLowerCase();
        if (existingName == normalized) {
          return doc.data()['code'] as String? ?? '';
        }
      }
      return null;
    } catch (e) {
      debugPrint('[GownService.checkDuplicateName] $e');
      return null;
    }
  }

  // ── Real-time streams ──────────────────────────────────────────────────────

  /// Live stream of all gowns, newest first.
  static Stream<List<GownModel>> gownsStream() {
    return _collection
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => GownModel.fromFirestore(doc)).toList());
  }

  /// Live stream of available gown count.
  static Stream<int> availableCountStream() {
    return _collection
        .where('status', isEqualTo: 'available')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Live stream of total gown count.
  static Stream<int> totalCountStream() {
    return _collection
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // ── Cleaning management ────────────────────────────────────────────────────

  /// Sets a gown to 'cleaning' status with start and expected completion dates.
  static Future<bool> sendToCleaning({
    required String gownId,
    required DateTime startDate,
    required DateTime expectedDate,
  }) async {
    try {
      final doc = await _collection.doc(gownId).get();
      final name = doc.data()?['name'] ?? 'Unknown';

      await _collection.doc(gownId).update({
        'status': 'cleaning',
        'cleaningStartDate': Timestamp.fromDate(startDate),
        'cleaningExpectedDate': Timestamp.fromDate(expectedDate),
      });

      AdminLogService.log(
        type: AdminLogType.gownSentCleaning,
        title: 'Sent to cleaning',
        body: '"$name" sent for cleaning',
        targetType: 'cleaning',
        targetId: gownId,
      );

      return true;
    } catch (e) {
      debugPrint('[GownService.sendToCleaning] $e');
      return false;
    }
  }

  /// Marks a cleaning gown as available and clears cleaning dates.
  static Future<bool> markAsClean(String gownId) async {
    try {
      final doc = await _collection.doc(gownId).get();
      final name = doc.data()?['name'] ?? 'Unknown';

      await _collection.doc(gownId).update({
        'status': 'available',
        'cleaningStartDate': FieldValue.delete(),
        'cleaningExpectedDate': FieldValue.delete(),
        'rentalReturnDate': FieldValue.delete(),
      });

      AdminLogService.log(
        type: AdminLogType.gownMarkedClean,
        title: 'Cleaning done',
        body: '"$name" is now available',
        targetType: 'gown',
        targetId: gownId,
      );

      return true;
    } catch (e) {
      debugPrint('[GownService.markAsClean] $e');
      return false;
    }
  }

  /// Returns all gowns currently in cleaning status with their cleaning dates.
  static Future<List<Map<String, dynamic>>> getCleaningGownsWithDates() async {
    try {
      final snapshot =
          await _collection.where('status', isEqualTo: 'cleaning').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'gown': GownModel.fromFirestore(doc),
          'cleaningStartDate':
              (data['cleaningStartDate'] as Timestamp?)?.toDate(),
          'cleaningExpectedDate':
              (data['cleaningExpectedDate'] as Timestamp?)?.toDate(),
        };
      }).toList();
    } catch (e) {
      debugPrint('[GownService.getCleaningGownsWithDates] $e');
      return [];
    }
  }

  // ── Repair management ──────────────────────────────────────────────────────

  /// Sets a gown to 'repair' status with start and expected completion dates.
  static Future<bool> sendToRepair({
    required String gownId,
    required DateTime startDate,
    required DateTime expectedDate,
  }) async {
    try {
      final doc = await _collection.doc(gownId).get();
      final name = doc.data()?['name'] ?? 'Unknown';

      await _collection.doc(gownId).update({
        'status': 'repair',
        'repairStartDate': Timestamp.fromDate(startDate),
        'repairExpectedDate': Timestamp.fromDate(expectedDate),
      });

      AdminLogService.log(
        type: AdminLogType.gownSentRepair,
        title: 'Sent to repair',
        body: '"$name" sent for repair',
        targetType: 'repair',
        targetId: gownId,
      );

      return true;
    } catch (e) {
      debugPrint('[GownService.sendToRepair] $e');
      return false;
    }
  }

  /// Marks a repair gown as available and clears repair dates.
  static Future<bool> markRepairDone(String gownId) async {
    try {
      final doc = await _collection.doc(gownId).get();
      final name = doc.data()?['name'] ?? 'Unknown';

      await _collection.doc(gownId).update({
        'status': 'available',
        'repairStartDate': FieldValue.delete(),
        'repairExpectedDate': FieldValue.delete(),
      });

      AdminLogService.log(
        type: AdminLogType.gownRepairDone,
        title: 'Repair done',
        body: '"$name" is now available',
        targetType: 'gown',
        targetId: gownId,
      );

      return true;
    } catch (e) {
      debugPrint('[GownService.markRepairDone] $e');
      return false;
    }
  }

  /// Returns all gowns currently in repair status with their repair dates.
  static Future<List<Map<String, dynamic>>> getRepairGownsWithDates() async {
    try {
      final snapshot =
          await _collection.where('status', isEqualTo: 'repair').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'gown': GownModel.fromFirestore(doc),
          'repairStartDate':
              (data['repairStartDate'] as Timestamp?)?.toDate(),
          'repairExpectedDate':
              (data['repairExpectedDate'] as Timestamp?)?.toDate(),
        };
      }).toList();
    } catch (e) {
      debugPrint('[GownService.getRepairGownsWithDates] $e');
      return [];
    }
  }
}
