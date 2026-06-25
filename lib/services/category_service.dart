import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:smart_rent/core/utils/memory_cache.dart';
import '../core/models/category_model.dart';

class CategoryService {
  static final _collection =
      FirebaseFirestore.instance.collection('categories');

  /// In-memory cache for categories — avoids repeated Firestore reads.
  /// Expires after 5 minutes.
  static final _cache = MemoryCache<List<CategoryModel>>(
    ttl: const Duration(minutes: 5),
  );

  /// Fetches all categories ordered by the [order] field.
  /// Returns cached data if available and not expired.
  static Future<List<CategoryModel>> getCategories() async {
    // Return cached if valid
    final cached = _cache.get();
    if (cached != null) return cached;

    try {
      final snapshot = await _collection.orderBy('order').get();
      final categories = snapshot.docs
          .map((doc) => CategoryModel.fromFirestore(doc))
          .toList();
      _cache.set(categories);
      return categories;
    } on FirebaseException catch (e) {
      debugPrint('[CategoryService.getCategories] $e');
      if (e.code == 'unavailable') rethrow;
      return [];
    } catch (e) {
      debugPrint('[CategoryService.getCategories] $e');
      return [];
    }
  }

  /// Adds a new category and returns the created [CategoryModel], or null on failure.
  /// Returns null if a category with the same name already exists (case-insensitive).
  /// Clears the cache so the next read picks up the new category.
  static Future<CategoryModel?> addCategory(String name) async {
    try {
      final snapshot = await _collection.get();

      // Check for duplicate (case-insensitive)
      final normalizedName = name.trim().toLowerCase();
      final exists = snapshot.docs.any((doc) {
        final existing = (doc.data()['name'] as String? ?? '').trim().toLowerCase();
        return existing == normalizedName;
      });

      if (exists) return null;

      final order = snapshot.docs.length + 1;

      final docRef = await _collection.add({
        'name': name,
        'order': order,
      });

      final doc = await docRef.get();
      final newCategory = CategoryModel.fromFirestore(doc);

      // Clear cache so next getCategories() fetches fresh data
      _cache.clear();

      return newCategory;
    } catch (e) {
      debugPrint('[CategoryService.addCategory] $e');
      return null;
    }
  }

  /// Deletes a category by [categoryId]. Clears cache.
  static Future<bool> deleteCategory(String categoryId) async {
    try {
      await _collection.doc(categoryId).delete();
      _cache.clear();
      return true;
    } catch (e) {
      debugPrint('[CategoryService.deleteCategory] $e');
      return false;
    }
  }
}
