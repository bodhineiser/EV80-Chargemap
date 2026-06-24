import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../../core/models/filter_options.dart';
import '../../map/cubit/station_cubit.dart';
import '../../map/cubit/station_state.dart';

class NetworkFilterSheet extends StatefulWidget {
  final LatLngBounds? currentBounds;

  const NetworkFilterSheet({super.key, this.currentBounds});

  @override
  State<NetworkFilterSheet> createState() => _NetworkFilterSheetState();
}

class _NetworkFilterSheetState extends State<NetworkFilterSheet> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    final state = context.read<StationCubit>().state;
    _selected = Set.from(switch (state) {
      StationLoaded(:final filters) => filters.networks,
      StationLoading(:final filters) => filters.networks,
      _ => const <String>[],
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StationCubit, StationState>(
      builder: (context, state) {
        final networks = switch (state) {
          StationLoaded(:final availableNetworks) => availableNetworks,
          _ => <String>[],
        };

        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(children: [
                _header(context),
                Expanded(
                  child: networks.isEmpty
                      ? const Center(
                          child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Pan the map to load stations first.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ))
                      : ListView(
                          controller: scrollController,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: networks
                                  .map((n) => FilterChip(
                                        label: Text(n),
                                        selected: _selected.contains(n),
                                        onSelected: (val) => setState(() {
                                          if (val) {
                                            _selected.add(n);
                                          } else {
                                            _selected.remove(n);
                                          }
                                        }),
                                      ))
                                  .toList(),
                            ),
                          ],
                        ),
                ),
                _actions(context),
              ]),
            );
          },
        );
      },
    );
  }

  Widget _header(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(
            child: Container(
              width: 32,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Text('Network / Operator',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ]),
      );

  Widget _actions(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => setState(() => _selected.clear()),
              child: const Text('Reset'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: widget.currentBounds == null
                  ? null
                  : () {
                      final cubit = context.read<StationCubit>();
                      final current = switch (cubit.state) {
                        StationLoaded(:final filters) => filters,
                        StationLoading(:final filters) => filters,
                        _ => const FilterOptions(),
                      };
                      cubit.applyFilters(
                        current.copyWith(networks: _selected.toList()),
                        widget.currentBounds!,
                      );
                      Navigator.pop(context);
                    },
              child: const Text('Apply'),
            ),
          ),
        ]),
      );
}
