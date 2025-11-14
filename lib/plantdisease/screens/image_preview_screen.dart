import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../theme/theme.dart';
import '../bloc/plant_disease_bloc.dart';
import '../bloc/plant_disease_event.dart';

class ImagePreviewScreen extends StatelessWidget {
  final File imageFile;
  final String plantType;

  const ImagePreviewScreen({
    super.key,
    required this.imageFile,
    required this.plantType,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('معاينة الصورة'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Image.file(imageFile),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('إلغاء'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<PlantDiseaseApiBloc>().add(
                            PlantDiseaseDiagnosisRequested(
                              imageFile: imageFile,
                              plantType: plantType,
                            ),
                          );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('تشخيص'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
