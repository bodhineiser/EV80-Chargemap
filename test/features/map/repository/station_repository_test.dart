import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ev80_chargers/core/api/going_electric_client.dart';
import 'package:ev80_chargers/core/api/dto/ge_station_dto.dart';
import 'package:ev80_chargers/core/models/filter_options.dart';
import 'package:ev80_chargers/features/map/repository/station_repository.dart';

class MockGoingElectricClient extends Mock implements GoingElectricClient {}

final _bounds = LatLngBounds(
  const LatLng(47.0, 9.0),
  const LatLng(48.0, 10.0),
);

GeStationListDto _makeList(List<GeStationDto> stations) =>
    GeStationListDto(status: 'ok', chargepoints: stations);

GeStationDto _makeStation({
  String id = '1',
  String? network,
  String? url,
}) =>
    GeStationDto(
      id: id,
      name: 'Station $id',
      latitude: 47.5,
      longitude: 9.5,
      address: 'Test Street, Test City',
      network: network,
      url: url,
      connectors: [],
    );

void main() {
  late MockGoingElectricClient mockClient;
  late StationRepository repo;

  setUp(() {
    mockClient = MockGoingElectricClient();
    repo = StationRepository(client: mockClient);
  });

  test('returns stations from API on cache miss', () async {
    when(() => mockClient.getStations(
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
          radiusKm: any(named: 'radiusKm'),
          count: any(named: 'count'),
        )).thenAnswer(
      (_) async => _makeList([_makeStation(network: 'Ionity')]),
    );

    final stations = await repo.getStations(bounds: _bounds);

    expect(stations.length, 1);
    expect(stations.first.network, 'Ionity');
  });

  test('returns cached result on identical second call', () async {
    when(() => mockClient.getStations(
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
          radiusKm: any(named: 'radiusKm'),
          count: any(named: 'count'),
        )).thenAnswer((_) async => _makeList([_makeStation()]));

    await repo.getStations(bounds: _bounds);
    await repo.getStations(bounds: _bounds);

    verify(() => mockClient.getStations(
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
          radiusKm: any(named: 'radiusKm'),
          count: any(named: 'count'),
        )).called(1);
  });

  test('clearCache forces re-fetch', () async {
    when(() => mockClient.getStations(
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
          radiusKm: any(named: 'radiusKm'),
          count: any(named: 'count'),
        )).thenAnswer((_) async => _makeList([_makeStation()]));

    await repo.getStations(bounds: _bounds);
    repo.clearCache();
    await repo.getStations(bounds: _bounds);

    verify(() => mockClient.getStations(
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
          radiusKm: any(named: 'radiusKm'),
          count: any(named: 'count'),
        )).called(2);
  });

  test('filters by network client-side', () async {
    when(() => mockClient.getStations(
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
          radiusKm: any(named: 'radiusKm'),
          count: any(named: 'count'),
        )).thenAnswer((_) async => _makeList([
          _makeStation(id: '1', network: 'Ionity'),
          _makeStation(id: '2', network: 'EnBW'),
        ]));

    const filters = FilterOptions(networks: ['Ionity']);
    final stations =
        await repo.getStations(bounds: _bounds, filters: filters);

    expect(stations.length, 1);
    expect(stations.first.network, 'Ionity');
  });

  test('hardware filter is ignored at repository level (applied in cubit)', () async {
    when(() => mockClient.getStations(
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
          radiusKm: any(named: 'radiusKm'),
          count: any(named: 'count'),
        )).thenAnswer((_) async => _makeList([
          _makeStation(id: '1'),
          _makeStation(id: '2'),
        ]));

    const filters = FilterOptions(manufacturers: ['ABB']);
    final stations =
        await repo.getStations(bounds: _bounds, filters: filters);

    expect(stations.length, 2);
  });

  test('getUrlsForIds returns stored URLs', () async {
    when(() => mockClient.getStations(
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
          radiusKm: any(named: 'radiusKm'),
          count: any(named: 'count'),
        )).thenAnswer((_) async => _makeList([
          _makeStation(
              id: '42',
              url: 'https://www.goingelectric.de/stromtankstellen/.../42/'),
        ]));

    await repo.getStations(bounds: _bounds);
    final urls = repo.getUrlsForIds(['42', '99']);

    expect(urls['42'],
        'https://www.goingelectric.de/stromtankstellen/.../42/');
    expect(urls['99'], isNull);
  });
}
