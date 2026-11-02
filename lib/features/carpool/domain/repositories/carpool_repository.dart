import '../entities/carpool_entities.dart';

/// Contract implemented by the data layer. The domain never depends on data.
abstract class CarpoolRepository {
  Future<CarpoolUserEntity> getUser();
  Future<List<CarpoolPopularRouteEntity>> getPopularRoutes();
  Future<List<CarpoolRideEntity>> searchRides(CarpoolSearchRidesParams params);
  Future<void> bookRide(String rideId);
  Future<CarpoolRideEntity> publishRide(CarpoolPublishRideParams params);
  Future<List<CarpoolRideEntity>> getMyRides();
  Future<void> cancelRide(String rideId);
  Future<CarpoolWalletEntity> getWallet();
  Future<CarpoolWalletEntity> addMoney(double amount);
  Future<List<CarpoolMessageEntity>> getMessages();
}
