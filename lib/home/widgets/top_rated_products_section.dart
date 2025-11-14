import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';

import '../../services/supabaseservice.dart';
import '../../services/agricultural_cache_service.dart';
import '../../market/screens/market_screen.dart';
import '../../market/screens/product_details_screen.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_state.dart';

class TopRatedProductsSection extends StatelessWidget {
  const TopRatedProductsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              const Icon(Icons.star, color: Color(0xFFFF9800)),
              const SizedBox(width: 8),
              const Text(
                'أعلى المنتجات تقييماً',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 0, 0, 0),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const MarketScreen()),
                  );
                },
                child: const Text(
                  'عرض الكل',
                  style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 250,
          child: BlocBuilder<HomeBloc, HomeState>(
            builder: (context, state) {
              return FutureBuilder<List<Map<String, dynamic>>>(
                future: _getTopRatedProductsWithCache(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildTopRatedShimmer(context);
                  } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      itemCount:
                          snapshot.data!.length > 8 ? 8 : snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final product = snapshot.data![index];
                        return _buildTopRatedProductCard(context, product);
                      },
                    );
                  } else {
                    return _buildEmptyTopRated(context);
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<List<Map<String, dynamic>>> _getTopRatedProductsWithCache() async {
    final cachedTopRated =
        AgriculturalCacheService().getCachedTopRatedProducts();
    if (cachedTopRated.isNotEmpty) {
      _updateTopRatedProductsSilently();
      return cachedTopRated.take(8).toList();
    }

    try {
      final products = await SupabaseService().getTopRatedProducts(limit: 8);
      if (products.isNotEmpty) {
        await AgriculturalCacheService().cacheTopRatedProducts(products);
        return products;
      }

      final regularProducts =
          await SupabaseService().getMarketProducts(limit: 8);
      return regularProducts;
    } catch (e) {
      debugPrint('Error getting top rated products: $e');

      final cachedProducts = AgriculturalCacheService().getCachedProducts();
      if (cachedProducts.isNotEmpty) {
        return cachedProducts
            .take(8)
            .map((product) => product.toMap())
            .toList();
      }

      return [];
    }
  }

  Future<void> _updateTopRatedProductsSilently() async {
    try {
      final products = await SupabaseService().getTopRatedProducts(limit: 8);
      if (products.isNotEmpty) {
        await AgriculturalCacheService().cacheTopRatedProducts(products);
      }
    } catch (e) {
      debugPrint('خطأ في التحديث الخفي للمنتجات الأعلى تقييماً: $e');
    }
  }

  Widget _buildTopRatedShimmer(BuildContext context) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          width: 160,
          margin: const EdgeInsets.only(left: 12),
          child: Shimmer.fromColors(
            baseColor: Theme.of(context).brightness == Brightness.dark
                ? Theme.of(context).dividerColor.withOpacity(0.3)
                : Theme.of(context).dividerColor.withOpacity(0.2),
            highlightColor: Theme.of(context).brightness == Brightness.dark
                ? Theme.of(context).cardColor.withOpacity(0.8)
                : Theme.of(context).scaffoldBackgroundColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 10,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyTopRated(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_outline,
              size: 32, color: Theme.of(context).disabledColor),
          const SizedBox(height: 8),
          Text(
            'لا توجد منتجات مقيمة بعد',
            style: TextStyle(color: Theme.of(context).disabledColor),
          ),
        ],
      ),
    );
  }

  Widget _buildTopRatedProductCard(
      BuildContext context, Map<String, dynamic> product) {
    final imageUrls = List<String>.from(product['image_urls'] ?? []);
    final averageRating = (product['average_rating'] ?? 0.0) as double;
    final ratingsCount = (product['ratings_count'] ?? 0) as int;

    return Container(
      width: 160,
      margin: const EdgeInsets.only(left: 12),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ProductDetailsScreen(productId: product['id']),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: imageUrls.isNotEmpty
                      ? Image.network(
                          imageUrls.first,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Theme.of(context)
                                  .dividerColor
                                  .withOpacity(0.3),
                              child: const Icon(Icons.image_not_supported),
                            );
                          },
                        )
                      : Container(
                          color:
                              Theme.of(context).dividerColor.withOpacity(0.3),
                          child: const Icon(Icons.image, size: 32),
                        ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['name'] ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star,
                              color: Colors.orange, size: 12),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              '${averageRating.toStringAsFixed(1)} ($ratingsCount)',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(product['price'] ?? 0).toStringAsFixed(0)} ريال',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
