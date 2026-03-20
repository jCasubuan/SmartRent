class GownModel {
  final String id;
  final String name;
  final double price;
  final String categoryId;
  final String imageUrl;
  final bool isFavorite;

  const GownModel({
    required this.id,
    required this.name,
    required this.price,
    required this.categoryId,
    this.imageUrl = '',
    this.isFavorite = false,
  });
}