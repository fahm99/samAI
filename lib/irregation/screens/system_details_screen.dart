import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/irrigation_bloc.dart';
import '../bloc/irrigation_event.dart';
import '../bloc/irrigation_state.dart';
import '../widgets/system_info_card.dart';
import '../widgets/control_buttons_card.dart';
import '../widgets/sensor_data_card.dart';
import '../widgets/irrigation_logs_card.dart';

class SystemDetailsScreen extends StatelessWidget {
  final SystemDetailsLoaded state;

  const SystemDetailsScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(state.system.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.read<IrrigationBloc>().add(LoadIrrigationSystemsEvent());
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<IrrigationBloc>().add(
                    RefreshSensorDataEvent(systemId: state.system.id),
                  );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SystemInfoCard(system: state.system),
            const SizedBox(height: 16),
            ControlButtonsCard(system: state.system),
            const SizedBox(height: 16),
            SensorDataCard(
              sensorData: state.sensorData,
              pumpStatus: state.system.isActive,
            ),
            const SizedBox(height: 16),
            IrrigationLogsCard(
              logs: state.irrigationLogs,
              systemId: state.system.id,
            ),
          ],
        ),
      ),
    );
  }
}
