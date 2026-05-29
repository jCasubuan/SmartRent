import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a rental request document from the `rentals` collection.
class RentalModel {
  final String id;
  final String gownId;
  final String gownName;
  final String gownCode;
  final String gownImageUrl;
  final String gownCategory;
  final String gownColor;
  final double gownPrice;
  final String customerId;
  final String customerName;
  final String phone;
  final DateTime pickupDate;
  final DateTime returnDate;
  final String status; // pending | approved | rejected | cancelled | completed
  final String? cancellationReason;
  final DateTime? createdAt;
  final DateTime? approvedAt;
  final DateTime? completedAt;

  const RentalModel({
    required this.id,
    required this.gownId,
    required this.gownName,
    required this.gownCode,
    required this.gownImageUrl,
    required this.gownCategory,
    required this.gownColor,
    required this.gownPrice,
    required this.customerId,
    required this.customerName,
    required this.phone,
    required this.pickupDate,
    required this.returnDate,
    required this.status,
    this.cancellationReason,
    this.createdAt,
    this.approvedAt,
    this.completedAt,
  });

  factory RentalModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RentalModel(
      id: doc.id,
      gownId: data['gownId'] ?? '',
      gownName: data['gownName'] ?? '',
      gownCode: data['gownCode'] ?? '',
      gownImageUrl: data['gownImageUrl'] ?? '',
      gownCategory: data['gownCategory'] ?? '',
      gownColor: data['gownColor'] ?? '',
      gownPrice: (data['gownPrice'] ?? 0).toDouble(),
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      phone: data['phone'] ?? '',
      pickupDate: (data['pickupDate'] as Timestamp).toDate(),
      returnDate: (data['returnDate'] as Timestamp).toDate(),
      status: data['status'] ?? 'pending',
      cancellationReason: data['cancellationReason'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      approvedAt: (data['approvedAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
    );
  }
}
