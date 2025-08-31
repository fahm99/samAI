// شاشة السوق - محسنة للأداء والأمان
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:io';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shimmer/shimmer.dart';

import 'package:url_launcher/url_launcher.dart';

import 'package:sam/market/Add_Product.dart';
import 'package:sam/market/Product_Details.dart';
import 'package:sam/market/edit_product.dart';
import 'package:sam/services/supabaseservice.dart';
import 'package:sam/services/agricultural_cache_service.dart';
import 'package:sam/services/offline_manager.dart';
import 'package:sam/services/logger_service.dart';

// ملاحظة: يجب تثبيت الحزم التالية في pubspec.yaml:
// connectivity_plus: ^5.0.2
// shimmer: ^3.0.0
// ثم تشغيل flutter pub get

// Market Models
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

// Market Events
abstract class MarketEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadMarketDataEvent extends MarketEvent {}

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

class LoadMoreProductsEvent extends MarketEvent {
  final String? category;
  final String? location;

  LoadMoreProductsEvent({this.category, this.location});

  @override
  List<Object?> get props => [category, location];
}

class LoadProductDetailsEvent extends MarketEvent {
  final String productId;

  LoadProductDetailsEvent({required this.productId});

  @override
  List<Object> get props => [productId];
}

class ToggleProductLikeEvent extends MarketEvent {
  final String productId;

  ToggleProductLikeEvent({required this.productId});

  @override
  List<Object> get props => [productId];
}

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

class DeleteProductEvent extends MarketEvent {
  final String productId;

  DeleteProductEvent({required this.productId});

  @override
  List<Object> get props => [productId];
}

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

// Market States
abstract class MarketState extends Equatable {
  @override
  List<Object?> get props => [];
}

class MarketInitial extends MarketState {}

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

// تم إزالة MarketLoadedOffline لتبسيط تجربة المستخدم

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

class MarketError extends MarketState {
  final String message;

  MarketError({required this.message});

  @override
  List<Object> get props => [message];
}

class MarketSuccess extends MarketState {
  final String message;

  MarketSuccess({required this.message});

  @override
  List<Object> get props => [message];
}

// Market Bloc - محسن للأداء والتجربة مع التخزين المؤقت
class MarketBloc extends Bloc<MarketEvent, MarketState> {
  final SupabaseService _supabaseService = SupabaseService();
  final AgriculturalCacheService _cacheService = AgriculturalCacheService();

  // تحسين الأداء: إضافة مراقبة الاتصال
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isConnected = true;

