import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/irrigation_bloc.dart';
import '../bloc/irrigation_event.dart';

class AutoIrrigationSettingsDialog extends StatefulWidget {
  final String systemId;

  const AutoIrrigationSettingsDialog({super.key, required this.systemId});

  @override
  State<AutoIrrigationSettingsDialog> createState() =>
      _AutoIrrigationSettingsDialogState();
}

class _AutoIrrigationSettingsDialogState
    extends State<AutoIrrigationSettingsDialog> {
  final startController = TextEditingController();
  final stopController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إعدادات الري التلقائي'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: startController,
            decoration: const InputDecoration(labelText: 'عتبة بدء الري (%)'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: stopController,
            decoration: const InputDecoration(labelText: 'عتبة إيقاف الري (%)'),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            context.read<IrrigationBloc>().add(
                  UpdateAutoIrrigationSettingsEvent(
                    systemId: widget.systemId,
                    startThreshold: double.tryParse(startController.text),
                    stopThreshold: double.tryParse(stopController.text),
                  ),
                );
          },
          child: const Text('حفظ'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    startController.dispose();
    stopController.dispose();
    super.dispose();
  }
}
