import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:rxdart/rxdart.dart';

import '../../services/supabaseservice.dart';
import '../../services/agricultural_cache_service.dart';
import '../models/product.dart';
import '../models/product_rating.dart';
import '../models/market_categories.dart';
import '../models/market_locations.dart';
import 'market_event.dart';
import 'market_state.dart';

/// BLoC إدارة السوق الزراعي
class MarketBloc extends Bloc<MarketEvent, MarketState> {
  final SupabaseService _supabaseService = SupabaseService();
  final AgriculturalCacheService _cacheService = AgriculturalCacheService();

  // مراقبة الاتصال
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

    // مراقبة الاتصال بالإنترنت
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((result) {
      _isConnected = !result.contains(ConnectivityResult.none);
      if (_isConnected && state is MarketError) {
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

  /// Debounce transformer للبحث
  EventTransformer<SearchProductsEvent> _debounceTransformer() {
    return (events, mapper) => events
        .debounceTime(const Duration(milliseconds: 300))
        .switchMap(mapper);
  }

  /// تحميل بيانات السوق الأساسية
  Future<void> _onLoadMarketData(
      LoadMarketDataEvent event, Emitter<MarketState> emit) async {
    try {
      emit(MarketLoading());

      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) {
        emit(MarketError(message: 'المستخدم غير مسجل الدخول'));
        return;
      }

      final productsData = await _supabaseService.getMarketProducts(limit: 20);
      List<Product> products =
          await _processProductsData(productsData, currentUser.id);

      final categories = MarketCategories.getCategoryValues();
      final locations = MarketLocations.getLocations();

      emit(MarketLoaded(
        products: products,
        categories: categories,
        locations: locations,
      ));
    } catch (e) {
      emit(MarketError(message: _getErrorMessage(e)));
    }
  }

  /// تحميل المنتجات مع الفلاتر
  Future<void> _onLoadProducts(
      LoadProductsEvent event, Emitter<MarketState> emit) async {
    try {
      // فحص الاتصال
      final connectivityResult = await Connectivity().checkConnectivity();
      _isConnected = !connectivityResult.contains(ConnectivityResult.none);
      _cacheService.updateConnectionStatus(_isConnected);

      // عرض البيانات المحفوظة أولاً
      final cachedProducts = _cacheService.getCachedProducts();
      final cachedCategories = _cacheService.getCachedCategories();
      final cachedLocations = _cacheService.getCachedLocations();

      if (cachedProducts.isNotEmpty) {
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

        emit(MarketLoaded(
          products: filteredProducts,
          categories: cachedCategories.isNotEmpty
              ? cachedCategories
              : MarketCategories.getCategoryValues(),
          locations: cachedLocations.isNotEmpty
              ? cachedLocations
              : MarketLocations.getLocations(),
        ));
      }

      // إذا لم يكن هناك اتصال، اكتفِ بالبيانات المحفوظة
      if (!_isConnected) {
        if (cachedProducts.isEmpty) {
          emit(MarketLoaded(
            products: const [],
            categories: MarketCategories.getCategoryValues(),
            locations: MarketLocations.getLocations(),
          ));
        }
        return;
      }

      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) {
        if (cachedProducts.isEmpty) {
          emit(MarketLoaded(
            products: const [],
            categories: MarketCategories.getCategoryValues(),
            locations: MarketLocations.getLocations(),
          ));
        }
        return;
      }

      // التحديث في الخلفية
      _loadAndCacheProductsDataSilently(event).then((_) {
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
                  : MarketCategories.getCategoryValues(),
              locations: _cacheService.getCachedLocations().isNotEmpty
                  ? _cacheService.getCachedLocations()
                  : MarketLocations.getLocations(),
            ));
          }
        }
      }).catchError((e) {
        if (cachedProducts.isEmpty && !isClosed) {
          emit(MarketLoaded(
            products: const [],
            categories: MarketCategories.getCategoryValues(),
            locations: MarketLocations.getLocations(),
          ));
        }
        debugPrint('خطأ في تحميل منتجات السوق: $e');
      });
    } catch (e) {
      emit(MarketLoaded(
        products: const [],
        categories: MarketCategories.getCategoryValues(),
        locations: MarketLocations.getLocations(),
      ));
      debugPrint('خطأ في تحميل منتجات السوق: $e');
    }
  }

  /// تحميل البيانات وحفظها في التخزين المؤقت
  Future<void> _loadAndCacheProductsDataSilently(
      LoadProductsEvent event) async {
    try {
      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) return;

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

      if (products.isNotEmpty) {
        _cacheService.smartUpdateProducts(products);
      }

      final categories = MarketCategories.getCategoryValues();
      final locations = MarketLocations.getLocations();

      _cacheService.cacheCategories(categories);
      _cacheService.cacheLocations(locations);
    } catch (e) {
      debugPrint('خطأ في تحميل البيانات للتخزين المؤقت: $e');
    }
  }

  /// تحميل المزيد من المنتجات
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

  /// معالجة بيانات المنتجات
  Future<List<Product>> _processProductsData(
      List<dynamic> productsData, String userId) async {
    List<Product> products = [];

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

  /// تحميل تفاصيل المنتج
  Future<void> _onLoadProductDetails(
      LoadProductDetailsEvent event, Emitter<MarketState> emit) async {
    try {
      emit(MarketLoading());

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
      emit(MarketError(message: _getErrorMessage(e)));
    }
  }

  /// تبديل الإعجاب بالمنتج
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
      emit(MarketError(message: _getErrorMessage(e)));
    }
  }

  /// إضافة منتج جديد
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
        final path = '${currentUser.id}/$fileName';

        String? imageUrl;
        if (kIsWeb && event.webImageData != null) {
          final imageBytes = event.webImageData![event.images[i]];
          if (imageBytes != null) {
            imageUrl = await _supabaseService.uploadFileWeb(
              'productimages',
              path,
              imageBytes,
            );
          }
        } else {
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
        'price': event.price.toDouble(),
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
      emit(MarketError(message: _getErrorMessage(e)));
    }
  }

  /// تحديث منتج موجود
  Future<void> _onUpdateProduct(
      UpdateProductEvent event, Emitter<MarketState> emit) async {
    try {
      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) {
        emit(MarketError(message: 'المستخدم غير مسجل الدخول'));
        return;
      }

      List<String>? newImageUrls;
      if (event.newImages != null && event.newImages!.isNotEmpty) {
        newImageUrls = [];
        for (int i = 0; i < event.newImages!.length; i++) {
          final fileName =
              'product_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
          final path = '${currentUser.id}/$fileName';

          final imageUrl = await _supabaseService.uploadFile(
            'productimages',
            path,
            event.newImages![i],
          );

          if (imageUrl != null) {
            newImageUrls.add(imageUrl);
          }
        }
      }

      final productData = {
        'name': event.name,
        'price': event.price.toDouble(),
        'description': event.description,
        'category': event.category,
        'location': event.location,
        if (newImageUrls != null) 'image_urls': newImageUrls,
      };

      final success =
          await _supabaseService.updateProduct(event.productId, productData);

      if (success) {
        emit(MarketSuccess(message: 'تم تحديث المنتج بنجاح'));
        add(LoadProductDetailsEvent(productId: event.productId));
      } else {
        emit(MarketError(message: 'فشل في تحديث المنتج'));
      }
    } catch (e) {
      emit(MarketError(message: _getErrorMessage(e)));
    }
  }

  /// حذف منتج
  Future<void> _onDeleteProduct(
      DeleteProductEvent event, Emitter<MarketState> emit) async {
    try {
      final success = await _supabaseService.deleteProduct(event.productId);

      if (success) {
        emit(MarketSuccess(message: 'تم حذف المنتج بنجاح'));
      } else {
        emit(MarketError(message: 'فشل في حذف المنتج'));
      }
    } catch (e) {
      emit(MarketError(message: _getErrorMessage(e)));
    }
  }

  /// البحث في المنتجات
  Future<void> _onSearchProducts(
      SearchProductsEvent event, Emitter<MarketState> emit) async {
    try {
      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) {
        emit(MarketError(message: 'المستخدم غير مسجل الدخول'));
        return;
      }

      final productsData = await _supabaseService.searchProducts(
        searchTerm: event.query,
        category: event.category,
        location: event.location,
        minPrice: event.minPrice,
        maxPrice: event.maxPrice,
      );

      List<Product> products =
          await _processProductsData(productsData, currentUser.id);

      emit(MarketLoaded(
        products: products,
        categories: MarketCategories.getCategoryValues(),
        locations: MarketLocations.getLocations(),
      ));
    } catch (e) {
      emit(MarketError(message: _getErrorMessage(e)));
    }
  }

  /// إضافة تقييم للمنتج
  Future<void> _onAddProductRating(
      AddProductRatingEvent event, Emitter<MarketState> emit) async {
    try {
      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) {
        emit(MarketError(message: 'المستخدم غير مسجل الدخول'));
        return;
      }

      final success = await _supabaseService.addProductRating({
        'product_id': event.productId,
        'user_id': currentUser.id,
        'rating': event.rating,
        'comment': event.comment,
      });

      if (success) {
        emit(MarketSuccess(message: 'تم إضافة التقييم بنجاح'));
        add(LoadProductDetailsEvent(productId: event.productId));
      } else {
        emit(MarketError(message: 'فشل في إضافة التقييم'));
      }
    } catch (e) {
      emit(MarketError(message: _getErrorMessage(e)));
    }
  }

  /// معالج الأخطاء مع رسائل واضحة
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
}
