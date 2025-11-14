import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';

import '../../services/offline_manager.dart';
import '../bloc/irrigation_bloc.dart';
import '../bloc/irrigation_event.dart';
import '../bloc/irrigation_state.dart';
import '../models/irrigation_system.dart';
import '../widgets/irrigation_summary_card.dart';
import '../widgets/system_card.dart';
import 'system_details_screen.dart';

class IrrigationScreen extends StatefulWidget {
  const IrrigationScreen({super.key});

  @override
  State<IrrigationScreen> createState() => _IrrigationScreenState();
}

class _IrrigationScreenState extends State<IrrigationScreen> with OfflineMixin {
  @override
  void initState() {
    super.initState();
    context.read<IrrigationBloc>().add(LoadIrrigationSystemsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<IrrigationBloc, IrrigationState>(
        listener: (context, state) {
          if (state is IrrigationError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
                duration: const Duration(seconds: 4),
              ),
            );
          } else if (state is IrrigationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.primary,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        child: BlocBuilder<IrrigationBloc, IrrigationState>(
          builder: (context, state) {
            return _buildContent(state);
          },
        ),
      ),
    );
  }

  Widget _buildContent(IrrigationState state) {
    if (state is IrrigationLoading) {
      return _buildShimmerLoading();
    } else if (state is IrrigationSystemsLoaded) {
      return _buildSystemsList(state.systems);
    } else if (state is SystemDetailsLoaded) {
      return SystemDetailsScreen(state: state);
    } else if (state is IrrigationError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error,
                size: 64, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(
              state.message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context
                    .read<IrrigationBloc>()
                    .add(LoadIrrigationSystemsEvent());
              },
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }
    return Container();
  }

  Widget _buildSystemsList(List<IrrigationSystem> systems) {
    if (systems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.water_drop_outlined,
                size: 64, color: Theme.of(context).disabledColor),
            const SizedBox(height: 16),
            Text(
              'لا توجد أنظمة ري',
              style: TextStyle(
                  fontSize: 18, color: Theme.of(context).disabledColor),
            ),
            const SizedBox(height: 8),
            Text(
              'لا توجد أنظمة ري مضافة حالياً',
              style: TextStyle(color: Theme.of(context).disabledColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final activeSystems = systems.where((s) => s.isActive).length;
    final autoSystems = systems.where((s) => s.autoIrrigationEnabled).length;

    return RefreshIndicator(
      onRefresh: () async {
        context.read<IrrigationBloc>().add(LoadIrrigationSystemsEvent());
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: systems.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return IrrigationSummaryCard(
              totalSystems: systems.length,
              activeSystems: activeSystems,
              autoSystems: autoSystems,
            );
          }
          final system = systems[index - 1];
          return SystemCard(system: system);
        },
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );
      },
    );
  }
}
