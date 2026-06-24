import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../../../core/models/filter_options.dart';
import '../../cubit/station_cubit.dart';
import '../../cubit/station_state.dart';

class ActiveFilterStrip extends StatelessWidget {
  final LatLngBounds? currentBounds;

  const ActiveFilterStrip({super.key, this.currentBounds});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StationCubit, StationState>(
      builder: (context, state) {
        final filters = switch (state) {
          StationLoaded(:final filters) => filters,
          StationLoading(:final filters) => filters,
          StationError(:final filters) => filters,
          _ => null,
        };

        if (filters == null || filters.isEmpty) return const SizedBox.shrink();

        final chips = [
          ...filters.networks.map((n) => _chip(n, Colors.blue)),
          ...filters.manufacturers.map((m) => _chip(m, Colors.green)),
          ...filters.models.map((m) => _chip(m, Colors.orange)),
        ];

        return Container(
          color: Theme.of(context).colorScheme.surface,
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(children: [
            Expanded(child: Wrap(spacing: 6, children: chips)),
            TextButton(
              onPressed: currentBounds == null
                  ? null
                  : () => context.read<StationCubit>().applyFilters(
                        const FilterOptions(),
                        currentBounds!,
                      ),
              child: const Text('Clear'),
            ),
          ]),
        );
      },
    );
  }

  Widget _chip(String label, Color color) => Chip(
        label: Text(label,
            style: TextStyle(color: color, fontSize: 11)),
        backgroundColor: color.withValues(alpha: 0.1),
        side: BorderSide(color: color.withValues(alpha: 0.4)),
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      );
}
