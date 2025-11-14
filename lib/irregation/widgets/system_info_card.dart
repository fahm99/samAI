import 'package:flutter/material.dart';
import '../models/irrigation_system.dart';

class SystemInfoCard extends StatelessWidget {
  final IrrigationSystem system;

  const SystemInfoCard({super.key, required this.system});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFF2E7D32)),
                SizedBox(width: 8),
                Text(
                  'معلومات النظام',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  _buildInfoRow('الاسم', system.name),
                  _buildInfoRow('رقم الجهاز', system.deviceSerial),
                  _buildInfoRow('نوع المحصول', system.cropType),
                  if (system.areaSize != null)
                    _buildInfoRow('المساحة', '${system.areaSize} متر مربع'),
                  if (system.location != null)
                    _buildInfoRow('الموقع', system.location!),
                  _buildInfoRow(
                      'عتبة انخفاض المياه', '${system.waterLowThreshold}%'),
                  Row(
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(
                          'الحالة:',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: system.isActive
                              ? Colors.green.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: system.isActive ? Colors.green : Colors.grey,
                          ),
                        ),
                        child: Text(
                          system.isActive ? 'نشط' : 'متوقف',
                          style: TextStyle(
                            color: system.isActive ? Colors.green : Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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
}
