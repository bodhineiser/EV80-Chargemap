import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../../core/models/filter_options.dart';
import '../../../core/services/hardware_scraper.dart';
import '../../map/cubit/station_cubit.dart';
import '../../map/cubit/station_state.dart';

class HardwareFilterSheet extends StatefulWidget {
  final LatLngBounds? currentBounds;

  const HardwareFilterSheet({super.key, this.currentBounds});

  @override
  State<HardwareFilterSheet> createState() => _HardwareFilterSheetState();
}

class _HardwareFilterSheetState extends State<HardwareFilterSheet> {
  late Set<String> _selectedManufacturers;
  late Set<String> _selectedModels;
  String _manufacturerQuery = '';
  String _modelQuery = '';

  @override
  void initState() {
    super.initState();
    final filters = switch (context.read<StationCubit>().state) {
      StationLoaded(:final filters) => filters,
      StationLoading(:final filters) => filters,
      _ => const FilterOptions(),
    };
    _selectedManufacturers = Set.from(filters.manufacturers);
    _selectedModels = Set.from(filters.models);
  }

  @override
  Widget build(BuildContext context) {
    final allManufacturers = switch (context.watch<StationCubit>().state) {
      StationLoaded(:final availableManufacturers) => availableManufacturers,
      _ => <String>[],
    };

    final scraper = GetIt.instance<HardwareScraper>();
    final allModels = _selectedManufacturers.isNotEmpty
        ? scraper.getModelsForManufacturers(_selectedManufacturers.toList())
        : <String>[];

    final shownManufacturers = allManufacturers
        .where(
            (m) => m.toLowerCase().contains(_manufacturerQuery.toLowerCase()))
        .toList();
    final shownModels = allModels
        .where((m) => m.toLowerCase().contains(_modelQuery.toLowerCase()))
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
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
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _sectionLabel(context, 'Manufacturer'),
                  const SizedBox(height: 8),
                  _searchField(
                    hint: 'Search manufacturers...',
                    onChanged: (v) =>
                        setState(() => _manufacturerQuery = v),
                  ),
                  const SizedBox(height: 4),
                  if (allManufacturers.isEmpty)
                    _emptyHint(
                        'Loading hardware data — pan the map and wait a moment.')
                  else if (shownManufacturers.isEmpty)
                    _emptyHint('No matches.')
                  else
                    ...shownManufacturers.map((m) => CheckboxListTile(
                          title: Text(m,
                              style: const TextStyle(fontSize: 14)),
                          value: _selectedManufacturers.contains(m),
                          dense: true,
                          onChanged: (val) => setState(() {
                            if (val == true) {
                              _selectedManufacturers.add(m);
                            } else {
                              _selectedManufacturers.remove(m);
                              final mModels = scraper
                                  .getModelsForManufacturers([m]);
                              _selectedModels.removeAll(mModels);
                            }
                          }),
                        )),
                  if (_selectedManufacturers.isNotEmpty) ...[
                    const Divider(height: 24),
                    _sectionLabel(context, 'Model'),
                    const SizedBox(height: 8),
                    _searchField(
                      hint: 'Search models...',
                      onChanged: (v) =>
                          setState(() => _modelQuery = v),
                    ),
                    const SizedBox(height: 4),
                    if (allModels.isEmpty)
                      _emptyHint(
                          'No model data for selected manufacturers.')
                    else if (shownModels.isEmpty)
                      _emptyHint('No matches.')
                    else
                      ...shownModels.map((m) => CheckboxListTile(
                            title: Text(m,
                                style: const TextStyle(fontSize: 14)),
                            value: _selectedModels.contains(m),
                            dense: true,
                            onChanged: (val) => setState(() {
                              if (val == true) {
                                _selectedModels.add(m);
                              } else {
                                _selectedModels.remove(m);
                              }
                            }),
                          )),
                  ],
                ],
              ),
            ),
            _actions(context),
          ]),
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
          Text('Hardware',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ]),
      );

  Widget _sectionLabel(BuildContext context, String label) => Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(color: Colors.grey),
      );

  Widget _searchField(
          {required String hint,
          required ValueChanged<String> onChanged}) =>
      TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search, size: 18),
          border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
      );

  Widget _emptyHint(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(text, style: const TextStyle(color: Colors.grey)),
      );

  Widget _actions(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => setState(() {
                _selectedManufacturers.clear();
                _selectedModels.clear();
              }),
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
                        current.copyWith(
                          manufacturers:
                              _selectedManufacturers.toList(),
                          models: _selectedModels.toList(),
                        ),
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
