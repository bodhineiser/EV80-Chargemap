import 'package:freezed_annotation/freezed_annotation.dart';
import 'connector.dart';

part 'charging_station.freezed.dart';

@freezed
abstract class ChargingStation with _$ChargingStation {
  const factory ChargingStation({
    required String id,
    required String name,
    required String address,
    required double latitude,
    required double longitude,
    required String network,
    String? manufacturer,
    String? model,
    @Default([]) List<Connector> connectors,
  }) = _ChargingStation;
}
