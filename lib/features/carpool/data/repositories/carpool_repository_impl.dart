import '../../domain/entities/carpool_entities.dart';
import '../../domain/entities/carpool_pricing_entity.dart';
import '../../domain/repositories/carpool_repository.dart';
import '../../domain/usecases/carpool_calculate_pricing_usecase.dart';
import '../datasources/carpool_remote_data_source.dart';

class CarpoolRepositoryImpl implements CarpoolRepository {
  const CarpoolRepositoryImpl(this._remote);
  final CarpoolRemoteDataSource _remote;

  @override
  Future<CarpoolUserEntity> getUser() => _remote.fetchUser();

  @override
  Future<List<CarpoolPopularRouteEntity>> getPopularRoutes() =>
      _remote.fetchPopularRoutes();

  @override
  Future<List<CarpoolRideEntity>> searchRides(
          CarpoolSearchRidesParams params) =>
      _remote.searchRides(params);

  @override
  Future<void> bookRide(String rideId) => _remote.bookRide(rideId);

  @override
  Future<CarpoolRideEntity> publishRide(CarpoolPublishRideParams params) =>
      _remote.publishRide(params);

  @override
  Future<List<CarpoolRideEntity>> getMyRides() => _remote.fetchMyRides();

  @override
  Future<void> cancelRide(String rideId) => _remote.cancelRide(rideId);

  @override
  Future<CarpoolWalletEntity> getWallet() => _remote.fetchWallet();

  @override
  Future<CarpoolWalletEntity> addMoney(double amount) =>
      _remote.addMoney(amount);

  @override
  Future<List<CarpoolMessageEntity>> getMessages() => _remote.fetchMessages();

  @override
  Future<CarpoolPricingEntity> calculatePricing(
    CarpoolCalculatePricingParams params,
  ) =>
      _remote.calculatePricing(params);
}
