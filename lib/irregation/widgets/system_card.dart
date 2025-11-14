import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../services/supabaseservice.dart';
import '../bloc/irrigation_bloc.dart';
import '../bloc/irrigation_event.dart';
import '../models/irrigation_system.dart';

class SystemCard extends StatelessWidget {
  final IrrigationSystem system;

  const SystemCard({super.key, required this.system});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.water_drop,
                  color: system.isActive
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).disabledColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    system.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildSoilMoistureIndicator(system.id),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: system.isActive
                        ? Theme.of(context).primaryColor.withOpacity(0.1)
                        : Theme.of(context).disabledColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    system.isActive ? 'نشط' : 'متوقف',
                    style: TextStyle(
                      color: system.isActive
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).disabledColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.memory, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'رقم الجهاز: ${system.deviceSerial}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.agriculture, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'نوع المحصول: ${system.cropType}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            if (system.location != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'الموقع: ${system.location}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
            if (system.areaSize != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.square_foot, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'المساحة: ${system.areaSize} متر مربع',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.read<IrrigationBloc>().add(
                            LoadSystemDetailsEvent(systemId: system.id),
                          );
                    },
                    icon: const Icon(Icons.visibility),
                    label: const Text('عرض التفاصيل'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: const Color(0xFF2E7D32),
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      side: const BorderSide(color: Color(0xFF2E7D32)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: system.isActive,
                  onChanged: (value) {
                    context.read<IrrigationBloc>().add(
                          ToggleSystemEvent(
                              systemId: system.id, isActive: value),
                        );
                  },
                  activeColor: const Color(0xFF2E7D32),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoilMoistureIndicator(String systemId) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: SupabaseService().sensorDataPollingStream(systemId, limit: 1),
      builder: (context, snapshot) {
        double? soilMoisture;

        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final latestData = snapshot.data!.first;
          soilMoisture = latestData['soil_moisture']?.toDouble();
        }

        if (soilMoisture == null) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.water_drop, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                Text('--', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          );
        }

        Color backgroundColor;
        Color textColor;
        IconData icon;

        if (soilMoisture < 30) {
          backgroundColor = Colors.red.withOpacity(0.2);
          textColor = Colors.red[700]!;
          icon = Icons.warning;
        } else if (soilMoisture >= 70) {
          backgroundColor = Colors.green.withOpacity(0.2);
          textColor = Colors.green[700]!;
          icon = Icons.check_circle;
        } else {
          backgroundColor = Colors.blue.withOpacity(0.2);
          textColor = Colors.blue[700]!;
          icon = Icons.water_drop;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: textColor),
              const SizedBox(width: 4),
              Text(
                '${soilMoisture.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
