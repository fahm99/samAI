import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../theme/theme.dart';
import '../bloc/plant_disease_bloc.dart';
import '../bloc/plant_disease_event.dart';
import '../models/plant_types.dart';

class PlantDiseaseMainScreen extends StatefulWidget {
  final List<Map<String, dynamic>> diagnoses;
  final String selectedPlantType;

  const PlantDiseaseMainScreen({
    super.key,
    required this.diagnoses,
    required this.selectedPlantType,
  });

  @override
  State<PlantDiseaseMainScreen> createState() => _PlantDiseaseMainScreenState();
}

class _PlantDiseaseMainScreenState extends State<PlantDiseaseMainScreen> {
  String _selectedPlantType = 'طماطم';

  @override
  void initState() {
    super.initState();
    _selectedPlantType = widget.selectedPlantType;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Plant Type Selector
          Container(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              value: _selectedPlantType,
              decoration: const InputDecoration(
                labelText: 'نوع النبات',
                border: OutlineInputBorder(),
              ),
              items: PlantTypes.supportedPlants.entries
                  .map((entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value['displayName']!),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedPlantType = value;
                  });
                  context.read<PlantDiseaseApiBloc>().add(
                        PlantTypeChanged(plantType: value),
                      );
                }
              },
            ),
          ),
          // Diagnoses List
          Expanded(
            child: widget.diagnoses.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.eco, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'لا توجد تشخيصات سابقة',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'اضغط على زر الكاميرا لبدء التشخيص',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: widget.diagnoses.length,
                    itemBuilder: (context, index) {
                      final diagnosis = widget.diagnoses[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: ListTile(
                          leading:
                              const Icon(Icons.eco, color: AppColors.primary),
                          title: Text(
                              diagnosis['predicted_disease'] ?? 'غير محدد'),
                          subtitle: Text(
                            'النبات: ${diagnosis['plant_type'] ?? 'غير محدد'}\n'
                            'التاريخ: ${diagnosis['created_at'] ?? 'غير محدد'}',
                          ),
                          trailing: Text(
                            '${((diagnosis['confidence_score'] ?? 0.0) * 100).toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
