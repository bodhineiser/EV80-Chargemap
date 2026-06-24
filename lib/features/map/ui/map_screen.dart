import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/models/charging_station.dart';
import '../../filters/ui/hardware_filter_sheet.dart';
import '../../filters/ui/network_filter_sheet.dart';
import '../../station_detail/ui/station_detail_sheet.dart';
import '../cubit/station_cubit.dart';
import '../cubit/station_state.dart';
import 'widgets/active_filter_strip.dart';
import 'widgets/station_marker.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _mapController = MapController();
  LatLngBounds? _currentBounds;
  Timer? _loadDebounce;

  @override
  void dispose() {
    _loadDebounce?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  void _onMapReady() {
    setState(() {
      _currentBounds = _mapController.camera.visibleBounds;
    });
    context.read<StationCubit>().loadStations(_currentBounds!);
  }

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    if (!hasGesture) return;
    setState(() => _currentBounds = camera.visibleBounds);
    _loadDebounce?.cancel();
    _loadDebounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted && _currentBounds != null) {
        context.read<StationCubit>().loadStations(_currentBounds!);
      }
    });
  }

  void _showDetail(ChargingStation station) {
    final id = station.id;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<StationCubit>(),
        child: BlocBuilder<StationCubit, StationState>(
          builder: (ctx, _) {
            final live =
                ctx.read<StationCubit>().getStation(id) ?? station;
            return StationDetailSheet(station: live);
          },
        ),
      ),
    );
  }

  void _openNetworkFilter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<StationCubit>(),
        child: NetworkFilterSheet(currentBounds: _currentBounds),
      ),
    );
  }

  void _openHardwareFilter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<StationCubit>(),
        child: HardwareFilterSheet(currentBounds: _currentBounds),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⚡ EV Chargers'),
        actions: [
          TextButton.icon(
            onPressed: _openNetworkFilter,
            icon: const Icon(Icons.cell_tower, size: 16),
            label: const Text('Network'),
          ),
          TextButton.icon(
            onPressed: _openHardwareFilter,
            icon: const Icon(Icons.memory, size: 16),
            label: const Text('Hardware'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          ActiveFilterStrip(currentBounds: _currentBounds),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter:
                        const LatLng(51.1657, 10.4515),
                    initialZoom: 6.0,
                    onMapReady: _onMapReady,
                    onPositionChanged: _onPositionChanged,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'de.ev80.chargers',
                    ),
                    BlocBuilder<StationCubit, StationState>(
                      builder: (context, state) {
                        final stations = switch (state) {
                          StationLoaded(:final stations) => stations,
                          _ => <ChargingStation>[],
                        };

                        final markers = stations
                            .map((s) => Marker(
                                  point: LatLng(s.latitude, s.longitude),
                                  width: 28,
                                  height: 28,
                                  child: StationMarker(
                                    station: s,
                                    onTap: () => _showDetail(s),
                                  ),
                                ))
                            .toList();

                        return MarkerClusterLayerWidget(
                          options: MarkerClusterLayerOptions(
                            maxClusterRadius: 80,
                            size: const Size(36, 36),
                            markers: markers,
                            builder: (context, clusterMarkers) => Container(
                              decoration: BoxDecoration(
                                color: Colors.orange.shade600,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white, width: 2),
                                boxShadow: const [
                                  BoxShadow(
                                      color: Colors.black26, blurRadius: 4)
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  '${clusterMarkers.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                BlocBuilder<StationCubit, StationState>(
                  buildWhen: (p, c) =>
                      (p is StationLoading) != (c is StationLoading),
                  builder: (context, state) {
                    if (state is! StationLoading) {
                      return const SizedBox.shrink();
                    }
                    return const Positioned(
                      top: 8,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Card(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                ),
                                SizedBox(width: 8),
                                Text('Loading...'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                BlocListener<StationCubit, StationState>(
                  listenWhen: (_, c) => c is StationError,
                  listener: (context, state) {
                    if (state is StationError) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: const Text("Couldn't load stations"),
                        action: SnackBarAction(
                          label: 'Retry',
                          onPressed: () {
                            if (_currentBounds != null) {
                              context
                                  .read<StationCubit>()
                                  .loadStations(_currentBounds!);
                            }
                          },
                        ),
                      ));
                    }
                  },
                  child: const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
