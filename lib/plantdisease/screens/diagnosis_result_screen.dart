import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../theme/theme.dart';
import '../bloc/plant_disease_bloc.dart';
import '../bloc/plant_disease_event.dart';

class DiagnosisResultScreen extends StatelessWidget {
  final File imageFile;
  final Map<String, dynamic> diagnosis;
  final Map<String, dynamic> diseaseInfo;

  const DiagnosisResultScreen({
    super.key,
    required this.imageFile,
    required this.diagnosis,
    required this.diseaseInfo,
  });

  @override
  Widget build(BuildContext context) {
    final isHealthy = diagnosis['is_healthy'] ?? false;
    final confidence = (diagnosis['confidence_score'] ?? 0.0) * 100;

    return Scaffold(
      appBar: AppBar(
        title: const Text('نتيجة التشخيص'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageCard(isHealthy, confidence),
            const SizedBox(height: 16),
            if (diagnosis['plant_name'] != null) ...[
              _buildPlantInfoCard(),
              const SizedBox(height: 16),
            ],
            if (diseaseInfo['disease']?['description'] != null) ...[
              _buildDescriptionCard(),
              const SizedBox(height: 16),
            ],
            if (diseaseInfo['disease']?['symptoms'] != null) ...[
              _buildSymptomsCard(),
              const SizedBox(height: 16),
            ],
            if (diagnosis['treatments'] != null) ...[
              _buildTreatmentCard(),
              const SizedBox(height: 16),
            ],
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCard(bool isHealthy, double confidence) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                imageFile,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  isHealthy ? Icons.check_circle : Icons.warning,
                  color: isHealthy ? Colors.green : Colors.orange,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        diagnosis['predicted_disease'] ?? 'غير محدد',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'الثقة: ${confidence.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlantInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'معلومات النبات',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('الاسم: ${diagnosis['plant_name']}'),
            if (diagnosis['plant_name_english'] != null)
              Text('الاسم الإنجليزي: ${diagnosis['plant_name_english']}'),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'الوصف',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(diseaseInfo['disease']['description']),
          ],
        ),
      ),
    );
  }

  Widget _buildSymptomsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'الأعراض',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...((diseaseInfo['disease']['symptoms'] as List<dynamic>?) ?? [])
                .map((symptom) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• '),
                          Expanded(child: Text(symptom.toString())),
                        ],
                      ),
                    )),
          ],
        ),
      ),
    );
  }

  Widget _buildTreatmentCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'العلاج المقترح',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...((diagnosis['treatments'] as List<dynamic>?) ?? [])
                .map((treatment) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            treatment['title'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (treatment['description'] != null)
                            Text(treatment['description']),
                          if (treatment['steps'] != null) ...[
                            const SizedBox(height: 4),
                            ...((treatment['steps'] as List<dynamic>?) ?? [])
                                .map((step) => Padding(
                                      padding: const EdgeInsets.only(
                                          left: 16, bottom: 2),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text('• '),
                                          Expanded(
                                              child: Text(step.toString())),
                                        ],
                                      ),
                                    )),
                          ],
                        ],
                      ),
                    )),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              context.read<PlantDiseaseApiBloc>().add(
                    PlantDiseaseSaveRequested(diagnosisData: diagnosis),
                  );
            },
            child: const Text('حفظ التشخيص'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              context.read<PlantDiseaseApiBloc>().add(
                    PlantDiseaseDataRequested(),
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('تشخيص جديد'),
          ),
        ),
      ],
    );
  }
}
