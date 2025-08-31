// Product_Details Screen

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:sam/market/edit_product.dart';
import 'package:sam/market/market.dart';
import 'package:sam/services/supabaseservice.dart';

class ProductDetailsScreen extends StatefulWidget {
  final String productId;

  const ProductDetailsScreen({super.key, required this.productId});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<MarketBloc>()
          .add(LoadProductDetailsEvent(productId: widget.productId));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<MarketBloc, MarketState>(
        listener: (context, state) {
          if (state is MarketError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is MarketSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            // إذا كان الحدث حذف منتج، العودة للشاشة الرئيسية مع إعادة التحميل
            if (state.message.contains('حذف')) {
              Navigator.pop(context, 'refresh');
            }
          }
        },
        child: BlocBuilder<MarketBloc, MarketState>(
          builder: (context, state) {
            if (state is ProductDetailsLoaded) {
              return _buildProductDetails(state);
            } else if (state is MarketError) {
              return Scaffold(
                appBar: AppBar(title: const Text('خطأ')),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(state.message),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('العودة'),
                      ),
                    ],
                  ),
                ),
              );
            }
            // حالة افتراضية مع شاشة تحميل
            return Scaffold(
              appBar: AppBar(title: const Text('تفاصيل المنتج')),
              body: const Center(child: CircularProgressIndicator()),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProductDetails(ProductDetailsLoaded state) {
    final product = state.product;

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        actions: state.isOwner
            ? [
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editProduct(product);
                    } else if (value == 'delete') {
                      _deleteProduct(product.id);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('تعديل'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('حذف'),
                        ],
                      ),
                    ),
                  ],
                ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Images
            SizedBox(
              height: 300,
              child:
                  product.imageUrls.isNotEmpty && product.imageUrls.first != ''
                      ? PageView.builder(
                          itemCount: product.imageUrls.length,
                          itemBuilder: (context, index) {
                            return Image.network(
                              product.imageUrls[index],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image_not_supported,
                                      size: 64),
                                );
                              },
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(Icons.image, size: 64),
                          ),
                        ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Info
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          context.read<MarketBloc>().add(
                                ToggleProductLikeEvent(productId: product.id),
                              );
                        },
                        child: Row(
                          children: [
                            Icon(
                              product.isLiked
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: product.isLiked ? Colors.red : Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text('${product.likesCount}'),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Text(
                    '${product.price.toStringAsFixed(0)} ريال',
                    style: const TextStyle(
                      fontSize: 20,
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        product.averageRating.toStringAsFixed(1),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(' (${product.ratingsCount} تقييم)'),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Seller Info
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundImage: product.sellerAvatar != null
                                    ? NetworkImage(product.sellerAvatar!)
                                    : null,
                                child: product.sellerAvatar == null
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.sellerName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const Text('البائع'),
                                  ],
                                ),
                              ),
                              if (!state.isOwner)
                                ElevatedButton.icon(
                                  onPressed: () {
                                    _contactSeller(context, product);
                                  },
                                  icon: const Icon(Icons.phone),
                                  label: const Text('تواصل'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2E7D32),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // عرض معلومات التواصل المتاحة
                          FutureBuilder<Map<String, dynamic>?>(
                            future: SupabaseService()
                                .getUserProfile(product.userId),
                            builder: (context, snapshot) {
                              if (snapshot.hasData && snapshot.data != null) {
                                final sellerData = snapshot.data!;
                                final whatsappNumber =
                                    sellerData['whatsapp_number'] as String?;
                                final phoneNumber =
                                    sellerData['phone_number'] as String?;

                                return Row(
                                  children: [
                                    if (whatsappNumber != null &&
                                        whatsappNumber.isNotEmpty)
                                      Container(
                                        margin: const EdgeInsets.only(right: 8),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.green[50],
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: Colors.green[200]!),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.chat,
                                                color: Colors.green[600],
                                                size: 16),
                                            const SizedBox(width: 4),
                                            Text('WhatsApp',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.green[700])),
                                          ],
                                        ),
                                      ),
                                    if (phoneNumber != null &&
                                        phoneNumber.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.blue[50],
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: Colors.blue[200]!),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.phone,
                                                color: Colors.blue[600],
                                                size: 16),
                                            const SizedBox(width: 4),
                                            Text('هاتف',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.blue[700])),
                                          ],
                                        ),
                                      ),
                                    if ((whatsappNumber == null ||
                                            whatsappNumber.isEmpty) &&
                                        (phoneNumber == null ||
                                            phoneNumber.isEmpty))
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'لا توجد معلومات تواصل',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600]),
                                        ),
                                      ),
                                  ],
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Product Details
                  const Text(
                    'تفاصيل المنتج',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow('الوصف', product.description),
                          _buildDetailRow('الفئة', product.category),
                          _buildDetailRow('الموقع', product.location),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Ratings Section
                  Row(
                    children: [
                      const Text(
                        'التقييمات',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (!state.isOwner)
                        TextButton.icon(
                          onPressed: () => _showRatingDialog(product.id),
                          icon: const Icon(Icons.star),
                          label: const Text('إضافة تقييم'),
                        ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  if (state.ratings.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: Text('لا توجد تقييمات بعد'),
                        ),
                      ),
                    )
                  else
                    ...state.ratings.map((rating) => _buildRatingCard(rating)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingCard(ProductRating rating) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: rating.userAvatar != null
                      ? NetworkImage(rating.userAvatar!)
                      : null,
                  child: rating.userAvatar == null
                      ? const Icon(Icons.person, size: 16)
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    rating.userName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < rating.rating ? Icons.star : Icons.star_border,
                      size: 16,
                      color: Colors.orange,
                    );
                  }),
                ),
              ],
            ),
            if (rating.comment != null && rating.comment!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(rating.comment!),
            ],
            const SizedBox(height: 4),
            Text(
              _formatDate(rating.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRatingDialog(String productId) {
    int selectedRating = 5;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('إضافة تقييم'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('اختر التقييم:'),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedRating = index + 1;
                      });
                    },
                    child: Icon(
                      index < selectedRating ? Icons.star : Icons.star_border,
                      size: 32,
                      color: Colors.orange,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                style: const TextStyle(fontSize: 16),
                decoration: const InputDecoration(
                  labelText: 'تعليق (اختياري)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.read<MarketBloc>().add(
                      AddProductRatingEvent(
                        productId: productId,
                        rating: selectedRating,
                        comment: commentController.text.trim().isEmpty
                            ? null
                            : commentController.text.trim(),
                      ),
                    );
              },
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
  }

  void _editProduct(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProductScreen(product: product),
      ),
    );
  }

  void _deleteProduct(String productId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا المنتج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // إغلاق حوار التأكيد
              context.read<MarketBloc>().add(
                    DeleteProductEvent(productId: productId),
                  );
              // سيتم التعامل مع العودة في BlocListener عند نجاح الحذف
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // دالة التواصل الخارجي مع البائع
  void _contactSeller(BuildContext context, Product product) async {
    if (!mounted) return;

    // عرض مؤشر التحميل
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // جلب معلومات البائع من قاعدة البيانات
      final sellerData = await SupabaseService().getUserProfile(product.userId);

      // إخفاء مؤشر التحميل
      if (mounted) Navigator.of(context).pop();

      if (sellerData == null) {
        if (mounted)
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
        if (mounted)
          _showContactOptionsDialog(
              context, whatsappNumber, phoneNumber, message);
      } else if (whatsappNumber != null && whatsappNumber.isNotEmpty) {
        if (mounted) _openWhatsApp(context, whatsappNumber, message);
      } else if (phoneNumber != null && phoneNumber.isNotEmpty) {
        if (mounted) _makePhoneCall(context, phoneNumber);
      } else {
        if (mounted)
          _showContactErrorDialog(
              context, 'لا توجد معلومات تواصل متاحة للبائع');
      }
    } catch (e) {
      // إخفاء مؤشر التحميل في حالة الخطأ
      if (mounted) Navigator.of(context).pop();
      if (mounted)
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
      final url =
          'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        throw 'لا يمكن فتح WhatsApp';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في فتح WhatsApp: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // إجراء مكالمة هاتفية
  void _makePhoneCall(BuildContext context, String phoneNumber) async {
    try {
      final url = 'tel:$phoneNumber';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        throw 'لا يمكن إجراء المكالمة';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في إجراء المكالمة: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
