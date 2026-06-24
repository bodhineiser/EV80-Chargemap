// Raw GE API response DTOs. Field names verified against actual API JSON (2026-06-08).

class GeStationListDto {
  final String status;
  final List<GeStationDto> chargepoints;

  GeStationListDto({required this.status, required this.chargepoints});

  factory GeStationListDto.fromJson(Map<String, dynamic> json) {
    // API returns "chargelocations" at top level, not "chargepoints"
    final list = (json['chargelocations'] as List<dynamic>? ?? [])
        .map((e) => e is Map ? GeStationDto.fromJson(Map<String, dynamic>.from(e)) : null)
        .whereType<GeStationDto>()
        .toList();
    return GeStationListDto(
      status: json['status'] as String? ?? '',
      chargepoints: list,
    );
  }
}

class GeStationDto {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String address;
  final String? network;
  final String? manufacturer;
  final String? model;
  final String? url;
  final List<GeConnectorDto> connectors;

  GeStationDto({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.address,
    this.network,
    this.manufacturer,
    this.model,
    this.url,
    required this.connectors,
  });

  factory GeStationDto.fromJson(Map<String, dynamic> json) {
    final rawCoords = json['coordinates'];
    final coords = rawCoords != null
        ? Map<String, dynamic>.from(rawCoords as Map)
        : <String, dynamic>{};
    final rawAddr = json['address'];
    final addr = rawAddr != null
        ? Map<String, dynamic>.from(rawAddr as Map)
        : <String, dynamic>{};
    // "street" already includes the house number (e.g. "Hauptstraße 9")
    // GE API uses false (not null) for absent string fields
    final street = addr['street'] is String ? addr['street'] as String : '';
    final city = addr['city'] is String ? addr['city'] as String : '';
    final addressStr =
        [street, city].where((s) => s.isNotEmpty).join(', ');

    final connList = (json['chargepoints'] as List<dynamic>? ?? [])
        .map((e) => e is Map ? GeConnectorDto.fromJson(Map<String, dynamic>.from(e)) : null)
        .whereType<GeConnectorDto>()
        .toList();

    return GeStationDto(
      id: (json['ge_id'] ?? json['id'] ?? '').toString(),
      name: json['name'] as String? ?? '',
      latitude: (coords['lat'] as num?)?.toDouble() ?? 0.0,
      longitude: (coords['lng'] as num?)?.toDouble() ?? 0.0,
      address: addressStr,
      // API uses false (not null) for absent string fields
      network: json['network'] is String ? json['network'] as String : null,
      manufacturer: json['manufacturer'] is String ? json['manufacturer'] as String : null,
      model: json['model'] is String ? json['model'] as String : null,
      // URL is protocol-relative "//www.goingelectric.de/..." — prepend https:
      url: json['url'] is String ? 'https:${json['url'] as String}' : null,
      connectors: connList,
    );
  }
}

class GeConnectorDto {
  final String type;
  final double? power;

  GeConnectorDto({required this.type, this.power});

  factory GeConnectorDto.fromJson(Map<String, dynamic> json) {
    return GeConnectorDto(
      type: json['type'] as String? ?? '',
      power: (json['power'] as num?)?.toDouble(),
    );
  }
}
