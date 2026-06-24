import 'package:flutter_test/flutter_test.dart';
import 'package:ev80_chargers/core/models/charging_station.dart';
import 'package:ev80_chargers/core/models/connector.dart';
import 'package:ev80_chargers/core/models/filter_options.dart';

void main() {
  group('ChargingStation', () {
    test('creates with required fields and null-optional fields', () {
      const station = ChargingStation(
        id: '42',
        name: 'Test Station',
        address: 'Hauptstraße 1, Berlin',
        latitude: 52.52,
        longitude: 13.405,
        network: 'Ionity',
      );

      expect(station.id, '42');
      expect(station.manufacturer, isNull);
      expect(station.model, isNull);
      expect(station.connectors, isEmpty);
    });

    test('value equality holds', () {
      const a = ChargingStation(
        id: '1', name: 'A', address: 'X', latitude: 1.0, longitude: 2.0, network: 'N',
      );
      const b = ChargingStation(
        id: '1', name: 'A', address: 'X', latitude: 1.0, longitude: 2.0, network: 'N',
      );
      expect(a, equals(b));
    });

    test('copyWith updates single field', () {
      const station = ChargingStation(
        id: '1', name: 'Old', address: 'X', latitude: 1.0, longitude: 2.0, network: 'N',
      );
      final updated = station.copyWith(name: 'New');
      expect(updated.name, 'New');
      expect(updated.id, '1');
    });
  });

  group('FilterOptions', () {
    test('isEmpty true for default instance', () {
      expect(const FilterOptions().isEmpty, isTrue);
    });

    test('isEmpty false when any list is non-empty', () {
      expect(const FilterOptions(networks: ['Ionity']).isEmpty, isFalse);
    });

    test('value equality holds', () {
      expect(
        const FilterOptions(networks: ['A']),
        equals(const FilterOptions(networks: ['A'])),
      );
    });
  });

  group('Connector', () {
    test('construction with type only (powerKw is null)', () {
      const connector = Connector(type: 'CCS');
      expect(connector.type, 'CCS');
      expect(connector.powerKw, isNull);
    });

    test('construction with both fields', () {
      const connector = Connector(type: 'Type2', powerKw: 22);
      expect(connector.type, 'Type2');
      expect(connector.powerKw, 22);
    });

    test('value equality holds', () {
      const a = Connector(type: 'CCS', powerKw: 50);
      const b = Connector(type: 'CCS', powerKw: 50);
      expect(a, equals(b));
    });

    test('copyWith updates powerKw', () {
      const connector = Connector(type: 'CCS', powerKw: 50);
      final updated = connector.copyWith(powerKw: 150);
      expect(updated.type, 'CCS');
      expect(updated.powerKw, 150);
    });
  });
}
