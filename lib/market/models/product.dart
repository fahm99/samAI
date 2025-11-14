import 'package:equatable/equatable.dart';

/// نموذج المنتج في السوق الزراعي
class Product extends Equatable {
  final String id;
  final String name;
  final double price;
  final String description;
  final String category;
  final List<String> imageUrls;
  final bool isActive;
  final DateTime createdAt;
  final String userId;
  final String location;
  final String sellerName;
  final String? sellerAvatar;
  final String? sellerPhone;
  final int likesCount;
  final bool isLiked;
  final double averageRating;
  final int ratingsCount;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.category,
    required this.imageUrls,
    required this.isActive,
    required this.createdAt,
    required this.userId,
    required this.location,
    required this.sellerName,
    this.sellerAvatar,
    this.sellerPhone,
    required this.likesCount,
    required this.isLiked,
    required this.averageRating,
    required this.ratingsCount,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      imageUrls: List<String>.from(map['image_urls'] ?? []),
      isActive: map['is_active'] ?? true,
      createdAt:
          DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      userId: map['user_id'] ?? '',
      location: map['location'] ?? '',
      sellerName: map['profiles']?['full_name'] ?? 'غير محدد',
      sellerAvatar: map['profiles']?['avatar_url'],
      sellerPhone: map['profiles']?['phone_number'],
      likesCount: map['likes_count'] ?? 0,
      isLiked: map['is_liked'] ?? false,
      averageRating: (map['average_rating'] ?? 0.0).toDouble(),
      ratingsCount: map['ratings_count'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'description': description,
      'category': category,
      'image_urls': imageUrls,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'user_id': userId,
      'location': location,
      'likes_count': likesCount,
      'is_liked': isLiked,
      'average_rating': averageRating,
      'ratings_count': ratingsCount,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        price,
        description,
        category,
        imageUrls,
        isActive,
        createdAt,
        userId,
        location,
        sellerName,
        sellerAvatar,
        sellerPhone,
        likesCount,
        isLiked,
        averageRating,
        ratingsCount,
      ];

  Product copyWith({
    String? id,
    String? name,
    double? price,
    String? description,
    String? category,
    List<String>? imageUrls,
    bool? isActive,
    DateTime? createdAt,
    String? userId,
    String? location,
    String? sellerName,
    String? sellerAvatar,
    String? sellerPhone,
    int? likesCount,
    bool? isLiked,
    double? averageRating,
    int? ratingsCount,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      description: description ?? this.description,
      category: category ?? this.category,
      imageUrls: imageUrls ?? this.imageUrls,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
      location: location ?? this.location,
      sellerName: sellerName ?? this.sellerName,
      sellerAvatar: sellerAvatar ?? this.sellerAvatar,
      sellerPhone: sellerPhone ?? this.sellerPhone,
      likesCount: likesCount ?? this.likesCount,
      isLiked: isLiked ?? this.isLiked,
      averageRating: averageRating ?? this.averageRating,
      ratingsCount: ratingsCount ?? this.ratingsCount,
    );
  }
}
