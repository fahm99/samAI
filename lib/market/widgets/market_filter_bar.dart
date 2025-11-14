import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/market_categories.dart';
import '../models/market_locations.dart';

class MarketFilterBar extends StatefulWidget {
  final String? selectedCategory;
  final String? selectedLocation;
  final double? minPrice;
  final double? maxPrice;
  final Function(String?) onCategoryChanged;
  final Function(String?) onLocationChanged;
  final Function(double?, double?) onPriceRangeChanged;
  final VoidCallback? onClearFilters;

  const MarketFilterBar({
    super.key,
    this.selectedCategory,
    this.selectedLocation,
    this.minPrice,
    this.maxPrice,
    required this.onCategoryChanged,
    required this.onLocationChanged,
    required this.onPriceRangeChanged,
    this.onClearFilters,
  });

  @override
  State<MarketFilterBar> createState() => _MarketFilterBarState();
}

class _MarketFilterBarState extends State<MarketFilterBar> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // شريط الفلاتر السريعة
          _buildQuickFilters(),

          // الفلاتر المتقدمة
          if (_isExpanded) _buildAdvancedFilters(),
        ],
      ),
    );
  }

  Widget _buildQuickFilters() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          // فلتر الفئة
          Expanded(
            child: _buildCategoryFilter(),
          ),
          SizedBox(width: 12.w),

          // فلتر الموقع
          Expanded(
            child: _buildLocationFilter(),
          ),
          SizedBox(width: 12.w),

          // زر الفلاتر المتقدمة
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: _isExpanded
                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                _isExpanded ? Icons.expand_less : Icons.expand_more,
                color: _isExpanded
                    ? Theme.of(context).primaryColor
                    : Colors.grey[600],
                size: 20.sp,
              ),
            ),
          ),

          // زر مسح الفلاتر
          if (widget.selectedCategory != null ||
              widget.selectedLocation != null ||
              widget.minPrice != null ||
              widget.maxPrice != null) ...[
            SizedBox(width: 8.w),
            GestureDetector(
              onTap: widget.onClearFilters,
              child: Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.clear,
                  color: Colors.red,
                  size: 20.sp,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return GestureDetector(
      onTap: () => _showCategoryDialog(),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: widget.selectedCategory != null
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(8.r),
          border: widget.selectedCategory != null
              ? Border.all(color: Theme.of(context).primaryColor, width: 1)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.category,
              size: 16.sp,
              color: widget.selectedCategory != null
                  ? Theme.of(context).primaryColor
                  : Colors.grey[600],
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: Text(
                widget.selectedCategory ?? 'الفئة',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: widget.selectedCategory != null
                      ? Theme.of(context).primaryColor
                      : Colors.grey[600],
                  fontWeight: widget.selectedCategory != null
                      ? FontWeight.w500
                      : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              size: 16.sp,
              color: Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationFilter() {
    return GestureDetector(
      onTap: () => _showLocationDialog(),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: widget.selectedLocation != null
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(8.r),
          border: widget.selectedLocation != null
              ? Border.all(color: Theme.of(context).primaryColor, width: 1)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_on,
              size: 16.sp,
              color: widget.selectedLocation != null
                  ? Theme.of(context).primaryColor
                  : Colors.grey[600],
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: Text(
                widget.selectedLocation ?? 'الموقع',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: widget.selectedLocation != null
                      ? Theme.of(context).primaryColor
                      : Colors.grey[600],
                  fontWeight: widget.selectedLocation != null
                      ? FontWeight.w500
                      : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              size: 16.sp,
              color: Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedFilters() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'نطاق السعر',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.titleMedium?.color,
            ),
          ),
          SizedBox(height: 12.h),
          _buildPriceRangeFilter(),
        ],
      ),
    );
  }

  Widget _buildPriceRangeFilter() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'من',
              hintStyle: TextStyle(fontSize: 12.sp),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            ),
            onChanged: (value) {
              final minPrice = double.tryParse(value);
              widget.onPriceRangeChanged(minPrice, widget.maxPrice);
            },
          ),
        ),
        SizedBox(width: 12.w),
        Text(
          'إلى',
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'إلى',
              hintStyle: TextStyle(fontSize: 12.sp),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            ),
            onChanged: (value) {
              final maxPrice = double.tryParse(value);
              widget.onPriceRangeChanged(widget.minPrice, maxPrice);
            },
          ),
        ),
      ],
    );
  }

  void _showCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اختر الفئة'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: MarketCategories.getCategoriesData().length,
            itemBuilder: (context, index) {
              final categoryData = MarketCategories.getCategoriesData()[index];
              final isAll = categoryData['value']!.isEmpty;

              return ListTile(
                leading: Text(
                  categoryData['icon']!,
                  style: TextStyle(fontSize: 20.sp),
                ),
                title: Text(categoryData['name']!),
                onTap: () {
                  widget
                      .onCategoryChanged(isAll ? null : categoryData['value']);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showLocationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اختر الموقع'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: MarketLocations.getLocations().length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return ListTile(
                  title: const Text('جميع المواقع'),
                  onTap: () {
                    widget.onLocationChanged(null);
                    Navigator.pop(context);
                  },
                );
              }

              final location = MarketLocations.getLocations()[index - 1];
              return ListTile(
                leading: const Icon(Icons.location_on),
                title: Text(location),
                onTap: () {
                  widget.onLocationChanged(location);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
