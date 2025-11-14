import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';

import '../bloc/market_bloc.dart';
import '../bloc/market_event.dart';
import '../bloc/market_state.dart';
import '../widgets/widgets.dart';
import 'product_details_screen.dart';
import 'add_product_screen.dart';

/// شاشة السوق الزراعي الرئيسية
class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  String? _selectedCategory;
  String? _selectedLocation;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // تحميل البيانات عند بدء الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MarketBloc>().add(LoadMarketDataEvent());
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      context.read<MarketBloc>().add(LoadMoreProductsEvent(
            category: _selectedCategory,
            location: _selectedLocation,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      body: Column(
        children: [
          // شريط البحث
          MarketSearchBar(
            onSearch: (query) {
              setState(() {
                _searchQuery = query;
              });
              if (query.isNotEmpty) {
                context.read<MarketBloc>().add(SearchProductsEvent(
                      query: query,
                      category: _selectedCategory,
                      location: _selectedLocation,
                    ));
              } else {
                context.read<MarketBloc>().add(LoadProductsEvent(
                      category: _selectedCategory,
                      location: _selectedLocation,
                    ));
              }
            },
          ),

          // شريط الفلاتر
          MarketFilterBar(
            selectedCategory: _selectedCategory,
            selectedLocation: _selectedLocation,
            onCategoryChanged: (category) {
              setState(() {
                _selectedCategory = category;
              });
              _applyFilters();
            },
            onLocationChanged: (location) {
              setState(() {
                _selectedLocation = location;
              });
              _applyFilters();
            },
            onPriceRangeChanged: (min, max) {
              // تطبيق فلتر السعر
            },
            onClearFilters: () {
              setState(() {
                _selectedCategory = null;
                _selectedLocation = null;
                _searchQuery = '';
              });
              context.read<MarketBloc>().add(LoadProductsEvent());
            },
          ),

          // قائمة المنتجات
          Expanded(
            child: BlocConsumer<MarketBloc, MarketState>(
              listener: (context, state) {
                if (state is MarketError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is MarketLoading) {
                  return _buildLoadingGrid();
                } else if (state is MarketLoaded) {
                  return _buildProductsGrid(state);
                } else if (state is MarketError) {
                  return _buildErrorWidget(state.message);
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddProduct(),
        backgroundColor: const Color(0xFF2E7D32),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _applyFilters() {
    if (_searchQuery.isNotEmpty) {
      context.read<MarketBloc>().add(SearchProductsEvent(
            query: _searchQuery,
            category: _selectedCategory,
            location: _selectedLocation,
          ));
    } else {
      context.read<MarketBloc>().add(LoadProductsEvent(
            category: _selectedCategory,
            location: _selectedLocation,
          ));
    }
  }

  Widget _buildLoadingGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    color: Colors.white,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 16,
                          width: double.infinity,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 14,
                          width: 100,
                          color: Colors.white,
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
    );
  }

  Widget _buildProductsGrid(MarketLoaded state) {
    if (state.products.isEmpty) {
      return _buildEmptyWidget();
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<MarketBloc>().add(LoadProductsEvent(
              category: _selectedCategory,
              location: _selectedLocation,
              isRefresh: true,
            ));
      },
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: state.products.length + (state.isLoadingMore ? 2 : 0),
        itemBuilder: (context, index) {
          if (index >= state.products.length) {
            return _buildLoadingCard();
          }

          final product = state.products[index];
          return ProductCard(
            product: product,
            onTap: () => _navigateToProductDetails(product.id),
            onFavorite: () {
              context.read<MarketBloc>().add(
                    ToggleProductLikeEvent(productId: product.id),
                  );
            },
            isFavorite: false, // يمكن ربطه بحالة المفضلة
          );
        },
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Card(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.store_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد منتجات',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'جرب تغيير الفلاتر أو البحث',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToAddProduct(),
            icon: const Icon(Icons.add),
            label: const Text('أضف منتج جديد'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'حدث خطأ',
            style: TextStyle(
              fontSize: 18,
              color: Colors.red[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              context.read<MarketBloc>().add(LoadMarketDataEvent());
            },
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  void _navigateToAddProduct() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddProductScreen(),
      ),
    );

    if (result == 'refresh') {
      context.read<MarketBloc>().add(LoadProductsEvent(
            category: _selectedCategory,
            location: _selectedLocation,
          ));
    }
  }

  void _navigateToProductDetails(String productId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailsScreen(productId: productId),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
