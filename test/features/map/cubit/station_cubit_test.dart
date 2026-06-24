import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ev80_chargers/core/models/charging_station.dart';
import 'package:ev80_chargers/core/models/filter_options.dart';
import 'package:ev80_chargers/core/services/hardware_scraper.dart';
import 'package:ev80_chargers/features/map/cubit/station_cubit.dart';
import 'package:ev80_chargers/features/map/cubit/station_state.dart';
import 'package:ev80_chargers/features/map/repository/station_repository.dart';

class MockStationRepository extends Mock implements StationRepository {}
class MockHardwareScraper extends Mock implements HardwareScraper {}

final _bounds =
    LatLngBounds(const LatLng(47.0, 9.0), const LatLng(48.0, 10.0));

const _station = ChargingStation(
  id: '1',
  name: 'Test',
  address: 'Addr',
  latitude: 47.5,
  longitude: 9.5,
  network: 'Ionity',
);

void main() {
  late MockStationRepository mockRepo;
  late MockHardwareScraper mockScraper;

  setUp(() {
    mockRepo = MockStationRepository();
    mockScraper = MockHardwareScraper();
    registerFallbackValue(const FilterOptions());
    registerFallbackValue(_bounds);

    when(() => mockRepo.getAvailableNetworks()).thenReturn([]);
    when(() => mockRepo.getUrlsForIds(any())).thenReturn({});
    when(() => mockScraper.updates)
        .thenAnswer((_) => const Stream.empty());
    when(() => mockScraper.getCached(any())).thenReturn(null);
    when(() => mockScraper.enqueueStations(any())).thenReturn(null);
  });

  blocTest<StationCubit, StationState>(
    'emits [loading, loaded] on successful fetch',
    build: () {
      when(() => mockRepo.getStations(
            bounds: any(named: 'bounds'),
            filters: any(named: 'filters'),
          )).thenAnswer((_) async => [_station]);
      return StationCubit(repository: mockRepo, scraper: mockScraper);
    },
    act: (c) => c.loadStations(_bounds),
    expect: () => [
      const StationState.loading(filters: FilterOptions()),
      const StationState.loaded(
        stations: [_station],
        filters: FilterOptions(),
        availableNetworks: [],
        availableManufacturers: [],
      ),
    ],
  );

  blocTest<StationCubit, StationState>(
    'emits [loading, error] on API failure',
    build: () {
      when(() => mockRepo.getStations(
            bounds: any(named: 'bounds'),
            filters: any(named: 'filters'),
          )).thenThrow(Exception('network error'));
      return StationCubit(repository: mockRepo, scraper: mockScraper);
    },
    act: (c) => c.loadStations(_bounds),
    expect: () => [
      const StationState.loading(filters: FilterOptions()),
      isA<StationError>(),
    ],
  );

  blocTest<StationCubit, StationState>(
    'applyFilters clears cache then re-fetches',
    build: () {
      when(() => mockRepo.getStations(
            bounds: any(named: 'bounds'),
            filters: any(named: 'filters'),
          )).thenAnswer((_) async => []);
      when(() => mockRepo.clearCache()).thenReturn(null);
      return StationCubit(repository: mockRepo, scraper: mockScraper);
    },
    act: (c) =>
        c.applyFilters(const FilterOptions(networks: ['Ionity']), _bounds),
    verify: (_) => verify(() => mockRepo.clearCache()).called(1),
    expect: () => [
      const StationState.loading(filters: FilterOptions(networks: ['Ionity'])),
      const StationState.loaded(
        stations: [],
        filters: FilterOptions(networks: ['Ionity']),
        availableNetworks: [],
        availableManufacturers: [],
      ),
    ],
  );

  blocTest<StationCubit, StationState>(
    'applies hardware filter from scraper cache',
    build: () {
      when(() => mockRepo.getStations(
            bounds: any(named: 'bounds'),
            filters: any(named: 'filters'),
          )).thenAnswer((_) async => [
            _station,
            const ChargingStation(
              id: '2',
              name: 'Alpitronic Station',
              address: 'Addr2',
              latitude: 47.6,
              longitude: 9.6,
              network: 'Ladenetz',
            ),
          ]);
      when(() => mockScraper.getCached('1'))
          .thenReturn(const HardwareInfo(manufacturer: 'ABB', model: 'Terra 54'));
      when(() => mockScraper.getCached('2'))
          .thenReturn(
              const HardwareInfo(manufacturer: 'Alpitronic', model: 'HYC 150'));
      return StationCubit(repository: mockRepo, scraper: mockScraper);
    },
    act: (c) => c.applyFilters(
        const FilterOptions(manufacturers: ['ABB']), _bounds),
    verify: (_) => verify(() => mockRepo.clearCache()).called(1),
    expect: () => [
      const StationState.loading(
          filters: FilterOptions(manufacturers: ['ABB'])),
      isA<StationLoaded>().having(
        (s) => s.stations.map((st) => st.manufacturer).toList(),
        'manufacturers',
        ['ABB'],
      ),
    ],
  );
}
