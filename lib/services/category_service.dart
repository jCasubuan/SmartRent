import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../core/models/category_model.dart';

class CategoryService {
  static final _collection =
      FirebaseFirestore.instance.collection('categories');

  /// Fetches all categories ordered by the [order] field.
  static Future<List<CategoryModel>> getCategories() async {
    try {
      final snapshot = await _collection.orderBy('order').get();
      return snapshot.docs
          .map((doc) => CategoryModel.fromFirestore(doc))
          .toList();
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
  static Future<CategoryModel?> addCategory(String name) async {
    try {
      final snapshot = await _collection.get();
      final order = snapshot.docs.length + 1;

      final docRef = await _collection.add({
        'name': name,
        'order': order,
      });

      final doc = await docRef.get();
      return CategoryModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('[CategoryService.addCategory] $e');
      return null;
    }
  }

  /// Deletes a category by [categoryId].
  static Future<bool> deleteCategory(String categoryId) async {
    try {
      await _collection.doc(categoryId).delete();
      return true;
    } catch (e) {
      debugPrint('[CategoryService.deleteCategory] $e');
      return false;
    }
  }
}
