import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../../core/models/charging_station.dart';
import '../../../core/models/filter_options.dart';
import '../../../core/services/hardware_scraper.dart';
import '../repository/station_repository.dart';
import 'station_state.dart';

class StationCubit extends Cubit<StationState> {
  final StationRepository _repository;
  final HardwareScraper _scraper;
  StreamSubscription<MapEntry<String, HardwareInfo>>? _scraperSub;

  // Full unfiltered station list (enriched with scraped hardware data).
  // Hardware filter is applied here in the cubit, not in the repository,
  // because the GE API never returns manufacturer/model data.
  List<ChargingStation> _allStations = [];

  StationCubit({
    required StationRepository repository,
    required HardwareScraper scraper,
  })  : _repository = repository,
        _scraper = scraper,
        super(const StationState.initial()) {
    _scraperSub = _scraper.updates.listen(_onHardwareUpdate);
  }

  Future<void> loadStations(LatLngBounds bounds) async {
    final filters = _activeFilters;
    emit(StationState.loading(filters: filters));
    await _fetchAndEmit(filters, bounds);
  }

  Future<void> applyFilters(FilterOptions filters, LatLngBounds bounds) async {
    if (state is StationLoaded && _activeFilters == filters) return;
    _repository.clearCache();
    emit(StationState.loading(filters: filters));
    await _fetchAndEmit(filters, bounds);
  }

  Future<void> _fetchAndEmit(FilterOptions filters, LatLngBounds bounds) async {
    try {
      // Fetch stations — only network filter at repository level.
      // Hardware filter applied below using scraped data.
      final networkOnlyFilters =
          filters.copyWith(manufacturers: [], models: []);
      final apiStations = await _repository.getStations(
          bounds: bounds, filters: networkOnlyFilters);

      // Enrich immediately with any already-cached hardware data
      _allStations = _enrich(apiStations);

      final filtered = _applyHardwareFilter(_allStations, filters);
      final availableManufacturers = _extractManufacturers(_allStations);

      if (isClosed) return;
      emit(StationState.loaded(
        stations: filtered,
        filters: filters,
        availableNetworks: _repository.getAvailableNetworks(),
        availableManufacturers: availableManufacturers,
      ));

      // All stations from the API are CCS (we filter by combo_typ2 at API level)
      final urlMap =
          _repository.getUrlsForIds(apiStations.map((s) => s.id).toList());
      _scraper.enqueueStations(urlMap);
    } catch (e) {
      if (isClosed) return;
      emit(StationState.error(message: e.toString(), filters: filters));
    }
  }

  void _onHardwareUpdate(MapEntry<String, HardwareInfo> update) {
    final current = state;
    if (current is! StationLoaded) return;

    // Patch the station in the full unfiltered list
    _allStations = _allStations.map((s) {
      if (s.id != update.key) return s;
      return s.copyWith(
        manufacturer: update.value.manufacturer,
        model: update.value.model,
      );
    }).toList();

    final filtered = _applyHardwareFilter(_allStations, current.filters);
    final availableManufacturers = _extractManufacturers(_allStations);

    emit(current.copyWith(
      stations: filtered,
      availableManufacturers: availableManufacturers,
    ));
  }

  List<ChargingStation> _enrich(List<ChargingStation> stations) {
    return stations.map((s) {
      final hw = _scraper.getCached(s.id);
      if (hw == null) return s;
      return s.copyWith(manufacturer: hw.manufacturer, model: hw.model);
    }).toList();
  }

  List<ChargingStation> _applyHardwareFilter(
      List<ChargingStation> stations, FilterOptions filters) {
    var result = stations;
    if (filters.manufacturers.isNotEmpty) {
      result = result
          .where((s) => filters.manufacturers.contains(s.manufacturer))
          .toList();
    }
    if (filters.models.isNotEmpty) {
      result =
          result.where((s) => filters.models.contains(s.model)).toList();
    }
    return result;
  }

  List<String> _extractManufacturers(List<ChargingStation> stations) {
    return stations
        .map((s) => s.manufacturer)
        .whereType<String>()
        .where((m) => m.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  ChargingStation? getStation(String id) =>
      _allStations.where((s) => s.id == id).firstOrNull;

  FilterOptions get _activeFilters => switch (state) {
        StationLoading(:final filters) => filters,
        StationLoaded(:final filters) => filters,
        StationError(:final filters) => filters,
        _ => const FilterOptions(),
      };

  @override
  Future<void> close() {
    _scraperSub?.cancel();
    return super.close();
  }
}
