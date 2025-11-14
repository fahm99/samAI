import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/irrigation_bloc.dart';
import '../bloc/irrigation_event.dart';
import '../models/irrigation_system.dart';
import '../widgets/auto_irrigation_settings_dialog.dart';

class ControlButtonsCard extends StatelessWidget {
  final IrrigationSystem system;

  const ControlButtonsCard({super.key, required this.system});

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
                Icon(Icons.control_camera, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'أزرار التحكم',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildManualControlCard(context),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildAutoControlCard(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (system.autoIrrigationEnabled)
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) =>
                          AutoIrrigationSettingsDialog(systemId: system.id),
                    );
                  },
                  icon: const Icon(Icons.settings),
                  label: const Text('إعدادات الري التلقائي'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualControlCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: system.isActive && !system.autoIrrigationEnabled
            ? Colors.green.withOpacity(0.1)
            : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: system.isActive && !system.autoIrrigationEnabled
              ? Colors.green
              : Colors.grey[300]!,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.touch_app,
            color: system.isActive && !system.autoIrrigationEnabled
                ? Colors.green
                : Colors.grey,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'ري يدوي',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: system.isActive && !system.autoIrrigationEnabled
                  ? Colors.green
                  : Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Switch.adaptive(
            value: system.isActive && !system.autoIrrigationEnabled,
            onChanged: (value) {
              if (value) {
                if (system.autoIrrigationEnabled) {
                  context.read<IrrigationBloc>().add(
                        SetAutoIrrigationEvent(
                          systemId: system.id,
                          enabled: false,
                        ),
                      );
                }
                context.read<IrrigationBloc>().add(
                      ToggleSystemEvent(
                        systemId: system.id,
                        isActive: true,
                      ),
                    );
              } else {
                context.read<IrrigationBloc>().add(
                      ToggleSystemEvent(
                        systemId: system.id,
                        isActive: false,
                      ),
                    );
              }
            },
            activeColor: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildAutoControlCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: system.autoIrrigationEnabled
            ? Colors.blue.withOpacity(0.1)
            : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: system.autoIrrigationEnabled ? Colors.blue : Colors.grey[300]!,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.smart_toy,
            color: system.autoIrrigationEnabled ? Colors.blue : Colors.grey,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'ري تلقائي',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: system.autoIrrigationEnabled ? Colors.blue : Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Switch.adaptive(
            value: system.autoIrrigationEnabled,
            onChanged: (value) {
              if (value) {
                if (system.isActive) {
                  context.read<IrrigationBloc>().add(
                        ToggleSystemEvent(
                          systemId: system.id,
                          isActive: false,
                        ),
                      );
                }
                context.read<IrrigationBloc>().add(
                      SetAutoIrrigationEvent(
                        systemId: system.id,
                        enabled: true,
                      ),
                    );
              } else {
                context.read<IrrigationBloc>().add(
                      SetAutoIrrigationEvent(
                        systemId: system.id,
                        enabled: false,
                      ),
                    );
              }
            },
            activeColor: Colors.blue,
          ),
        ],
      ),
    );
  }
}
