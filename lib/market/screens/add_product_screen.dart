import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/image_service.dart';
import '../../widgets/location_field.dart';
import '../bloc/market_bloc.dart';
import '../bloc/market_event.dart';
import '../bloc/market_state.dart';
import '../models/market_categories.dart';

/// شاشة إضافة منتج جديد
class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  String _selectedCategory = 'خضروات';
  final List<File> _selectedImages = [];
  final Map<File, Uint8List> _webImageData = {};

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة منتج جديد'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: BlocListener<MarketBloc, MarketState>(
        listener: (context, state) {
          if (state is MarketSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تمت إضافة المنتج بنجاح!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, 'refresh');
          } else if (state is MarketError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // قسم الصور
                _buildImagesSection(),
                const SizedBox(height: 24),

                // اسم المنتج
                _buildNameField(),
                const SizedBox(height: 16),

                // الفئة
                _buildCategoryField(),
                const SizedBox(height: 16),

                // السعر
                _buildPriceField(),
                const SizedBox(height: 16),

                // الموقع
                _buildLocationField(),
                const SizedBox(height: 16),

                // الوصف
                _buildDescriptionField(),
                const SizedBox(height: 32),

                // زر الإضافة
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagesSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.photo_library, color: Color(0xFF2E7D32)),
                const SizedBox(width: 8),
                const Text(
                  'صور المنتج',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_selectedImages.length}/5',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ..._selectedImages.asMap().entries.map((entry) {
                    final index = entry.key;
                    final image = entry.value;
                    return _buildImageItem(image, index);
                  }),
                  if (_selectedImages.length < 5) _buildAddImageButton(),
                ],
              ),
            ),
            if (_selectedImages.isEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.orange[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'يرجى إضافة صورة واحدة على الأقل للمنتج',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageItem(File image, int index) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: kIsWeb
                ? (_webImageData.containsKey(image)
                    ? Image.memory(
                        _webImageData[image]!,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(Icons.image, color: Colors.grey),
                        ),
                      ))
                : Image.file(
                    image,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeImage(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _pickImages,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[400]!, width: 2),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[50],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate,
              size: 32,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 4),
            Text(
              'إضافة صورة',
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

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'اسم المنتج *',
        hintText: 'مثال: طماطم طازجة',
        prefixIcon: Icon(Icons.inventory_2_outlined),
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'يرجى إدخال اسم المنتج';
        }
        if (value.trim().length < 3) {
          return 'اسم المنتج يجب أن يكون 3 أحرف على الأقل';
        }
        return null;
      },
    );
  }

  Widget _buildCategoryField() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: const InputDecoration(
        labelText: 'الفئة *',
        prefixIcon: Icon(Icons.category_outlined),
        border: OutlineInputBorder(),
      ),
      items: MarketCategories.getCategoryNames().map((category) {
        return DropdownMenuItem(
          value: category,
          child: Row(
            children: [
              Text(MarketCategories.getCategoryIcon(category)),
              const SizedBox(width: 8),
              Text(category),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCategory = value!;
        });
      },
    );
  }

  Widget _buildPriceField() {
    return TextFormField(
      controller: _priceController,
      decoration: const InputDecoration(
        labelText: 'السعر *',
        hintText: '0.00',
        prefixIcon: Icon(Icons.attach_money),
        suffixText: 'ريال',
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'يرجى إدخال السعر';
        }
        final price = double.tryParse(value);
        if (price == null || price <= 0) {
          return 'يرجى إدخال سعر صحيح';
        }
        return null;
      },
    );
  }

  Widget _buildLocationField() {
    return LocationField(
      controller: _locationController,
      labelText: 'الموقع *',
      hintText: 'اختر موقعك أو احصل على الموقع الحالي',
      isRequired: true,
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: const InputDecoration(
        labelText: 'الوصف *',
        hintText: 'اكتب وصفاً مفصلاً عن المنتج...',
        prefixIcon: Icon(Icons.description_outlined),
        border: OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
      maxLines: 4,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'يرجى إدخال وصف المنتج';
        }
        if (value.trim().length < 10) {
          return 'الوصف يجب أن يكون 10 أحرف على الأقل';
        }
        return null;
      },
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _submitForm,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.add_shopping_cart),
        label: Text(_isLoading ? 'جاري الإضافة...' : 'إضافة المنتج'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImages() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage();

      if (images.isEmpty) return;

      final List<File> processedImages = [];

      for (var image in images) {
        if (_selectedImages.length + processedImages.length >= 5) break;

        final File originalFile = File(image.path);

        if (kIsWeb) {
          final Uint8List originalBytes = await image.readAsBytes();
          final Uint8List? compressedBytes =
              await ImageService.compressImageForWeb(originalBytes);

          if (compressedBytes != null) {
            _webImageData[originalFile] = compressedBytes;
            processedImages.add(originalFile);
          } else {
            _webImageData[originalFile] = originalBytes;
            processedImages.add(originalFile);
          }
        } else {
          final File? compressedFile =
              await ImageService.compressImage(originalFile);

          if (compressedFile != null) {
            processedImages.add(compressedFile);
          } else {
            processedImages.add(originalFile);
          }
        }
      }

      setState(() {
        _selectedImages.addAll(processedImages);
      });

      if (processedImages.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم إضافة ${processedImages.length} صورة'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في معالجة الصور: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      final image = _selectedImages[index];
      _selectedImages.removeAt(index);
      if (kIsWeb) {
        _webImageData.remove(image);
      }
    });
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إضافة صورة واحدة على الأقل'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    context.read<MarketBloc>().add(
          AddProductEvent(
            name: _nameController.text.trim(),
            price: double.parse(_priceController.text),
            description: _descriptionController.text.trim(),
            category: _selectedCategory,
            images: _selectedImages,
            location: _locationController.text.trim(),
            webImageData: kIsWeb ? _webImageData : null,
          ),
        );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}
