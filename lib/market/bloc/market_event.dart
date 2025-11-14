import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// أحداث السوق الزراعي
abstract class MarketEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// تحميل بيانات السوق الأساسية
class LoadMarketDataEvent extends MarketEvent {}

/// تحميل المنتجات مع الفلاتر
class LoadProductsEvent extends MarketEvent {
  final String? category;
  final String? location;
  final bool isRefresh;
  final int page;
  final int limit;

  LoadProductsEvent({
    this.category,
    this.location,
    this.isRefresh = false,
    this.page = 1,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [category, location, isRefresh, page, limit];
}

/// تحميل المزيد من المنتجات (pagination)
class LoadMoreProductsEvent extends MarketEvent {
  final String? category;
  final String? location;

  LoadMoreProductsEvent({this.category, this.location});

  @override
  List<Object?> get props => [category, location];
}

/// تحميل تفاصيل منتج محدد
class LoadProductDetailsEvent extends MarketEvent {
  final String productId;

  LoadProductDetailsEvent({required this.productId});

  @override
  List<Object> get props => [productId];
}

/// تبديل الإعجاب بالمنتج
class ToggleProductLikeEvent extends MarketEvent {
  final String productId;

  ToggleProductLikeEvent({required this.productId});

  @override
  List<Object> get props => [productId];
}

/// إضافة منتج جديد
class AddProductEvent extends MarketEvent {
  final String name;
  final double price;
  final String description;
  final String category;
  final List<File> images;
  final String location;
  final Map<File, Uint8List>? webImageData; // بيانات الصور للويب

  AddProductEvent({
    required this.name,
    required this.price,
    required this.description,
    required this.category,
    required this.images,
    required this.location,
    this.webImageData,
  });

  @override
  List<Object?> get props => [
        name,
        price,
        description,
        category,
        images,
        location,
        webImageData,
      ];
}

/// تحديث منتج موجود
class UpdateProductEvent extends MarketEvent {
  final String productId;
  final String name;
  final double price;
  final String description;
  final String category;
  final String location;
  final List<File>? newImages;

  UpdateProductEvent({
    required this.productId,
    required this.name,
    required this.price,
    required this.description,
    required this.category,
    required this.location,
    this.newImages,
  });

  @override
  List<Object?> get props => [
        productId,
        name,
        price,
        description,
        category,
        location,
        newImages,
      ];
}

/// حذف منتج
class DeleteProductEvent extends MarketEvent {
  final String productId;

  DeleteProductEvent({required this.productId});

  @override
  List<Object> get props => [productId];
}

/// البحث في المنتجات
class SearchProductsEvent extends MarketEvent {
  final String query;
  final String? category;
  final String? location;
  final double? minPrice;
  final double? maxPrice;
  final int? minRating;

  SearchProductsEvent({
    required this.query,
    this.category,
    this.location,
    this.minPrice,
    this.maxPrice,
    this.minRating,
  });

  @override
  List<Object?> get props =>
      [query, category, location, minPrice, maxPrice, minRating];
}

/// إضافة تقييم للمنتج
class AddProductRatingEvent extends MarketEvent {
  final String productId;
  final int rating;
  final String? comment;

  AddProductRatingEvent({
    required this.productId,
    required this.rating,
    this.comment,
  });

  @override
  List<Object?> get props => [productId, rating, comment];
}
