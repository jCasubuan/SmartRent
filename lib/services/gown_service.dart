import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../core/models/gown_model.dart';

class GownService {
  static final _collection =
      FirebaseFirestore.instance.collection('gowns');
  static final _storage = FirebaseStorage.instance;

  // Auto-generate gown code example GWN-001
  static Future<String> _generateCode() async {
    final snapshot = await _collection.get();
    final count = snapshot.docs.length + 1;
    return 'GWN-${count.toString().padLeft(3, '0')}';
  }

  // Upload multiple images to Firebase Storage
  // Returns list of download URLs
  static Future<List<String>> uploadImages(
      List<File> images, String gownCode) async {
    final List<String> urls = [];
    for (int i = 0; i < images.length; i++) {
      final ref = _storage
          .ref()
          .child('gowns/$gownCode/image_$i.jpg');
      final uploadTask = await ref.putFile(images[i]);
      final url = await uploadTask.ref.getDownloadURL();
      urls.add(url);
    }
    return urls;
  }

  // Add a new gown
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

      // Upload images first
      final imageUrls = images.isNotEmpty
          ? await uploadImages(images, code)
          : <String>[];

      // Save gown document
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
    } catch (_) {
      return false;
    }
  }

  // Fetch all gowns
  static Future<List<GownModel>> getGowns() async {
    try {
      final snapshot =
          await _collection.orderBy('addedAt', descending: true).get();
      return snapshot.docs
          .map((doc) => GownModel.fromFirestore(doc))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // Fetch gowns by status
  static Future<List<GownModel>> getGownsByStatus(String status) async {
    try {
      final snapshot = await _collection
          .where('status', isEqualTo: status)
          .get();
      return snapshot.docs
          .map((doc) => GownModel.fromFirestore(doc))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // Update gown status
  static Future<bool> updateStatus(String gownId, String status) async {
    try {
      await _collection.doc(gownId).update({'status': status});
      return true;
    } catch (_) {
      return false;
    }
  }
}