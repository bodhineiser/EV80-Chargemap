import 'dart:async';
import 'package:dio/dio.dart';

class HardwareInfo {
  final String manufacturer;
  final String model;

  const HardwareInfo({required this.manufacturer, required this.model});
}

/// Fetches hardware manufacturer/model from GE station pages by scraping the
/// "Ladesäulen: N× Manufacturer Model" text in the ls-station-summary element.
/// Processes one station per ~1200ms to be respectful of the website.
class HardwareScraper {
  final Dio _dio;
  final Map<String, HardwareInfo?> _cache = {};
  final StreamController<MapEntry<String, HardwareInfo>> _controller =
      StreamController.broadcast();
  final List<(String, String)> _queue = [];
  bool _processing = false;

  // Matches "Ladesäulen: 2× Keba KeContact P30" and captures "Keba KeContact P30"
  static final _hwRegex = RegExp('Ladesäulen: \\d+×\\s*([^<\\n]+)');

  HardwareScraper({required Dio dio}) : _dio = dio;

  Stream<MapEntry<String, HardwareInfo>> get updates => _controller.stream;

  HardwareInfo? getCached(String id) => _cache[id];

  List<String> getModelsForManufacturers(List<String> manufacturers) {
    final mSet = manufacturers.toSet();
    return _cache.values
        .whereType<HardwareInfo>()
        .where((hw) => mSet.contains(hw.manufacturer))
        .map((hw) => hw.model)
        .where((m) => m.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  /// Adds stations not yet cached. New stations are inserted at the front of the
  /// queue so the current viewport is always scraped before old queued stations.
  /// Stations no longer in the current set are removed from the queue.
  void enqueueStations(Map<String, String> idsToUrls) {
    _queue.removeWhere((e) => !idsToUrls.containsKey(e.$1));

    final toAdd = <(String, String)>[];
    for (final entry in idsToUrls.entries) {
      if (_cache.containsKey(entry.key)) continue;
      if (entry.value.isEmpty) continue;
      if (_queue.any((e) => e.$1 == entry.key)) continue;
      toAdd.add((entry.key, entry.value));
    }
    _queue.insertAll(0, toAdd);
    if (toAdd.isNotEmpty && !_processing) _processQueue();
  }

  Future<void> _processQueue() async {
    _processing = true;
    var backoffSeconds = 0;
    while (_queue.isNotEmpty) {
      final (id, url) = _queue.removeAt(0);
      if (_cache.containsKey(id)) continue;
      try {
        final response = await _dio.get(
          url,
          options: Options(
            responseType: ResponseType.plain,
            headers: {
              'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36'
            },
            receiveTimeout: const Duration(seconds: 15),
            sendTimeout: const Duration(seconds: 10),
          ),
        );
        backoffSeconds = 0;
        final info = _parseHtml(response.data as String);
        _cache[id] = info;
        if (info != null) _controller.add(MapEntry(id, info));
      } catch (e) {
        final is429 =
            e is DioException && e.response?.statusCode == 429;
        if (is429) {
          // Re-queue at front and back off — don't cache so it can be retried.
          _queue.insert(0, (id, url));
          backoffSeconds = backoffSeconds == 0 ? 30 : (backoffSeconds * 2).clamp(0, 120);
          await Future.delayed(Duration(seconds: backoffSeconds));
          continue;
        }
        _cache[id] = null;
      }
      if (_queue.isNotEmpty) {
        await Future.delayed(const Duration(milliseconds: 1200));
      }
    }
    _processing = false;
  }

  HardwareInfo? _parseHtml(String html) {
    final match = _hwRegex.firstMatch(html);
    if (match == null) return null;
    final raw = match.group(1)!.trim();
    if (raw.isEmpty) return null;
    final parts =
        raw.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return null;
    final manufacturer = _capitalizeFirst(parts.first);
    final model = parts.length > 1 ? parts.skip(1).join(' ') : '';
    return HardwareInfo(manufacturer: manufacturer, model: model);
  }

  // Only capitalize the first letter — preserves ABB, keeps "alpitronic"→"Alpitronic"
  String _capitalizeFirst(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  void dispose() => _controller.close();
}
