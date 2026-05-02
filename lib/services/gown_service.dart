import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
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
      await _collection.doc(gownId).delete();
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
}