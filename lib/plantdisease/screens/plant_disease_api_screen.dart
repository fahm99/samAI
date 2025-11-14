import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/supabaseservice.dart';
import '../../theme/theme.dart';
import '../bloc/plant_disease_bloc.dart';
import '../bloc/plant_disease_event.dart';
import '../bloc/plant_disease_state.dart';
import 'plant_disease_main_screen.dart';
import 'image_preview_screen.dart';
import 'diagnosing_screen.dart';
import 'diagnosis_result_screen.dart';

class PlantDiseaseApiScreen extends StatelessWidget {
  const PlantDiseaseApiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PlantDiseaseApiBloc(SupabaseService())
        ..add(PlantDiseaseDataRequested()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تشخيص أمراض النباتات'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: BlocBuilder<PlantDiseaseApiBloc, PlantDiseaseState>(
          builder: (context, state) {
            if (state is PlantDiseaseLoading) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'جاري التحضير...',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              );
            } else if (state is PlantDiseaseError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: AppColors.error),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context
                            .read<PlantDiseaseApiBloc>()
                            .add(PlantDiseaseDataRequested());
                      },
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              );
            } else if (state is PlantDiseaseImagePreview) {
              return ImagePreviewScreen(
                imageFile: state.imageFile,
                plantType: state.plantType,
              );
            } else if (state is PlantDiseaseDiagnosing) {
              return DiagnosingScreen(imageFile: state.imageFile);
            } else if (state is PlantDiseaseDiagnosed) {
              return DiagnosisResultScreen(
                imageFile: state.imageFile,
                diagnosis: state.diagnosis,
                diseaseInfo: state.diseaseInfo,
              );
            } else if (state is PlantDiseaseLoaded) {
              return PlantDiseaseMainScreen(
                diagnoses: state.diagnoses,
                selectedPlantType: state.selectedPlantType,
              );
            }
            return const SizedBox();
          },
        ),
        floatingActionButton:
            BlocBuilder<PlantDiseaseApiBloc, PlantDiseaseState>(
          builder: (context, state) {
            if (state is PlantDiseaseLoaded) {
              return FloatingActionButton(
                onPressed: () =>
                    _showImageSourceDialog(context, state.selectedPlantType),
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.camera_alt, color: Colors.white),
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }

  void _showImageSourceDialog(BuildContext context, String plantType) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('التقاط صورة'),
              onTap: () async {
                Navigator.pop(context);
                final image =
                    await ImagePicker().pickImage(source: ImageSource.camera);
                if (image != null) {
                  context.read<PlantDiseaseApiBloc>().add(
                        PlantDiseaseImageSelected(
                          imageFile: File(image.path),
                          plantType: plantType,
                        ),
                      );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('من المعرض'),
              onTap: () async {
                Navigator.pop(context);
                final image =
                    await ImagePicker().pickImage(source: ImageSource.gallery);
                if (image != null) {
                  context.read<PlantDiseaseApiBloc>().add(
                        PlantDiseaseImageSelected(
                          imageFile: File(image.path),
                          plantType: plantType,
                        ),
                      );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
