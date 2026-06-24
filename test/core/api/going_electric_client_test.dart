import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ev80_chargers/core/api/going_electric_client.dart';
import 'package:ev80_chargers/core/api/dto/ge_station_dto.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late GoingElectricClient client;

  setUp(() {
    mockDio = MockDio();
    client = GoingElectricClient(dio: mockDio, apiKey: 'test-key');
  });

  test('getStations sends correct query params', () async {
    when(() => mockDio.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
        )).thenAnswer((_) async => Response(
          data: {'status': 'ok', 'chargelocations': []},
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ));

    await client.getStations(lat: 51.5, lng: 10.0, radiusKm: 25.0);

    final captured = verify(() => mockDio.get(
          captureAny(),
          queryParameters: captureAny(named: 'queryParameters'),
        )).captured;

    expect(captured[0], contains('/chargepoints/'));
    final params = captured[1] as Map<String, dynamic>;
    expect(params['key'], 'test-key');
    expect(params['lat'], 51.5);
    expect(params['lng'], 10.0);
    expect(params['radius'], 25.0);
    expect(params['plugs[0][type]'], 'combo_typ2');
  });

  test('getStations returns empty list on empty response', () async {
    when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
        .thenAnswer((_) async => Response(
              data: {'status': 'ok', 'chargelocations': []},
              statusCode: 200,
              requestOptions: RequestOptions(path: ''),
            ));

    final result =
        await client.getStations(lat: 51.5, lng: 10.0, radiusKm: 25.0);

    expect(result.status, 'ok');
    expect(result.chargepoints, isEmpty);
  });

  test('GeStationDto.fromJson parses nested coordinates and address', () {
    final json = {
      'ge_id': 42,
      'name': 'Test Station',
      'coordinates': {'lat': 48.1, 'lng': 11.5},
      'address': {'street': 'Hauptstraße 1', 'city': 'München'},
      'network': 'Ionity',
      'chargepoints': [
        {'type': 'CCS2', 'power': 350.0}
      ],
    };

    final dto = GeStationDto.fromJson(json);

    expect(dto.id, '42');
    expect(dto.latitude, 48.1);
    expect(dto.longitude, 11.5);
    expect(dto.address, 'Hauptstraße 1, München');
    expect(dto.network, 'Ionity');
    expect(dto.connectors.length, 1);
    expect(dto.connectors.first.type, 'CCS2');
    expect(dto.connectors.first.power, 350.0);
  });

  test('GeStationDto.fromJson handles missing optional fields gracefully', () {
    final json = {
      'ge_id': 1,
      'name': 'Minimal',
      'coordinates': {'lat': 50.0, 'lng': 8.0},
      'address': {},
      'chargepoints': [],
    };

    final dto = GeStationDto.fromJson(json);

    expect(dto.network, isNull);
    expect(dto.manufacturer, isNull);
    expect(dto.connectors, isEmpty);
  });

  test('getStations includes network param when provided', () async {
    when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
        .thenAnswer((_) async => Response(
              data: {'status': 'ok', 'chargelocations': []},
              statusCode: 200,
              requestOptions: RequestOptions(path: ''),
            ));

    await client.getStations(lat: 51.5, lng: 10.0, radiusKm: 25.0, network: 'Ionity');

    final captured = verify(() => mockDio.get(
          captureAny(),
          queryParameters: captureAny(named: 'queryParameters'),
        )).captured;

    final params = captured[1] as Map<String, dynamic>;
    expect(params['network'], 'Ionity');
  });
}
