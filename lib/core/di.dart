import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'api/going_electric_client.dart';
import 'env.dart';
import 'services/hardware_scraper.dart';
import '../features/map/repository/station_repository.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  getIt.registerLazySingleton<Dio>(() => Dio());

  getIt.registerLazySingleton<GoingElectricClient>(
    () => GoingElectricClient(
      dio: getIt<Dio>(),
      apiKey: Env.apiKey,
    ),
  );

  getIt.registerLazySingleton<StationRepository>(
    () => StationRepository(client: getIt<GoingElectricClient>()),
  );

  getIt.registerLazySingleton<HardwareScraper>(
    () => HardwareScraper(dio: getIt<Dio>()),
  );
}
