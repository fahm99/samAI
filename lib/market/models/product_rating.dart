import 'package:equatable/equatable.dart';

/// نموذج تقييم المنتج
class ProductRating extends Equatable {
  final String id;
  final String productId;
  final String userId;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final String userName;
  final String? userAvatar;

  const ProductRating({
    required this.id,
    required this.productId,
    required this.userId,
    required this.rating,
    this.comment,
    required this.createdAt,
    required this.userName,
    this.userAvatar,
  });

  factory ProductRating.fromMap(Map<String, dynamic> map) {
    return ProductRating(
      id: map['id'] ?? '',
      productId: map['product_id'] ?? '',
      userId: map['user_id'] ?? '',
      rating: map['rating'] ?? 1,
      comment: map['comment'],
      createdAt:
          DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      userName: map['profiles']?['full_name'] ?? 'غير محدد',
      userAvatar: map['profiles']?['avatar_url'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'user_id': userId,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        productId,
        userId,
        rating,
        comment,
        createdAt,
        userName,
        userAvatar,
      ];
}
