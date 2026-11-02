import '../../domain/entities/carpool_entities.dart';
import '../models/carpool_models.dart';

abstract class CarpoolRemoteDataSource {
  Future<CarpoolUserModel> fetchUser();
  Future<List<CarpoolPopularRouteModel>> fetchPopularRoutes();
  Future<List<CarpoolRideModel>> searchRides(CarpoolSearchRidesParams params);
  Future<void> bookRide(String rideId);
  Future<CarpoolRideModel> publishRide(CarpoolPublishRideParams params);
  Future<List<CarpoolRideModel>> fetchMyRides();
  Future<void> cancelRide(String rideId);
  Future<CarpoolWalletModel> fetchWallet();
  Future<CarpoolWalletModel> addMoney(double amount);
  Future<List<CarpoolMessageModel>> fetchMessages();
}
