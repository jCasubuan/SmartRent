import 'package:cloud_firestore/cloud_firestore.dart';

class GownModel {
  final String id;
  final String code;
  final String name;
  final String category;
  final String color;
  final Map<String, String> measurements;
  final double rentalPrice;
  final String status;
  final List<String> imageUrls;
  final String description;
  final DateTime? addedAt;

  // Client-side only — not stored in Firestore
  final bool isFavorite;

  const GownModel({
    required this.id,
    required this.code,
    required this.name,
    required this.category,
    required this.color,
    required this.measurements,
    required this.rentalPrice,
    this.status = 'available',
    this.imageUrls = const [],
    this.description = '',
    this.addedAt,
    this.isFavorite = false,
  });

  // From Firestore document
  factory GownModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GownModel(
      id: doc.id,
      code: data['code'] ?? '',
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      color: data['color'] ?? '',
      measurements: Map<String, String>.from(data['measurements'] ?? {}),
      rentalPrice: (data['rentalPrice'] ?? 0).toDouble(),
      status: data['status'] ?? 'available',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      description: data['description'] ?? '',
      addedAt: (data['addedAt'] as Timestamp?)?.toDate(),
    );
  }

  // To Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'code': code,
      'name': name,
      'category': category,
      'color': color,
      'measurements': measurements,
      'rentalPrice': rentalPrice,
      'status': status,
      'imageUrls': imageUrls,
      'description': description,
      'addedAt': FieldValue.serverTimestamp(),
    };
  }
}