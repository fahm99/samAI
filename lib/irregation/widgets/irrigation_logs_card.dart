import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/irrigation_bloc.dart';
import '../bloc/irrigation_event.dart';
import '../models/irrigation_log.dart';

class IrrigationLogsCard extends StatelessWidget {
  final List<IrrigationLog> logs;
  final String systemId;

  const IrrigationLogsCard({
    super.key,
    required this.logs,
    required this.systemId,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'سجل الري',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (logs.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => _showClearLogsConfirmation(context),
                    icon: const Icon(Icons.delete_sweep,
                        size: 18, color: Colors.red),
                    label: const Text(
                      'مسح السجلات',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (logs.isEmpty)
              const SizedBox(
                height: 100,
                child: Center(
                  child: Text(
                    'لا توجد سجلات ري متاحة',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...logs.take(5).map((log) => _buildLogItem(log)),
            if (logs.length > 5)
              TextButton(
                onPressed: () {},
                child: const Text('عرض جميع السجلات'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogItem(IrrigationLog log) {
    final isOngoing = log.endTime == null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                log.type == 'manual' ? Icons.touch_app : Icons.schedule,
                size: 16,
                color: isOngoing ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                log.type == 'manual' ? 'ري يدوي' : 'ري تلقائي',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isOngoing
                      ? Colors.green.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isOngoing ? 'جاري' : 'مكتمل',
                  style: TextStyle(
                    color: isOngoing ? Colors.green : Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'بدء: ${_formatDateTime(log.startTime)}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          if (log.endTime != null)
            Text(
              'انتهاء: ${_formatDateTime(log.endTime!)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          if (log.durationMinutes != null)
            Text(
              'المدة: ${log.durationMinutes} دقيقة',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          if (log.notes != null && log.notes!.isNotEmpty)
            Text(
              'ملاحظات: ${log.notes}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showClearLogsConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('مسح سجلات الري'),
        content: const Text(
            'هل أنت متأكد من مسح جميع سجلات الري؟ لا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<IrrigationBloc>().add(
                    ClearIrrigationLogsEvent(systemId: systemId),
                  );
            },
            child: const Text('مسح', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
