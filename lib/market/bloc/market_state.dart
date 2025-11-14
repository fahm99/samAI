import 'package:equatable/equatable.dart';
import '../models/product.dart';
import '../models/product_rating.dart';

/// حالات السوق الزراعي
abstract class MarketState extends Equatable {
  @override
  List<Object?> get props => [];
}

/// الحالة الأولية
class MarketInitial extends MarketState {}

/// حالة تحميل البيانات
class MarketLoading extends MarketState {}

/// حالة تحميل البيانات بنجاح
class MarketLoaded extends MarketState {
  final List<Product> products;
  final List<String> categories;
  final List<String> locations;
  final bool hasMoreProducts;
  final int currentPage;
  final bool isLoadingMore;

  MarketLoaded({
    required this.products,
    required this.categories,
    required this.locations,
    this.hasMoreProducts = true,
    this.currentPage = 1,
    this.isLoadingMore = false,
  });

  @override
  List<Object> get props => [
        products,
        categories,
        locations,
        hasMoreProducts,
        currentPage,
        isLoadingMore
      ];

  MarketLoaded copyWith({
    List<Product>? products,
    List<String>? categories,
    List<String>? locations,
    bool? hasMoreProducts,
    int? currentPage,
    bool? isLoadingMore,
  }) {
    return MarketLoaded(
      products: products ?? this.products,
      categories: categories ?? this.categories,
      locations: locations ?? this.locations,
      hasMoreProducts: hasMoreProducts ?? this.hasMoreProducts,
      currentPage: currentPage ?? this.currentPage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

/// حالة تحميل تفاصيل المنتج
class ProductDetailsLoaded extends MarketState {
  final Product product;
  final List<ProductRating> ratings;
  final bool isOwner;

  ProductDetailsLoaded({
    required this.product,
    required this.ratings,
    required this.isOwner,
  });

  @override
  List<Object> get props => [product, ratings, isOwner];
}

/// حالة الخطأ
class MarketError extends MarketState {
  final String message;

  MarketError({required this.message});

  @override
  List<Object> get props => [message];
}

/// حالة النجاح
class MarketSuccess extends MarketState {
  final String message;

  MarketSuccess({required this.message});

  @override
  List<Object> get props => [message];
}
