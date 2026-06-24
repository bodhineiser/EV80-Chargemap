import 'package:dio/dio.dart';
import 'dto/ge_station_dto.dart';

class GoingElectricClient {
  static const _baseUrl = 'https://api.goingelectric.de';

  final Dio _dio;
  final String _apiKey;

  GoingElectricClient({required Dio dio, required String apiKey})
      : _dio = dio,
        _apiKey = apiKey;

  Future<GeStationListDto> getStations({
    required double lat,
    required double lng,
    required double radiusKm,
    int count = 100,
    String? network,
  }) async {
    final response = await _dio.get(
      '$_baseUrl/chargepoints/',
      queryParameters: {
        'key': _apiKey,
        'lat': lat,
        'lng': lng,
        'radius': radiusKm,
        'count': count,
        'plugs[0][type]': 'combo_typ2',
        if (network != null) 'network': network,
      },
    );
    return GeStationListDto.fromJson(response.data as Map<String, dynamic>);
  }
}
