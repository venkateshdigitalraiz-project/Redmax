import '../entities/carpool_entities.dart';
import '../repositories/carpool_repository.dart';
import 'carpool_usecase.dart';

class CarpoolGetUserUseCase
    implements CarpoolUseCase<CarpoolUserEntity, CarpoolNoParams> {
  const CarpoolGetUserUseCase(this._repository);
  final CarpoolRepository _repository;

  @override
  Future<CarpoolUserEntity> call(CarpoolNoParams params) =>
      _repository.getUser();
}

class CarpoolGetPopularRoutesUseCase
    implements
        CarpoolUseCase<List<CarpoolPopularRouteEntity>, CarpoolNoParams> {
  const CarpoolGetPopularRoutesUseCase(this._repository);
  final CarpoolRepository _repository;

  @override
  Future<List<CarpoolPopularRouteEntity>> call(CarpoolNoParams params) =>
      _repository.getPopularRoutes();
}

class CarpoolSearchRidesUseCase
    implements
        CarpoolUseCase<List<CarpoolRideEntity>, CarpoolSearchRidesParams> {
  const CarpoolSearchRidesUseCase(this._repository);
  final CarpoolRepository _repository;

  @override
  Future<List<CarpoolRideEntity>> call(CarpoolSearchRidesParams params) =>
      _repository.searchRides(params);
}

class CarpoolBookRideUseCase implements CarpoolUseCase<void, String> {
  const CarpoolBookRideUseCase(this._repository);
  final CarpoolRepository _repository;

  @override
  Future<void> call(String rideId) => _repository.bookRide(rideId);
}

class CarpoolPublishRideUseCase
    implements CarpoolUseCase<CarpoolRideEntity, CarpoolPublishRideParams> {
  const CarpoolPublishRideUseCase(this._repository);
  final CarpoolRepository _repository;

  @override
  Future<CarpoolRideEntity> call(CarpoolPublishRideParams params) {
    if (params.from.trim().isEmpty || params.to.trim().isEmpty) {
      throw ArgumentError('Pickup and drop locations are required.');
    }
    if (params.seats < 1) {
      throw ArgumentError('At least one seat must be offered.');
    }
    return _repository.publishRide(params);
  }
}

class CarpoolGetMyRidesUseCase
    implements CarpoolUseCase<List<CarpoolRideEntity>, CarpoolNoParams> {
  const CarpoolGetMyRidesUseCase(this._repository);
  final CarpoolRepository _repository;

  @override
  Future<List<CarpoolRideEntity>> call(CarpoolNoParams params) =>
      _repository.getMyRides();
}

class CarpoolCancelRideUseCase implements CarpoolUseCase<void, String> {
  const CarpoolCancelRideUseCase(this._repository);
  final CarpoolRepository _repository;

  @override
  Future<void> call(String rideId) => _repository.cancelRide(rideId);
}

class CarpoolGetWalletUseCase
    implements CarpoolUseCase<CarpoolWalletEntity, CarpoolNoParams> {
  const CarpoolGetWalletUseCase(this._repository);
  final CarpoolRepository _repository;

  @override
  Future<CarpoolWalletEntity> call(CarpoolNoParams params) =>
      _repository.getWallet();
}

class CarpoolAddMoneyUseCase
    implements CarpoolUseCase<CarpoolWalletEntity, double> {
  const CarpoolAddMoneyUseCase(this._repository);
  final CarpoolRepository _repository;

  @override
  Future<CarpoolWalletEntity> call(double amount) {
    if (amount <= 0) throw ArgumentError('Enter an amount greater than zero.');
    return _repository.addMoney(amount);
  }
}

class CarpoolGetMessagesUseCase
    implements CarpoolUseCase<List<CarpoolMessageEntity>, CarpoolNoParams> {
  const CarpoolGetMessagesUseCase(this._repository);
  final CarpoolRepository _repository;

  @override
  Future<List<CarpoolMessageEntity>> call(CarpoolNoParams params) =>
      _repository.getMessages();
}
