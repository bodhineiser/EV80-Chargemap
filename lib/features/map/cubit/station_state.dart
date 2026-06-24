import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../core/models/charging_station.dart';
import '../../../core/models/filter_options.dart';

part 'station_state.freezed.dart';

@freezed
abstract class StationState with _$StationState {
  const factory StationState.initial() = StationInitial;

  const factory StationState.loading({
    required FilterOptions filters,
  }) = StationLoading;

  const factory StationState.loaded({
    required List<ChargingStation> stations,
    required FilterOptions filters,
    required List<String> availableNetworks,
    required List<String> availableManufacturers,
  }) = StationLoaded;

  const factory StationState.error({
    required String message,
    required FilterOptions filters,
  }) = StationError;
}
