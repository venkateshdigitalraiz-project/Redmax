import '../../domain/entities/carpool_ride.dart';
import '../../domain/repositories/carpool_repository.dart';
import '../datasources/carpool_remote_datasource.dart';

/// Concrete implementation of [CarpoolRepository] using [CarpoolRemoteDataSource].
class CarpoolRepositoryImpl implements CarpoolRepository {
  final CarpoolRemoteDataSource remoteDataSource;

  const CarpoolRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<CarpoolRide>> getAvailableRides() =>
      remoteDataSource.fetchAvailableRides();

  @override
  Future<List<CarpoolRide>> searchRides(String query) =>
      remoteDataSource.searchRides(query);

  @override
  Future<String> bookRide(String rideId) =>
      remoteDataSource.bookRide(rideId);
}
