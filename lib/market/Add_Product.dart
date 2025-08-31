// Add_Product Screen
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sam/services/image_service.dart';
import 'package:sam/market/market.dart';
import 'package:sam/widgets/location_field.dart';

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
  final Map<File, Uint8List> _webImageData = {}; // لحفظ بيانات الصور في الويب

  final List<String> _categories = [
    'خضروات',
    'فواكه',
    'حبوب',
    'بذور',
    'أسمدة',
    'أدوات زراعية',
    'أخرى',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة منتج جديد'),
      ),
      body: BlocListener<MarketBloc, MarketState>(
        listener: (context, state) {
          if (state is MarketSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: const Text('تمت إضافة المنتج بنجاح!'),
                  backgroundColor: Colors.green),
            );
            Navigator.pop(context, 'refresh'); // إرجاع نتيجة لإعادة التحميل
          }
        },
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Images Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('صور المنتج',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 120,
                          child: Row(
                            children: [
                              ..._selectedImages.map((image) => Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: kIsWeb
                                              ? (_webImageData
                                                      .containsKey(image)
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
                                                        child: Icon(
                                                          Icons.image,
                                                          color: Colors.grey,
                                                        ),
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
                                            onTap: () {
                                              setState(() {
                                                _selectedImages.remove(image);
                                                if (kIsWeb) {
                                                  _webImageData.remove(image);
                                                }
                                              });
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: const BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.close,
                                                  size: 16,
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                              if (_selectedImages.length < 5)
                                GestureDetector(
                                  onTap: _pickImages,
                                  child: Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_photo_alternate,
                                            size: 32),
                                        Text('إضافة صورة',
                                            style: TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Product Name
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(fontSize: 16),
                  decoration: const InputDecoration(
                    labelText: 'اسم المنتج *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال اسم المنتج';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Category
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  style: const TextStyle(fontSize: 16, color: Colors.black),
                  decoration: const InputDecoration(
                    labelText: 'الفئة *',
                    border: OutlineInputBorder(),
                  ),
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value!;
                    });
                  },
                ),

                const SizedBox(height: 16),

                // Price
                TextFormField(
                  controller: _priceController,
                  style: const TextStyle(fontSize: 16),
                  decoration: const InputDecoration(
                    labelText: 'السعر *',
                    border: OutlineInputBorder(),
                    suffixText: 'ريال',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال السعر';
                    }
                    if (double.tryParse(value) == null) {
                      return 'سعر غير صحيح';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Location
                LocationField(
                  controller: _locationController,
                  labelText: 'الموقع',
                  hintText: 'اختر موقعك أو احصل على الموقع الحالي',
                  isRequired: true,
                ),

                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  style: const TextStyle(fontSize: 16),
                  decoration: const InputDecoration(
                    labelText: 'الوصف *',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال وصف المنتج';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                    ),
                    child: const Text(
                      'إضافة المنتج',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImages() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage();

      if (images.isEmpty) return;
      if (!mounted) return;

      // عرض مؤشر التحميل
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final List<File> processedImages = [];

      for (var image in images) {
        if (_selectedImages.length + processedImages.length >= 5) break;

        final File originalFile = File(image.path);

        if (kIsWeb) {
          // في الويب، نقرأ البايتات من XFile مباشرة
          final Uint8List originalBytes = await image.readAsBytes();
          final Uint8List? compressedBytes =
              await ImageService.compressImageForWeb(originalBytes);

          if (compressedBytes != null) {
            _webImageData[originalFile] = compressedBytes;
            processedImages.add(originalFile);
          } else {
            // في حالة فشل الضغط، استخدم الصورة الأصلية
            _webImageData[originalFile] = originalBytes;
            processedImages.add(originalFile);
          }
        } else {
          // في المحمول، نستخدم خدمة الضغط العادية
          final File? compressedFile =
              await ImageService.compressImage(originalFile);

          if (compressedFile != null) {
            processedImages.add(compressedFile);
          } else {
            // في حالة فشل الضغط، استخدم الصورة الأصلية
            processedImages.add(originalFile);
          }
        }
      }

      if (!mounted) return;

      // إخفاء مؤشر التحميل
      Navigator.of(context).pop();

      setState(() {
        _selectedImages.addAll(processedImages);
      });

      if (processedImages.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم ضغط وإضافة ${processedImages.length} صورة'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      // إخفاء مؤشر التحميل في حالة الخطأ
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في معالجة الصور: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_selectedImages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('يرجى إضافة صورة واحدة على الأقل'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

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
