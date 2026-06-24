import 'package:freezed_annotation/freezed_annotation.dart';

part 'filter_options.freezed.dart';

@freezed
abstract class FilterOptions with _$FilterOptions {
  const factory FilterOptions({
    @Default([]) List<String> networks,
    @Default([]) List<String> manufacturers,
    @Default([]) List<String> models,
  }) = _FilterOptions;

  const FilterOptions._();

  bool get isEmpty =>
      networks.isEmpty && manufacturers.isEmpty && models.isEmpty;
}
