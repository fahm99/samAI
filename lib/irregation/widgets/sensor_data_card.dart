import 'package:flutter/material.dart';
import '../models/sensor_data.dart';

class SensorDataCard extends StatelessWidget {
  final List<SensorData> sensorData;
  final bool pumpStatus;

  const SensorDataCard({
    super.key,
    required this.sensorData,
    this.pumpStatus = false,
  });

  @override
  Widget build(BuildContext context) {
    if (sensorData.isEmpty) {
      return const Card(
        elevation: 4,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.sensors, color: Colors.orange),
                  SizedBox(width: 8),
                  Text(
                    'بيانات الحساسات',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              SizedBox(
                height: 100,
                child: Center(
                  child: Text(
                    'لا توجد بيانات حساسات متاحة',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final latest = sensorData.first;
    final sensors = [
      {
        'label': 'رطوبة التربة',
        'value': latest.soilMoisture != null
            ? '${latest.soilMoisture!.toStringAsFixed(1)}%'
            : '--',
        'icon': Icons.water_drop,
        'color': _getSoilMoistureColor(latest.soilMoisture),
        'unit': '%'
      },
      {
        'label': 'درجة الحرارة',
        'value': latest.temperature != null
            ? '${latest.temperature!.toStringAsFixed(1)}°C'
            : '--',
        'icon': Icons.thermostat,
        'color': Colors.orange,
        'unit': '°C'
      },
      {
        'label': 'الرطوبة الجوية',
        'value': latest.humidity != null
            ? '${latest.humidity!.toStringAsFixed(1)}%'
            : '--',
        'icon': Icons.opacity,
        'color': Colors.cyan,
        'unit': '%'
      },
      {
        'label': 'منسوب المياه',
        'value': latest.waterLevel != null
            ? '${latest.waterLevel!.toStringAsFixed(1)}%'
            : '--',
        'icon': Icons.water,
        'color': Colors.blue[700]!,
        'unit': '%'
      },
      {
        'label': 'هطول المطر',
        'value': latest.rainDetected == true ? 'يوجد مطر' : 'لا يوجد',
        'icon': Icons.umbrella,
        'color': latest.rainDetected == true ? Colors.blue : Colors.grey,
        'unit': ''
      },
      {
        'label': 'حالة المضخة',
        'value': pumpStatus ? 'تشغيل' : 'إيقاف',
        'icon': pumpStatus ? Icons.power : Icons.power_off,
        'color': pumpStatus ? Colors.green : Colors.red,
        'unit': ''
      },
    ];

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.sensors, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'بيانات الحساسات',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const Spacer(),
                Text(
                  'آخر تحديث: ${_formatTime(latest.timestamp)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
              ),
              itemCount: sensors.length,
              itemBuilder: (context, index) {
                final sensor = sensors[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (sensor['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (sensor['color'] as Color).withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        sensor['icon'] as IconData,
                        color: sensor['color'] as Color,
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        sensor['label'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sensor['value'] as String,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: sensor['color'] as Color,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getSoilMoistureColor(double? moisture) {
    if (moisture == null) return Colors.grey;
    if (moisture < 30) return Colors.red;
    if (moisture < 60) return Colors.orange;
    return Colors.green;
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
