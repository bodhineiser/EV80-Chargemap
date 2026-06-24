import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di.dart';
import 'core/services/hardware_scraper.dart';
import 'features/map/cubit/station_cubit.dart';
import 'features/map/repository/station_repository.dart';
import 'features/map/ui/map_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => StationCubit(
            repository: getIt<StationRepository>(),
            scraper: getIt<HardwareScraper>(),
          ),
      child: MaterialApp(
        title: 'EV Chargers',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF4A9EFF)),
          useMaterial3: true,
        ),
        home: const MapScreen(),
      ),
    );
  }
}
