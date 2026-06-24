import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/api/going_electric_client.dart';
import '../../../core/api/dto/ge_station_dto.dart';
import '../../../core/models/charging_station.dart';
import '../../../core/models/connector.dart';
import '../../../core/models/filter_options.dart';

class StationRepository {
  final GoingElectricClient _client;
  final Map<String, List<ChargingStation>> _cache = {};
  List<String> _cachedNetworks = [];
  // Station URLs (ge_id → full URL) — persists across cache clears for scraping
  final Map<String, String> _stationUrls = {};

  StationRepository({required GoingElectricClient client}) : _client = client;

  Future<List<ChargingStation>> getStations({
    required LatLngBounds bounds,
    FilterOptions filters = const FilterOptions(),
  }) async {
    final cacheKey = _cacheKey(bounds, filters);
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey]!;

    final center = bounds.center;
    final radiusKm = _boundsRadiusKm(bounds);

    final dto = await _client.getStations(
      lat: center.latitude,
      lng: center.longitude,
      radiusKm: radiusKm,
    );

    // Build full list — hardware (manufacturer/model) always null from API
    final all = dto.chargepoints.map(_toStation).toList();
    _updateFilterLists(all);

    // Apply network filter client-side (hardware filtering done in cubit with scraped data)
    var stations = all;
    if (filters.networks.isNotEmpty) {
      stations =
          stations.where((s) => filters.networks.contains(s.network)).toList();
    }

    _cache[cacheKey] = stations;
    return stations;
  }

  List<String> getAvailableNetworks() => List.unmodifiable(_cachedNetworks);

  /// Returns a map of ge_id → URL for the given station IDs.
  Map<String, String> getUrlsForIds(List<String> ids) {
    final result = <String, String>{};
    for (final id in ids) {
      final url = _stationUrls[id];
      if (url != null) result[id] = url;
    }
    return result;
  }

  void clearCache() {
    _cache.clear();
    _cachedNetworks = [];
    // _stationUrls is intentionally NOT cleared — scraper cache persists across filter changes
  }

  void _updateFilterLists(List<ChargingStation> stations) {
    _cachedNetworks = stations
        .map((s) => s.network)
        .where((n) => n.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  ChargingStation _toStation(GeStationDto dto) {
    if (dto.url != null) _stationUrls[dto.id] = dto.url!;
    return ChargingStation(
      id: dto.id,
      name: dto.name,
      address: dto.address,
      latitude: dto.latitude,
      longitude: dto.longitude,
      network: dto.network ?? 'Unknown',
      connectors: dto.connectors.map(_toConnector).toList(),
    );
  }

  Connector _toConnector(GeConnectorDto dto) => Connector(
        type: dto.type,
        powerKw: dto.power?.round(),
      );

  String _cacheKey(LatLngBounds bounds, FilterOptions filters) {
    final b =
        '${bounds.south.toStringAsFixed(2)},${bounds.west.toStringAsFixed(2)},'
        '${bounds.north.toStringAsFixed(2)},${bounds.east.toStringAsFixed(2)}';
    final networks = [...filters.networks]..sort();
    return '$b|${networks.join(',')}';
  }

  double _boundsRadiusKm(LatLngBounds bounds) {
    const d = Distance();
    return d(bounds.center, bounds.northEast) / 1000;
  }
}