  MarketBloc() : super(MarketInitial()) {
    on<LoadMarketDataEvent>(_onLoadMarketData);
    on<LoadProductsEvent>(_onLoadProducts);
    on<LoadMoreProductsEvent>(_onLoadMoreProducts);
    on<LoadProductDetailsEvent>(_onLoadProductDetails);
    on<ToggleProductLikeEvent>(_onToggleProductLike);
    on<AddProductEvent>(_onAddProduct);
    on<UpdateProductEvent>(_onUpdateProduct);
    on<DeleteProductEvent>(_onDeleteProduct);
    on<SearchProductsEvent>(_onSearchProducts,
        transformer: _debounceTransformer());
    on<AddProductRatingEvent>(_onAddProductRating);

    // تحسين الأداء: مراقبة الاتصال بالإنترنت
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((result) {
      _isConnected = !result.contains(ConnectivityResult.none);
      if (_isConnected && state is MarketError) {
        // إعادة تحميل البيانات عند استعادة الاتصال
        add(LoadMarketDataEvent());
      }
    });
  }

  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    EasyDebounce.cancelAll();
    return super.close();
  }

  // تحسين الأداء: Debounce transformer محسن للبحث
  EventTransformer<SearchProductsEvent> _debounceTransformer() {
    return (events, mapper) => events
        .debounceTime(const Duration(milliseconds: 300)) // تقليل وقت التأخير
        .switchMap(mapper); // استخدام switchMap بدلاً من asyncExpand
  }

  Future<void> _onLoadMarketData(
      LoadMarketDataEvent event, Emitter<MarketState> emit) async {
    try {
      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) {
        emit(MarketError(message: 'المستخدم غير مسجل الدخول'));
        return;
      }

      final productsData = await _supabaseService.getMarketProducts(limit: 20);

      List<Product> products = [];
      for (var productData in productsData) {
        final likesCount =
            await _supabaseService.getProductLikesCount(productData['id']);
        final isLiked = await _supabaseService.isProductLiked(
            productData['id'], currentUser.id);
        final averageRating =
            await _supabaseService.getProductAverageRating(productData['id']);
        final ratingsData =
            await _supabaseService.getProductRatings(productData['id']);

        productData['likes_count'] = likesCount;
        productData['is_liked'] = isLiked;
        productData['average_rating'] = averageRating;
        productData['ratings_count'] = ratingsData.length;

        products.add(Product.fromMap(productData));
      }

      final categories = _getCategories();
      final locations = _getLocations();

      emit(MarketLoaded(
        products: products,
        categories: categories,
        locations: locations,
      ));
    } catch (e) {
      emit(MarketError(message: 'خطأ في تحميل بيانات السوق: ${e.toString()}'));
    }
  }

  Future<void> _onLoadProducts(
      LoadProductsEvent event, Emitter<MarketState> emit) async {
    try {
      // Check network connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      _isConnected = !connectivityResult.contains(ConnectivityResult.none);
      _cacheService.updateConnectionStatus(_isConnected);

      // أولاً، عرض البيانات المحفوظة إن وجدت (للاستجابة السريعة)
      final cachedProducts = _cacheService.getCachedProducts();
      final cachedCategories = _cacheService.getCachedCategories();
      final cachedLocations = _cacheService.getCachedLocations();

      if (cachedProducts.isNotEmpty) {
        // تطبيق الفلاتر على البيانات المحفوظة
        var filteredProducts = cachedProducts;
        if (event.category != null && event.category!.isNotEmpty) {
          filteredProducts = filteredProducts
              .where((p) => p.category == event.category)
              .toList();
        }
        if (event.location != null && event.location!.isNotEmpty) {
          filteredProducts = filteredProducts
              .where((p) => p.location == event.location)
              .toList();
        }

        // عرض البيانات المحفوظة فوراً
        emit(MarketLoaded(
          products: filteredProducts,
          categories:
              cachedCategories.isNotEmpty ? cachedCategories : _getCategories(),
          locations:
              cachedLocations.isNotEmpty ? cachedLocations : _getLocations(),
        ));
      }

      // إذا لم يكن هناك اتصال، اكتفِ بالبيانات المحفوظة
      if (!_isConnected) {
        if (cachedProducts.isEmpty) {
          // عرض شاشة فارغة بدلاً من رسالة خطأ
          emit(MarketLoaded(
            products: [],
            categories: _getCategories(),
            locations: _getLocations(),
          ));
        }
        return;
      }

      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) {
        // عرض البيانات المحفوظة إذا وجدت، وإلا عرض شاشة فارغة
        if (cachedProducts.isEmpty) {
          emit(MarketLoaded(
            products: [],
            categories: _getCategories(),
            locations: _getLocations(),
          ));
        }
        return;
      }

      // التحديث الخفي في الخلفية
      _loadAndCacheProductsDataSilently(event).then((_) {
        // إذا لم تكن هناك بيانات محفوظة من قبل، عرض البيانات الجديدة
        if (cachedProducts.isEmpty && !isClosed) {
          final newCachedProducts = _cacheService.getCachedProducts();
          if (newCachedProducts.isNotEmpty) {
            var filteredProducts = newCachedProducts;
            if (event.category != null && event.category!.isNotEmpty) {
              filteredProducts = filteredProducts
                  .where((p) => p.category == event.category)
                  .toList();
            }
            if (event.location != null && event.location!.isNotEmpty) {
              filteredProducts = filteredProducts
                  .where((p) => p.location == event.location)
                  .toList();
            }

            emit(MarketLoaded(
              products: filteredProducts,
              categories: _cacheService.getCachedCategories().isNotEmpty
                  ? _cacheService.getCachedCategories()
                  : _getCategories(),
              locations: _cacheService.getCachedLocations().isNotEmpty
                  ? _cacheService.getCachedLocations()
                  : _getLocations(),
            ));
          }
        }
      }).catchError((e) {
        // في حالة الخطأ، إذا لم تكن هناك بيانات محفوظة، عرض شاشة فارغة
        if (cachedProducts.isEmpty && !isClosed) {
          emit(MarketLoaded(
            products: [],
            categories: _getCategories(),
            locations: _getLocations(),
          ));
        }
        // تسجيل الخطأ فقط دون إظهاره للمستخدم
        debugPrint('خطأ في تحميل منتجات السوق: $e');
      });
    } catch (e) {
      // في حالة الخطأ، عرض شاشة فارغة
      emit(MarketLoaded(
        products: [],
        categories: _getCategories(),
        locations: _getLocations(),
      ));
      debugPrint('خطأ في تحميل منتجات السوق: $e');
    }
  }

  // دالة لتحميل البيانات وحفظها في التخزين المؤقت بشكل خفي
  Future<void> _loadAndCacheProductsDataSilently(
      LoadProductsEvent event) async {
    try {
      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) return;

      // تحميل المنتجات
      final productsData = await _supabaseService
          .getMarketProducts(
            category: event.category,
            location: event.location,
            limit: event.limit,
            offset: (event.page - 1) * event.limit,
          )
          .timeout(const Duration(seconds: 15));

      List<Product> products =
          await _processProductsData(productsData, currentUser.id);

      // حفظ البيانات في التخزين المؤقت مع مدة انتهاء طويلة (24 ساعة)
      if (products.isNotEmpty) {
        _cacheService.smartUpdateProducts(products);
      }

      final categories = _getCategories();
      final locations = _getLocations();

      // حفظ الفئات والمواقع في التخزين المؤقت
      _cacheService.cacheCategories(categories);
      _cacheService.cacheLocations(locations);
    } catch (e) {
      // في حالة فشل التحميل، لا نرمي خطأ بل نتجاهل
      debugPrint('خطأ في تحميل البيانات للتخزين المؤقت: $e');
    }
  }

  // Load more products for pagination
  Future<void> _onLoadMoreProducts(
      LoadMoreProductsEvent event, Emitter<MarketState> emit) async {
    if (state is MarketLoaded) {
      final currentState = state as MarketLoaded;
      if (!currentState.hasMoreProducts || currentState.isLoadingMore) return;

      emit(currentState.copyWith(isLoadingMore: true));

      add(LoadProductsEvent(
        category: event.category,
        location: event.location,
        page: currentState.currentPage + 1,
      ));
    }
  }

  // Helper method to process products data efficiently
  Future<List<Product>> _processProductsData(
      List<dynamic> productsData, String userId) async {
    List<Product> products = [];

    // Process products in batches to improve performance
    for (int i = 0; i < productsData.length; i += 5) {
      final batch = productsData.skip(i).take(5);
      final batchFutures = batch.map((productData) async {
        try {
          final likesCount =
              await _supabaseService.getProductLikesCount(productData['id']);
          final isLiked =
              await _supabaseService.isProductLiked(productData['id'], userId);
          final averageRating =
              await _supabaseService.getProductAverageRating(productData['id']);
          final ratingsData =
              await _supabaseService.getProductRatings(productData['id']);

          productData['likes_count'] = likesCount;
          productData['is_liked'] = isLiked;
          productData['average_rating'] = averageRating;
          productData['ratings_count'] = ratingsData.length;

          return Product.fromMap(productData);
        } catch (e) {
          debugPrint('Error processing product ${productData['id']}: $e');
          return null;
        }
      });

      final batchResults = await Future.wait(batchFutures);
      products.addAll(
          batchResults.where((product) => product != null).cast<Product>());
    }

    return products;
  }

  // Helper method for categories - استخدام قائمة موحدة
  List<String> _getCategories() {
    return _getCategoriesData()
        .map((cat) => cat['value']!)
        .where((value) => value.isNotEmpty)
        .toList();
  }

  // Helper method for locations
  List<String> _getLocations() {
    return [
      'صنعاء',
      'عدن',
      'تعز',
      'الحديدة',
      'إب',
      'ذمار',
      'صعدة',
      'حجة',
      'أخرى',
    ];
  }

  // قائمة التصنيفات الموحدة
  static List<Map<String, String>> _getCategoriesData() {
    return [
      {'name': 'الكل', 'value': '', 'icon': '🏪'},
      {'name': 'خضروات', 'value': 'خضروات', 'icon': '🥬'},
      {'name': 'فواكه', 'value': 'فواكه', 'icon': '🍎'},
      {'name': 'حبوب', 'value': 'حبوب', 'icon': '🌾'},
      {'name': 'بذور', 'value': 'بذور', 'icon': '🌱'},
      {'name': 'أسمدة', 'value': 'أسمدة', 'icon': '🧪'},
      {'name': 'أدوات زراعية', 'value': 'أدوات زراعية', 'icon': '🔧'},
      {'name': 'أخرى', 'value': 'أخرى', 'icon': '📦'},
    ];
  }

  /// معالج محسن للأخطاء مع رسائل واضحة باللغة العربية
  String _getErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('timeout')) {
      return 'انتهت مهلة الاتصال. يرجى المحاولة مجددًا.';
    } else if (errorString.contains('network') ||
        errorString.contains('connection')) {
      return 'خطأ في الشبكة. تحقق من اتصالك بالإنترنت.';
    } else if (errorString.contains('unauthorized') ||
        errorString.contains('401')) {
      return 'انتهت صلاحية الجلسة. يرجى تسجيل الدخول مجددًا.';
    } else if (errorString.contains('forbidden') ||
        errorString.contains('403')) {
      return 'ليس لديك صلاحية للوصول إلى هذا المحتوى.';
    } else if (errorString.contains('not found') ||
        errorString.contains('404')) {
      return 'المحتوى المطلوب غير موجود.';
    } else if (errorString.contains('server') || errorString.contains('500')) {
      return 'خطأ في الخادم. يرجى المحاولة لاحقًا.';
    } else {
      return 'حدث خطأ غير متوقع. يرجى المحاولة مجددًا.';
    }
  }

  Future<void> _onLoadProductDetails(
      LoadProductDetailsEvent event, Emitter<MarketState> emit) async {
    try {
      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) {
        emit(MarketError(message: 'المستخدم غير مسجل الدخول'));
        return;
      }

      final productData =
          await _supabaseService.getProductById(event.productId);
      if (productData == null) {
        emit(MarketError(message: 'المنتج غير موجود'));
        return;
      }

      final likesCount =
          await _supabaseService.getProductLikesCount(event.productId);
      final isLiked = await _supabaseService.isProductLiked(
          event.productId, currentUser.id);
      final averageRating =
          await _supabaseService.getProductAverageRating(event.productId);
      final ratingsData =
          await _supabaseService.getProductRatings(event.productId);

      productData['likes_count'] = likesCount;
      productData['is_liked'] = isLiked;
      productData['average_rating'] = averageRating;
      productData['ratings_count'] = ratingsData.length;

      final product = Product.fromMap(productData);
      final ratings =
          ratingsData.map((data) => ProductRating.fromMap(data)).toList();
      final isOwner = product.userId == currentUser.id;

      emit(ProductDetailsLoaded(
        product: product,
        ratings: ratings,
        isOwner: isOwner,
      ));
    } catch (e) {
      emit(MarketError(message: 'خطأ في تحميل تفاصيل المنتج: ${e.toString()}'));
    }
  }

  Future<void> _onToggleProductLike(
      ToggleProductLikeEvent event, Emitter<MarketState> emit) async {
    try {
      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) {
        emit(MarketError(message: 'المستخدم غير مسجل الدخول'));
        return;
      }

      final success = await _supabaseService.toggleProductLike(
          event.productId, currentUser.id);

      if (success) {
        if (state is MarketLoaded) {
          final currentState = state as MarketLoaded;
          final updatedProducts = currentState.products.map((product) {
            if (product.id == event.productId) {
              final newIsLiked = !product.isLiked;
              final newLikesCount =
                  newIsLiked ? product.likesCount + 1 : product.likesCount - 1;

              return product.copyWith(
                isLiked: newIsLiked,
                likesCount: newLikesCount,
              );
            }
            return product;
          }).toList();

          emit(currentState.copyWith(products: updatedProducts));
        } else if (state is ProductDetailsLoaded) {
          final currentState = state as ProductDetailsLoaded;
          final newIsLiked = !currentState.product.isLiked;
          final newLikesCount = newIsLiked
              ? currentState.product.likesCount + 1
              : currentState.product.likesCount - 1;

          final updatedProduct = currentState.product.copyWith(
            isLiked: newIsLiked,
            likesCount: newLikesCount,
          );

          emit(ProductDetailsLoaded(
            product: updatedProduct,
            ratings: currentState.ratings,
            isOwner: currentState.isOwner,
          ));
        }
      }
    } catch (e) {
      emit(MarketError(message: 'خطأ في تحديث الإعجاب: ${e.toString()}'));
    }
  }

  Future<void> _onAddProduct(
      AddProductEvent event, Emitter<MarketState> emit) async {
    try {
      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) {
        emit(MarketError(message: 'المستخدم غير مسجل الدخول'));
        return;
      }

      List<String> imageUrls = [];
      for (int i = 0; i < event.images.length; i++) {
        final fileName =
            'product_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final path = '${currentUser.id}/$fileName'; // إضافة مجلد المستخدم

        String? imageUrl;
        if (kIsWeb && event.webImageData != null) {
          // في الويب، نستخدم البايتات المضغوطة المرسلة
          final imageBytes = event.webImageData![event.images[i]];
          if (imageBytes != null) {
            imageUrl = await _supabaseService.uploadFileWeb(
              'productimages',
              path,
              imageBytes,
            );
          }
        } else {
          // في المحمول، نستخدم الطريقة العادية
          imageUrl = await _supabaseService.uploadFile(
            'productimages',
            path,
            event.images[i],
          );
        }

        if (imageUrl != null) {
          imageUrls.add(imageUrl);
        }
      }

      final productData = {
        'user_id': currentUser.id,
        'name': event.name,
        'price': event.price.toDouble(), // تأكد من أن السعر double
        'description': event.description,
        'category': event.category,
        'image_urls': imageUrls,
        'location': event.location,
        'is_active': true,
      };

      final success = await _supabaseService.addProduct(productData);

      if (success) {
        emit(MarketSuccess(message: 'تم إضافة المنتج بنجاح'));
        add(LoadProductsEvent());
      } else {
        emit(MarketError(message: 'فشل في إضافة المنتج'));
      }
    } catch (e) {
      emit(MarketError(message: 'خطأ في إضافة المنتج: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateProduct(
      UpdateProductEvent event, Emitter<MarketState> emit) async {
    try {
      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) {
        emit(MarketError(message: 'المستخدم غير مسجل الدخول'));
        return;
      }

      Map<String, dynamic> updateData = {
        'name': event.name,
        'price': event.price.toDouble(), // تأكد من أن السعر double
        'description': event.description,
        'category': event.category,
        'location': event.location,
      };

      if (event.newImages != null && event.newImages!.isNotEmpty) {
        List<String> imageUrls = [];
        for (int i = 0; i < event.newImages!.length; i++) {
          final fileName =
              'product_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
          final path =
              '${_supabaseService.currentUser?.id}/$fileName'; // إضافة مجلد المستخدم
          final imageUrl = await _supabaseService.uploadFile(
            'productimages',
            path,
            event.newImages![i],
          );

          if (imageUrl != null) {
            imageUrls.add(imageUrl);
          }
        }
        updateData['image_urls'] = imageUrls;
      }

      final success =
          await _supabaseService.updateProduct(event.productId, updateData);

      if (success) {
        emit(MarketSuccess(message: 'تم تحديث المنتج بنجاح'));
        add(LoadProductDetailsEvent(productId: event.productId));
      } else {
        emit(MarketError(message: 'فشل في تحديث المنتج'));
      }
    } catch (e) {
      emit(MarketError(message: 'خطأ في تحديث المنتج: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteProduct(
      DeleteProductEvent event, Emitter<MarketState> emit) async {
    try {
      final success = await _supabaseService.deleteProduct(event.productId);

      if (success) {
        emit(MarketSuccess(message: 'تم حذف المنتج بنجاح'));
        add(LoadProductsEvent());
      } else {
        emit(MarketError(message: 'فشل في حذف المنتج'));
      }
    } catch (e) {
      emit(MarketError(message: 'خطأ في حذف المنتج: ${e.toString()}'));
    }
  }

  /// البحث المحسن في المنتجات مع الفلاتر
  Future<void> _onSearchProducts(
      SearchProductsEvent event, Emitter<MarketState> emit) async {
    try {
      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) {
        emit(MarketError(message: 'المستخدم غير مسجل الدخول'));
        return;
      }

      if (event.query.isEmpty) {
        // إذا كان البحث فارغ، أعد تحميل المنتجات مع الفلاتر المطبقة
        add(LoadProductsEvent(
          category: event.category,
          location: event.location,
          isRefresh: true,
        ));
        return;
      }

      // البحث في قاعدة البيانات مع تطبيق الفلاتر
      final searchResults = await _supabaseService.searchProducts(
        searchTerm: event.query,
        category: event.category,
        location: event.location,
        limit: 50,
      );

      // معالجة النتائج وإضافة البيانات الإضافية
      List<Product> products =
          await _processProductsData(searchResults, currentUser.id);

      // تطبيق فلاتر السعر والتقييم محلياً
      if (event.minPrice != null ||
          event.maxPrice != null ||
          event.minRating != null) {
        products = _applyLocalFilters(
            products, event.minPrice, event.maxPrice, event.minRating);
      }

      if (state is MarketLoaded) {
        final currentState = state as MarketLoaded;
        emit(currentState.copyWith(
          products: products,
          hasMoreProducts: false, // البحث لا يدعم التصفح
          currentPage: 1,
        ));
      } else {
        // إذا لم تكن الحالة محملة، أنشئ حالة جديدة
        final categories = _getCategories();
        final locations = _getLocations();

        emit(MarketLoaded(
          products: products,
          categories: categories,
          locations: locations,
          hasMoreProducts: false,
          currentPage: 1,
        ));
      }
    } catch (e) {
      emit(MarketError(message: _getErrorMessage(e)));
    }
  }

  /// تطبيق الفلاتر المحلية على قائمة المنتجات
  List<Product> _applyLocalFilters(
    List<Product> products,
    double? minPrice,
    double? maxPrice,
    int? minRating,
  ) {
    return products.where((product) {
      // فلتر السعر
      if (minPrice != null && product.price < minPrice) return false;
      if (maxPrice != null && product.price > maxPrice) return false;

      // فلتر التقييم (يمكن إضافة منطق التقييم هنا عند توفره)
      if (minRating != null) {
        // TODO: إضافة منطق فلتر التقييم عند توفر بيانات التقييم
      }

      return true;
    }).toList();
  }

  Future<void> _onAddProductRating(
      AddProductRatingEvent event, Emitter<MarketState> emit) async {
    try {
      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) {
        emit(MarketError(message: 'المستخدم غير مسجل الدخول'));
        return;
      }

      final ratingData = {
        'product_id': event.productId,
        'user_id': currentUser.id,
        'rating': event.rating,
        'comment': event.comment,
      };

      final success = await _supabaseService.addProductRating(ratingData);

      if (success) {
        emit(MarketSuccess(message: 'تم إضافة التقييم بنجاح'));
        add(LoadProductDetailsEvent(productId: event.productId));
      } else {
        emit(MarketError(message: 'فشل في إضافة التقييم'));
      }
    } catch (e) {
      emit(MarketError(message: 'خطأ في إضافة التقييم: ${e.toString()}'));
    }
  }
}

// Market Screen
/// شاشة السوق الزراعي - تعرض المنتجات الزراعية مع إمكانيات البحث والفلترة
/// تستخدم نمط BLoC لإدارة الحالة مع تحسينات الأداء مثل lazy loading و debouncing
class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen>
    with
        AutomaticKeepAliveClientMixin,
        TickerProviderStateMixin,
        WidgetsBindingObserver,
        RouteAware,
        OfflineMixin {
  late final TextEditingController _searchController;
  late final Debouncer _debouncer;
  late final ScrollController _scrollController;
  String? _selectedCategory;
  String? _selectedLocation;
  late final ValueNotifier<bool> _isConnected;

  // متغيرات الفلاتر المحسنة
  double? _minPrice;
  double? _maxPrice;
  int? _minRating;
  int _filteredProductsCount = 0;

  // استخدام قائمة التصنيفات الموحدة
  List<Map<String, String>> get _categories => MarketBloc._getCategoriesData();

  // تحسين الأداء: إضافة AnimationController للانتقالات السلسة
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  // تحسين الأداء: إضافة Pagination
  bool _isLoadingMore = false;
  final bool _hasMoreData = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // إضافة مراقب دورة الحياة

    _searchController = TextEditingController();
    _debouncer = Debouncer(milliseconds: 300); // تحسين سرعة البحث
    _scrollController = ScrollController();
    _isConnected = ValueNotifier(true);

    // تهيئة الرسوم المتحركة
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _checkConnectivity();
    _setupScrollListener();

    // Add search listener with debouncing
    _searchController.addListener(() {
      _debouncer.run(() {
        if (_searchController.text.isNotEmpty) {
          EasyDebounce.debounce(
            'market-search',
            const Duration(milliseconds: 500),
            () => context.read<MarketBloc>().add(SearchProductsEvent(
                  query: _searchController.text,
                  category: _selectedCategory,
                  location: _selectedLocation,
                  minPrice: _minPrice,
                  maxPrice: _maxPrice,
                  minRating: _minRating,
                )),
          );
        } else {
          // Load all products when search is cleared
          context.read<MarketBloc>().add(LoadProductsEvent(
                category: _selectedCategory,
                location: _selectedLocation,
                isRefresh: true,
              ));
        }
      });
    });

    SchedulerBinding.instance.addPostFrameCallback((_) {
      context.read<MarketBloc>().add(LoadMarketDataEvent());
      _animationController.forward();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // إعادة تحميل البيانات عند العودة للشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshDataIfNeeded();
    });
  }

  /// إعادة تحميل البيانات إذا لزم الأمر
  void _refreshDataIfNeeded() {
    if (!mounted) return;

    final bloc = context.read<MarketBloc>();
    final currentState = bloc.state;

    // إعادة تحميل البيانات في الحالات التالية:
    // 1. الحالة الأولية
    // 2. حالة خطأ
    // 3. البيانات فارغة
    // 4. البيانات قديمة (أكثر من 5 دقائق)
    bool shouldRefresh = false;

    if (currentState is MarketInitial || currentState is MarketError) {
      shouldRefresh = true;
    } else if (currentState is MarketLoaded) {
      if (currentState.products.isEmpty) {
        shouldRefresh = true;
      }
      // يمكن إضافة فحص الوقت هنا إذا لزم الأمر
    }

    if (shouldRefresh) {
      bloc.add(LoadMarketDataEvent());
    }
  }

  /// إعادة تحميل بيانات السوق
  void _refreshMarketData() {
    context.read<MarketBloc>().add(LoadProductsEvent(
          category: _selectedCategory,
          location: _selectedLocation,
          isRefresh: true,
        ));
  }

  // تحسين الأداء: إعداد مستمع التمرير للـ Infinite Scroll
  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        // تحميل المزيد من المنتجات عند الوصول لنهاية القائمة
        if (!_isLoadingMore && _hasMoreData) {
          setState(() {
            _isLoadingMore = true;
          });
          context.read<MarketBloc>().add(LoadMoreProductsEvent());
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // إزالة مراقب دورة الحياة
    _searchController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    _isConnected.dispose();
    EasyDebounce.cancelAll();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // إعادة تحميل البيانات عند العودة للتطبيق
    if (state == AppLifecycleState.resumed) {
      _refreshDataIfNeeded();
    }
  }

  @override
  void didPopNext() {
    super.didPopNext();
    // إعادة تحميل البيانات عند العودة من شاشة أخرى
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _refreshMarketData();
      }
    });
  }

  Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    _isConnected.value = !connectivityResult.contains(ConnectivityResult.none);
    Connectivity().onConnectivityChanged.listen((result) {
      _isConnected.value = !result.contains(ConnectivityResult.none);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // فحص إضافي لضمان وجود البيانات عند بناء الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final currentState = context.read<MarketBloc>().state;
        if (currentState is MarketLoaded && currentState.products.isEmpty) {
          _refreshMarketData();
        }
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // مؤشر الوضع غير المتصل
            // تم إزالة مؤشر حالة الاتصال لتحسين تجربة المستخدم
            const SizedBox.shrink(),

            Expanded(
              child: BlocListener<MarketBloc, MarketState>(
                listener: (context, state) {
                  if (state is MarketSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                },
                child: Column(
                  children: [
                    // شريط البحث والفلترة المحسن
                    _buildEnhancedSearchAndFilters(),
                    // قائمة المنتجات
                    Expanded(
                      child: _buildProductsTab(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "market_fab",
        onPressed: () => _showAddProductDialog(),
        backgroundColor: const Color(0xFF2E7D32),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // شريط البحث والتصنيفات المحسن - تصميم نظيف ومنظم
  Widget _buildEnhancedSearchAndFilters() {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SingleChildScrollView(
        child: Column(
          children: [
            // شريط البحث منفصل وواضح
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor.withOpacity(0.08),
                    spreadRadius: 0,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                decoration: InputDecoration(
                  hintText: 'ابحث عن المنتجات والخدمات...',
                  hintStyle: TextStyle(
                    color: Theme.of(context).hintColor.withOpacity(0.7),
                    fontSize: 15,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: _searchController.text.isNotEmpty
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).hintColor,
                    size: 22,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear_rounded,
                            color: Theme.of(context).hintColor,
                            size: 20,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            _applyFiltersAndRefresh();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                onChanged: (value) {
                  setState(() {}); // لتحديث أيقونة المسح
                  EasyDebounce.debounce(
                    'market-search-optimized',
                    const Duration(milliseconds: 300),
                    () {
                      if (mounted) {
                        context.read<MarketBloc>().add(
                              SearchProductsEvent(
                                query: value,
                                category: _selectedCategory,
                                location: _selectedLocation,
                                minPrice: _minPrice,
                                maxPrice: _maxPrice,
                                minRating: _minRating,
                              ),
                            );
                      }
                    },
                  );
                },
              ),
            ),

            // فلاتر في صف واحد - النوع، السعر، الموقع، التقييم، الترتيب
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // زر فلتر النوع
                  Expanded(
                    child: _buildCompactFilterButton(
                      icon: Icons.category,
                      label: _getSelectedCategoryName(),
                      isActive: _selectedCategory != null,
                      onTap: () => _showCategoryFilter(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // زر فلتر السعر
                  Expanded(
                    child: _buildCompactFilterButton(
                      icon: Icons.attach_money,
                      label: 'السعر',
                      isActive: _minPrice != null || _maxPrice != null,
                      onTap: () => _showPriceFilter(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // زر فلتر الموقع
                  Expanded(
                    child: _buildCompactFilterButton(
                      icon: Icons.location_on,
                      label: _selectedLocation ?? 'الموقع',
                      isActive: _selectedLocation != null,
                      onTap: () => _showLocationFilter(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // زر فلتر التقييم
                  Expanded(
                    child: _buildCompactFilterButton(
                      icon: Icons.star,
                      label: 'التقييم',
                      isActive: _minRating != null,
                      onTap: () => _showRatingFilter(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // زر الترتيب
                  Expanded(
                    child: _buildCompactFilterButton(
                      icon: Icons.sort,
                      label: 'ترتيب',
                      onTap: () => _showSortOptions(context),
                    ),
                  ),
                ],
              ),
            ),

            // زر إعادة تعيين الفلاتر (يظهر فقط عند وجود فلاتر نشطة)
            if (_hasActiveFilters())
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                Theme.of(context).primaryColor.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'عدد النتائج: $_filteredProductsCount',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            GestureDetector(
                              onTap: _resetAllFilters,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'مسح الكل',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // خط فاصل
            Container(
              height: 1,
              color: Theme.of(context).dividerColor.withOpacity(0.1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsTab() {
    return BlocBuilder<MarketBloc, MarketState>(
      builder: (context, state) {
        if (state is MarketLoaded) {
          final products = state.products;

          if (products.isEmpty) {
            // فحص ما إذا كانت هذه المرة الأولى (لا توجد بيانات محفوظة)
            final cacheService = AgriculturalCacheService();
            final cachedProducts = cacheService.getCachedProducts();
            if (cachedProducts.isEmpty) {
              // عرض Shimmer للتحميل الأولي
              return _buildMarketShimmer();
            } else {
              // عرض شاشة فارغة إذا كانت هناك بيانات محفوظة لكنها فارغة
              return _buildEmptyState();
            }
          }
          // تحديث عدد النتائج
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _updateFilteredProductsCount(products.length);
          });

          return RefreshIndicator(
            onRefresh: () async {
              EasyDebounce.debounce(
                'market-refresh',
                const Duration(milliseconds: 1000),
                () => _applyFiltersAndRefresh(),
              );
            },
            child: NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification scrollInfo) {
                // Implement lazy loading when user scrolls near the end (only for online mode)
                if (state is MarketLoaded &&
                    scrollInfo.metrics.pixels ==
                        scrollInfo.metrics.maxScrollExtent &&
                    state.hasMoreProducts &&
                    !state.isLoadingMore) {
                  context.read<MarketBloc>().add(LoadMoreProductsEvent(
                        category: _selectedCategory,
                        location: _selectedLocation,
                      ));
                }
                return false;
              },
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // تحديد نوع التخطيط حسب عرض الشاشة
                  if (constraints.maxWidth > 600) {
                    // استخدام GridView للشاشات الكبيرة
                    int crossAxisCount = constraints.maxWidth > 900 ? 3 : 2;
                    return RefreshIndicator(
                      onRefresh: () async {
                        context.read<MarketBloc>().add(LoadProductsEvent());
                        // انتظار قصير للسماح للـ Bloc بالتحديث
                        await Future.delayed(const Duration(milliseconds: 500));
                      },
                      child: GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: products.length +
                            (state is MarketLoaded && state.isLoadingMore
                                ? 1
                                : 0),
                        itemBuilder: (context, index) {
                          if (index >= products.length) {
                            return _buildProductShimmerCard();
                          }
                          final product = products[index];
                          return _buildProductCard(product);
                        },
                      ),
                    );
                  } else {
                    // استخدام ListView للشاشات الصغيرة
                    return RefreshIndicator(
                      onRefresh: () async {
                        context.read<MarketBloc>().add(LoadProductsEvent());
                        await Future.delayed(const Duration(milliseconds: 500));
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
                        itemCount: products.length +
                            (state is MarketLoaded && state.isLoadingMore
                                ? 1
                                : 0),
                        itemBuilder: (context, index) {
                          if (index >= products.length) {
                            return Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: _buildProductShimmerCard(),
                            );
                          }
                          final product = products[index];
                          return _buildProductCard(product);
                        },
                      ),
                    );
                  }
                },
              ),
            ),
          );
        }
        // عرض Shimmer للتحميل الأولي
        return _buildMarketShimmer();
      },
    );
  }

  Widget _buildProductCard(Product product) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // معلومات البائع (مثل Facebook)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // صورة البائع
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFF2E7D32),
                    backgroundImage: product.sellerAvatar != null
                        ? CachedNetworkImageProvider(product.sellerAvatar!)
                        : null,
                    child: product.sellerAvatar == null
                        ? const Icon(Icons.person,
                            color: Colors.white, size: 20)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  // معلومات البائع
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.sellerName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.location_on,
                                size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                product.location,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // قائمة الخيارات
                  Builder(
                    builder: (context) => IconButton(
                      icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                      onPressed: () =>
                          _showProductOptionsMenu(context, product),
                    ),
                  ),
                ],
              ),
            ),

            // نص المنتج
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (product.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    ExpandableDescription(description: product.description),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 8),

            // صورة المنتج (أكبر مثل Facebook)
            GestureDetector(
              onTap: () => _navigateToProductDetails(context, product),
              child: SizedBox(
                width: double.infinity,
                height: 250,
                child: product.imageUrls.isNotEmpty &&
                        product.imageUrls.first != ''
                    ? CachedNetworkImage(
                        imageUrl: product.imageUrls.first,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            color: Colors.white,
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[200],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image_not_supported,
                                  size: 50, color: Colors.grey[400]),
                              const SizedBox(height: 8),
                              Text('لا توجد صورة',
                                  style: TextStyle(color: Colors.grey[600])),
                            ],
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image,
                                size: 50, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text('لا توجد صورة',
                                style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                      ),
              ),
            ),

            // معلومات السعر والتفاصيل
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // السعر والوحدة
                  Row(
                    children: [
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${product.price.toStringAsFixed(0)} ريال',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // التقييم والفئة
                  Row(
                    children: [
                      // التقييم
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star,
                                size: 16, color: Colors.orange),
                            const SizedBox(width: 4),
                            Text(
                              product.averageRating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              ' (${product.ratingsCount})',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // الفئة
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            product.category,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // خط فاصل
            Divider(height: 1, color: Colors.grey[200]),

            // أزرار التفاعل (مثل Facebook)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                children: [
                  // زر الإعجاب
                  Expanded(
                    child: _buildActionButton(
                      icon: product.isLiked
                          ? Icons.favorite
                          : Icons.favorite_border,
                      label: 'إعجاب (${product.likesCount})',
                      color: product.isLiked ? Colors.red : Colors.grey[600]!,
                      onTap: () {
                        context.read<MarketBloc>().add(
                              ToggleProductLikeEvent(productId: product.id),
                            );
                      },
                    ),
                  ),
                  // زر التواصل
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.phone,
                      label: 'تواصل',
                      color: _isCurrentUserOwner(product)
                          ? Colors.grey[400]!
                          : Colors.grey[600]!,
                      onTap: _isCurrentUserOwner(product)
                          ? null
                          : () => _contactSeller(context, product),
                    ),
                  ),
                  // زر الطلب (بدلاً من المشاركة)
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.shopping_cart_outlined,
                      label: 'طلب',
                      color: _isCurrentUserOwner(product)
                          ? Colors.grey[400]!
                          : const Color(0xFF2E7D32),
                      onTap: _isCurrentUserOwner(product)
                          ? null
                          : () => _requestProduct(context, product),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // دالة بناء زر التفاعل
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap, // جعل onTap اختياري
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1.0, // تقليل الشفافية عند التعطيل
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // دالة الانتقال لتفاصيل المنتج
  void _navigateToProductDetails(BuildContext context, Product product) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailsScreen(productId: product.id),
      ),
    );

    // إعادة تحميل البيانات دائماً عند العودة من شاشة التفاصيل
    // هذا يضمن أن البيانات محدثة حتى لو لم يحدث تغيير
    _refreshMarketData();
  }

  // دالة عرض خيارات المنتج مع موضع محسن
  void _showProductOptionsMenu(BuildContext context, Product product) {
    final currentUser = SupabaseService().currentUser;
    final isOwner = currentUser?.id == product.userId;

    // الحصول على موضع الزر
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;

    final Offset buttonPosition =
        button.localToGlobal(Offset.zero, ancestor: overlay);
    final Size buttonSize = button.size;

    // حساب الموضع المناسب للقائمة
    final double menuWidth = 180;
    final double left = buttonPosition.dx -
        menuWidth +
        buttonSize.width; // محاذاة يمين القائمة مع يمين الزر
    final double top =
        buttonPosition.dy + buttonSize.height + 4; // تحت الزر مع مسافة صغيرة

    final RelativeRect position = RelativeRect.fromLTRB(
      left,
      top,
      left + menuWidth,
      top + 300, // ارتفاع كافي للقائمة
    );

    showMenu<String>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 8,
      color: Colors.white,
      items: isOwner ? _buildOwnerMenuItems() : _buildUserMenuItems(),
    ).then((value) {
      if (value != null) {
        _handleMenuAction(context, product, value);
      }
    });
  }

  // بناء عناصر القائمة لمالك المنتج
  List<PopupMenuEntry<String>> _buildOwnerMenuItems() {
    return [
      PopupMenuItem<String>(
        value: 'view',
        height: 48,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.visibility, color: Colors.blue[600], size: 18),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'عرض التفاصيل',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: 'edit',
        height: 48,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.edit, color: Colors.orange[600], size: 18),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'تعديل المنتج',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: 'delete',
        height: 48,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.delete, color: Colors.red[600], size: 18),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'حذف المنتج',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
      const PopupMenuDivider(),
      PopupMenuItem<String>(
        value: 'share',
        height: 48,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.share, color: Colors.green[600], size: 18),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'مشاركة المنتج',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  // بناء عناصر القائمة للمستخدم العادي
  List<PopupMenuEntry<String>> _buildUserMenuItems() {
    return [
      PopupMenuItem<String>(
        value: 'view',
        height: 48,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.visibility, color: Colors.blue[600], size: 18),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'عرض التفاصيل',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: 'chat',
        height: 48,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.phone, color: Colors.green[600], size: 18),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'تواصل مع البائع',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: 'share',
        height: 48,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.share, color: Colors.orange[600], size: 18),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'مشاركة المنتج',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
      const PopupMenuDivider(),
      PopupMenuItem<String>(
        value: 'report',
        height: 48,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.report, color: Colors.red[600], size: 18),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'الإبلاغ عن المنتج',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  // معالجة إجراءات القائمة
  void _handleMenuAction(BuildContext context, Product product, String action) {
    switch (action) {
      case 'view':
        _navigateToProductDetails(context, product);
        break;
      case 'edit':
        _editProduct(context, product);
        break;
      case 'delete':
        _confirmDeleteProduct(context, product);
        break;
      case 'chat':
        _contactSeller(context, product);
        break;
      case 'share':
        _shareProduct(context, product);
        break;
      case 'report':
        _reportProduct(context, product);
        break;
    }
  }

  // دالة تعديل المنتج
  void _editProduct(BuildContext context, Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProductScreen(product: product),
      ),
    );
  }

  // دالة تأكيد حذف المنتج
  void _confirmDeleteProduct(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف المنتج "${product.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<MarketBloc>().add(
                    DeleteProductEvent(productId: product.id),
                  );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  // دالة التواصل الخارجي مع البائع
  void _contactSeller(BuildContext context, Product product) async {
    // عرض مؤشر التحميل بـ Shimmer
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );

    try {
      // جلب معلومات البائع من قاعدة البيانات
      final sellerData = await SupabaseService().getUserProfile(product.userId);

      // إخفاء مؤشر التحميل
      Navigator.of(context).pop();

      if (sellerData == null) {
        _showContactErrorDialog(context, 'لا يمكن العثور على معلومات البائع');
        return;
      }

      final whatsappNumber = sellerData['whatsapp_number'] as String?;
      final phoneNumber = sellerData['phone_number'] as String?;

      // إنشاء رسالة WhatsApp جاهزة
      final message = 'مرحباً، أهتم بمنتجك: ${product.name}';

      // إذا كان كلا الرقمين متوفرين، اعرض خيارات
      if ((whatsappNumber != null && whatsappNumber.isNotEmpty) &&
          (phoneNumber != null && phoneNumber.isNotEmpty)) {
        _showContactOptionsDialog(
            context, whatsappNumber, phoneNumber, message);
      } else if (whatsappNumber != null && whatsappNumber.isNotEmpty) {
        _openWhatsApp(context, whatsappNumber, message);
      } else if (phoneNumber != null && phoneNumber.isNotEmpty) {
        _makePhoneCall(context, phoneNumber);
      } else {
        _showContactErrorDialog(context, 'لا توجد معلومات تواصل متاحة للبائع');
      }
    } catch (e) {
      // إخفاء مؤشر التحميل في حالة الخطأ
      Navigator.of(context).pop();
      _showContactErrorDialog(context, 'خطأ في جلب معلومات البائع');
    }
  }

  // عرض خيارات التواصل عندما يكون كلا الرقمين متوفرين
  void _showContactOptionsDialog(BuildContext context, String whatsappNumber,
      String phoneNumber, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اختر طريقة التواصل'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.chat, color: Colors.green[600]),
              title: const Text('WhatsApp'),
              subtitle: Text(whatsappNumber),
              onTap: () {
                Navigator.of(context).pop();
                _openWhatsApp(context, whatsappNumber, message);
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.phone, color: Colors.blue[600]),
              title: const Text('مكالمة هاتفية'),
              subtitle: Text(phoneNumber),
              onTap: () {
                Navigator.of(context).pop();
                _makePhoneCall(context, phoneNumber);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }

  // عرض رسالة خطأ مع خيارات بديلة
  void _showContactErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعذر التواصل'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            const SizedBox(height: 16),
            const Text(
              'يمكنك المحاولة لاحقاً أو التواصل مع البائع بطريقة أخرى.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }

  // فتح WhatsApp
  void _openWhatsApp(
      BuildContext context, String phoneNumber, String message) async {
    try {
      // تنظيف رقم الهاتف (إزالة المسافات والرموز غير المرغوبة)
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      final url =
          'https://wa.me/$cleanNumber?text=${Uri.encodeComponent(message)}';

      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

        // عرض رسالة نجاح
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم فتح WhatsApp بنجاح'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        _showWhatsAppNotInstalledDialog(context, cleanNumber);
      }
    } catch (e) {
      _showContactErrorDialog(
          context, 'خطأ في فتح WhatsApp. تأكد من تثبيت التطبيق.');
    }
  }

  // إجراء مكالمة هاتفية
  void _makePhoneCall(BuildContext context, String phoneNumber) async {
    try {
      // تنظيف رقم الهاتف
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      final url = 'tel:$cleanNumber';

      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));

        // عرض رسالة نجاح
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم بدء المكالمة'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        _showContactErrorDialog(
            context, 'لا يمكن إجراء المكالمة من هذا الجهاز');
      }
    } catch (e) {
      _showContactErrorDialog(context, 'خطأ في إجراء المكالمة');
    }
  }

  // عرض حوار عندما لا يكون WhatsApp مثبتاً
  void _showWhatsAppNotInstalledDialog(
      BuildContext context, String phoneNumber) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('WhatsApp غير مثبت'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('تطبيق WhatsApp غير مثبت على جهازك.'),
            const SizedBox(height: 16),
            const Text('يمكنك:'),
            const SizedBox(height: 8),
            const Row(
              children: [
                Text('• تثبيت WhatsApp من متجر التطبيقات'),
              ],
            ),
            Row(
              children: [
                Text('• الاتصال مباشرة على: $phoneNumber'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _makePhoneCall(context, phoneNumber);
            },
            child: const Text('اتصال'),
          ),
        ],
      ),
    );
  }

  /// مشاركة المنتج عبر منصات التواصل الاجتماعي
  /// يتيح للمستخدم مشاركة تفاصيل المنتج مع الآخرين
  void _shareProduct(BuildContext context, Product product) {
    logger.userAction('مشاركة منتج',
        context: {'productId': product.id, 'productName': product.name});

    // إنشاء نص المشاركة
    final shareText = '''
🌱 منتج زراعي متميز من تطبيق حصادAI

📦 ${product.name}
💰 السعر: ${product.price} ريال
📍 الموقع: ${product.location ?? 'غير محدد'}
📝 ${product.description.isNotEmpty ? product.description : 'منتج زراعي عالي الجودة'}

#حصادAI #زراعة #منتجات_زراعية
    '''
        .trim();

    // عرض خيارات المشاركة
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'مشاركة المنتج',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('نسخ النص'),
              onTap: () {
                // نسخ النص إلى الحافظة
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم نسخ تفاصيل المنتج'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('مشاركة عامة'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('سيتم تفعيل المشاركة في التحديث القادم'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // دالة الإبلاغ عن المنتج
  void _reportProduct(BuildContext context, Product product) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('سيتم تطبيق الإبلاغ قريباً'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// دالة طلب المنتج (بدلاً من المشاركة)
  void _requestProduct(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('طلب المنتج'),
        content: const Text('سيتم إضافة خدمة الطلب قريباً'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }

  /// التحقق من أن المستخدم الحالي هو صاحب المنتج
  bool _isCurrentUserOwner(Product product) {
    final currentUser = SupabaseService().currentUser;
    return currentUser?.id == product.userId;
  }

  /// تطبيق فلتر السعر
  void _applyPriceFilter(double minPrice, double maxPrice) {
    setState(() {
      _minPrice = minPrice;
      _maxPrice = maxPrice == double.infinity ? null : maxPrice;
    });

    _applyFiltersAndRefresh();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'فلتر السعر: ${minPrice.toInt()} - ${maxPrice == double.infinity ? "∞" : maxPrice.toInt()} ريال'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// تطبيق فلتر التقييم
  void _applyRatingFilter(int minRating) {
    setState(() {
      _minRating = minRating;
    });

    _applyFiltersAndRefresh();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('فلتر التقييم: $minRating نجوم فأكثر'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// تطبيق خيار الترتيب
  void _applySortOption(String sortBy, bool ascending) {
    context.read<MarketBloc>().add(LoadProductsEvent(
          category: _selectedCategory,
          location: _selectedLocation,
          isRefresh: true,
        ));

    String sortText = '';
    switch (sortBy) {
      case 'created_at':
        sortText = 'الأحدث أولاً';
        break;
      case 'price':
        sortText =
            ascending ? 'السعر من الأقل للأعلى' : 'السعر من الأعلى للأقل';
        break;
      case 'rating':
        sortText = 'الأعلى تقييماً';
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ترتيب: $sortText'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // دالة بناء زر الفلتر المدمج
  Widget _buildCompactFilterButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isActive
                ? Theme.of(context).primaryColor.withOpacity(0.3)
                : Theme.of(context).dividerColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).hintColor,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isActive
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).textTheme.bodySmall?.color,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // دالة عرض فلتر النوع
  void _showCategoryFilter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Text(
                      'فلترة حسب النوع',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close,
                        color: Theme.of(context).iconTheme.color,
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable content
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isSelected = _selectedCategory == category['value'];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).primaryColor.withOpacity(0.1)
                            : Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Theme.of(context).dividerColor.withOpacity(0.3),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.2)
                                : Theme.of(context).scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              category['icon']!,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                        title: Text(
                          category['name']!,
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(
                                Icons.check_circle,
                                color: Theme.of(context).primaryColor,
                                size: 24,
                              )
                            : Icon(
                                Icons.radio_button_unchecked,
                                color: Theme.of(context).dividerColor,
                                size: 24,
                              ),
                        onTap: () {
                          Navigator.pop(context);
                          _applyCategoryFilter(category['value']!);
                        },
                      ),
                    );
                  },
                ),
              ),

              // Bottom padding
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // دالة للحصول على اسم التصنيف المحدد
  String _getSelectedCategoryName() {
    if (_selectedCategory == null) return 'النوع';
    final category = _categories.firstWhere(
      (cat) => cat['value'] == _selectedCategory,
      orElse: () => {'name': 'النوع', 'icon': '🏪'},
    );
    return '${category['icon']} ${category['name']}';
  }

  // دالة للتحقق من وجود فلاتر نشطة
  bool _hasActiveFilters() {
    return _selectedCategory != null ||
        _selectedLocation != null ||
        _minPrice != null ||
        _maxPrice != null ||
        _minRating != null;
  }

  // دالة إعادة تعيين جميع الفلاتر
  void _resetAllFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedLocation = null;
      _minPrice = null;
      _maxPrice = null;
      _minRating = null;
      _filteredProductsCount = 0;
    });

    // إعادة تحميل جميع المنتجات
    context.read<MarketBloc>().add(LoadProductsEvent(isRefresh: true));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم إعادة تعيين جميع الفلاتر'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // تطبيق فلتر النوع
  void _applyCategoryFilter(String category) {
    setState(() {
      _selectedCategory = category.isEmpty ? null : category;
    });

    _applyFiltersAndRefresh();

    final categoryName = _getSelectedCategoryName();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('فلتر النوع: $categoryName'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // دالة موحدة لتطبيق الفلاتر وإعادة التحميل
  void _applyFiltersAndRefresh() {
    if (_searchController.text.isNotEmpty) {
      // إذا كان هناك بحث نشط، طبق البحث مع الفلاتر
      context.read<MarketBloc>().add(SearchProductsEvent(
            query: _searchController.text,
            category: _selectedCategory,
            location: _selectedLocation,
            minPrice: _minPrice,
            maxPrice: _maxPrice,
            minRating: _minRating,
          ));
    } else {
      // إذا لم يكن هناك بحث، طبق الفلاتر على جميع المنتجات
      context.read<MarketBloc>().add(LoadProductsEvent(
            category: _selectedCategory,
            location: _selectedLocation,
            isRefresh: true,
          ));
    }
  }

  // تحديث عدد النتائج المفلترة
  void _updateFilteredProductsCount(int count) {
    setState(() {
      _filteredProductsCount = count;
    });
  }

  // بناء حالة عدم وجود نتائج
  Widget _buildEmptyState() {
    final hasSearch = _searchController.text.isNotEmpty;
    final hasFilters = _hasActiveFilters();

    IconData icon;
    String title;
    String subtitle;
    List<Widget> actions = [];

    if (hasSearch && hasFilters) {
      icon = Icons.search_off;
      title = 'لا توجد نتائج للبحث والفلاتر';
      subtitle = 'جرب تعديل كلمات البحث أو إزالة بعض الفلاتر';
      actions = [
        ElevatedButton.icon(
          onPressed: () {
            _searchController.clear();
            _resetAllFilters();
          },
          icon: const Icon(Icons.clear_all),
          label: const Text('مسح الكل'),
        ),
      ];
    } else if (hasSearch) {
      icon = Icons.search_off;
      title = 'لا توجد نتائج للبحث';
      subtitle = 'جرب كلمات بحث مختلفة أو تحقق من الإملاء';
      actions = [
        ElevatedButton.icon(
          onPressed: () => _searchController.clear(),
          icon: const Icon(Icons.clear),
          label: const Text('مسح البحث'),
        ),
      ];
    } else if (hasFilters) {
      icon = Icons.filter_list_off;
      title = 'لا توجد منتجات تطابق الفلاتر';
      subtitle = 'جرب تعديل الفلاتر أو إزالتها للحصول على نتائج أكثر';
      actions = [
        ElevatedButton.icon(
          onPressed: _resetAllFilters,
          icon: const Icon(Icons.clear_all),
          label: const Text('إزالة الفلاتر'),
        ),
      ];
    } else {
      icon = Icons.store_outlined;
      title = 'لا توجد منتجات متاحة';
      subtitle = 'كن أول من يضيف منتج في السوق';
      actions = [
        ElevatedButton.icon(
          onPressed: () {
            // التنقل لإضافة منتج جديد
            Navigator.pushNamed(context, '/add-product');
          },
          icon: const Icon(Icons.add),
          label: const Text('إضافة منتج'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
      ];
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ...actions,
          ],
        ),
      ),
    );
  }

  // دالة عرض فلتر السعر
  void _showPriceFilter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'فلترة حسب السعر',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              title: const Text('أقل من 100 ريال'),
              onTap: () {
                Navigator.pop(context);
                _applyPriceFilter(0, 100);
              },
            ),
            ListTile(
              title: const Text('100 - 500 ريال'),
              onTap: () {
                Navigator.pop(context);
                _applyPriceFilter(100, 500);
              },
            ),
            ListTile(
              title: const Text('500 - 1000 ريال'),
              onTap: () {
                Navigator.pop(context);
                _applyPriceFilter(500, 1000);
              },
            ),
            ListTile(
              title: const Text('أكثر من 1000 ريال'),
              onTap: () {
                Navigator.pop(context);
                _applyPriceFilter(1000, double.infinity);
              },
            ),
          ],
        ),
      ),
    );
  }

  // دالة عرض فلتر التقييم
  void _showRatingFilter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'فلترة حسب التقييم',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            for (int i = 5; i >= 1; i--)
              ListTile(
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    5,
                    (index) => Icon(
                      index < i ? Icons.star : Icons.star_border,
                      color: Colors.orange,
                      size: 20,
                    ),
                  ),
                ),
                title: Text('$i نجوم فأكثر'),
                onTap: () {
                  Navigator.pop(context);
                  _applyRatingFilter(i);
                },
              ),
          ],
        ),
      ),
    );
  }

  // دالة عرض فلتر الموقع
  void _showLocationFilter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'فلترة حسب الموقع',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              title: const Text('صنعاء'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _selectedLocation = 'صنعاء';
                });
                context.read<MarketBloc>().add(LoadProductsEvent(
                      category: _selectedCategory,
                      location: _selectedLocation,
                    ));
              },
            ),
            ListTile(
              title: const Text('عدن'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _selectedLocation = 'عدن';
                });
                context.read<MarketBloc>().add(LoadProductsEvent(
                      category: _selectedCategory,
                      location: _selectedLocation,
                    ));
              },
            ),
            ListTile(
              title: const Text('تعز'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _selectedLocation = 'تعز';
                });
                context.read<MarketBloc>().add(LoadProductsEvent(
                      category: _selectedCategory,
                      location: _selectedLocation,
                    ));
              },
            ),
            ListTile(
              title: const Text('الحديدة'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _selectedLocation = 'الحديدة';
                });
                context.read<MarketBloc>().add(LoadProductsEvent(
                      category: _selectedCategory,
                      location: _selectedLocation,
                    ));
              },
            ),
          ],
        ),
      ),
    );
  }

  // دالة عرض خيارات الترتيب
  void _showSortOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ترتيب النتائج',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('الأحدث أولاً'),
              onTap: () {
                Navigator.pop(context);
                _applySortOption('created_at', false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.arrow_upward),
              title: const Text('السعر من الأقل للأعلى'),
              onTap: () {
                Navigator.pop(context);
                _applySortOption('price', true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.arrow_downward),
              title: const Text('السعر من الأعلى للأقل'),
              onTap: () {
                Navigator.pop(context);
                _applySortOption('price', false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.star),
              title: const Text('الأعلى تقييماً'),
              onTap: () {
                Navigator.pop(context);
                _applySortOption('rating', false);
              },
            ),
          ],
        ),
      ),
    );
  }

  // دالة إضافة منتج جديد
  void _showAddProductDialog() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddProductScreen()),
    );

    // إعادة تحميل البيانات عند العودة من شاشة إضافة المنتج
    if (result == true || result == 'refresh') {
      _refreshMarketData();
    }
  }

  // دالة Shimmer للمنتجات
  Widget _buildProductsShimmerLoading() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        itemCount: 6, // عرض 6 عناصر shimmer
        itemBuilder: (context, index) {
          return _buildProductShimmerCard();
        },
      ),
    );
  }

  // بطاقة Shimmer للمنتج الواحد
  Widget _buildProductShimmerCard() {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[700]!
          : Colors.grey[300]!,
      highlightColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[600]!
          : Colors.grey[100]!,
      period: const Duration(milliseconds: 800),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // صورة وهمية
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
              ),
            ),
            // محتوى وهمي
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // عنوان وهمي
                    Container(
                      width: double.infinity,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // سعر وهمي
                    Container(
                      width: 80,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const Spacer(),
                    // زر وهمي
                    Container(
                      width: double.infinity,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // تأثير Shimmer لتحميل المنتجات
  Widget _buildMarketShimmer() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemCount: 6, // عرض 6 عناصر shimmer
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[800]!
                : Colors.grey[300]!,
            highlightColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[700]!
                : Colors.grey[100]!,
            period: const Duration(milliseconds: 800),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // صورة المنتج
                  Expanded(
                    flex: 3,
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  // تفاصيل المنتج
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // اسم المنتج
                          Container(
                            width: double.infinity,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // السعر
                          Container(
                            width: 80,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // الموقع
                          Container(
                            width: 60,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// تحسين التعامل مع الأخطاء برسائل مخصصة وودية للمستخدم
String _userFriendlyError(String error) {
  final errorLower = error.toLowerCase();

  if (errorLower.contains('network') ||
      errorLower.contains('socketexception')) {
    return 'تحقق من اتصالك بالإنترنت وحاول مرة أخرى';
  }
  if (errorLower.contains('timeout')) {
    return 'انتهت مهلة الاتصال بالخادم، يرجى المحاولة مجددًا';
  }
  if (errorLower.contains('unauthorized') || errorLower.contains('401')) {
    return 'يرجى تسجيل الدخول مجددًا';
  }
  if (errorLower.contains('forbidden') || errorLower.contains('403')) {
    return 'ليس لديك صلاحية للوصول إلى هذا المحتوى';
  }
  if (errorLower.contains('not found') || errorLower.contains('404')) {
    return 'المحتوى المطلوب غير موجود';
  }
  if (errorLower.contains('server') || errorLower.contains('500')) {
    return 'خطأ في الخادم، يرجى المحاولة لاحقًا';
  }
  return 'حدث خطأ غير متوقع، يرجى المحاولة مجددًا';
}

// Extension methods for formatting
extension ProductExtensions on Product {
  String get formattedPrice => '${price.toStringAsFixed(0)} ريال';
  String get shortLocation => location.isNotEmpty ? location : 'غير محدد';
  String get sellerDisplayName =>
      sellerName.isNotEmpty ? sellerName : 'غير محدد';
}

// Debouncer class for search
class Debouncer {
  final int milliseconds;
  VoidCallback? action;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
}

// Widget لعرض الوصف القابل للتوسيع
class ExpandableDescription extends StatefulWidget {
  final String description;
  final int maxLines;

  const ExpandableDescription({
    super.key,
    required this.description,
    this.maxLines = 3,
  });

  @override
  State<ExpandableDescription> createState() => _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<ExpandableDescription> {
  bool _isExpanded = false;
  bool _isTextOverflowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkTextOverflow();
    });
  }

  void _checkTextOverflow() {
    final textPainter = TextPainter(
      text: TextSpan(
        text: widget.description,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[700],
        ),
      ),
      maxLines: widget.maxLines,
      textDirection: TextDirection.rtl,
    );

    textPainter.layout(maxWidth: MediaQuery.of(context).size.width - 32);

    if (mounted) {
      setState(() {
        _isTextOverflowing = textPainter.didExceedMaxLines;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.description,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
          maxLines: _isExpanded ? null : widget.maxLines,
          overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
        ),
        if (_isTextOverflowing) ...[
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Text(
              _isExpanded ? 'عرض أقل' : 'عرض المزيد',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
