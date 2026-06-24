import 'package:freezed_annotation/freezed_annotation.dart';

part 'connector.freezed.dart';

@freezed
abstract class Connector with _$Connector {
  const factory Connector({
    required String type,
    int? powerKw,
  }) = _Connector;
}
