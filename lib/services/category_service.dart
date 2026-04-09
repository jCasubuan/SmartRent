import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/models/category_model.dart';

class CategoryService {
  static final _collection =
      FirebaseFirestore.instance.collection('categories');

  // Fetch all categories ordered by order field
  static Future<List<CategoryModel>> getCategories() async {
    try {
      final snapshot =
          await _collection.orderBy('order').get();
      return snapshot.docs
          .map((doc) => CategoryModel.fromFirestore(doc))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // Add a new category
  static Future<CategoryModel?> addCategory(String name) async {
    try {
      // Get current count to determine order
      final snapshot = await _collection.get();
      final order = snapshot.docs.length + 1;

      final docRef = await _collection.add({
        'name': name,
        'order': order,
      });

      final doc = await docRef.get();
      return CategoryModel.fromFirestore(doc);
    } catch (_) {
      return null;
    }
  }

  // Delete a category
  static Future<bool> deleteCategory(String categoryId) async {
    try {
      await _collection.doc(categoryId).delete();
      return true;
    } catch (_) {
      return false;
    }
  }
}