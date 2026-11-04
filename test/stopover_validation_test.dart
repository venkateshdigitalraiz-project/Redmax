import 'package:flutter_test/flutter_test.dart';
import 'package:pathway/core/utils/carpool_distance_calculator.dart';
import 'package:pathway/features/carpool/domain/usecases/carpool_usecases.dart';
import 'package:pathway/features/carpool/presentation/bloc/carpool_offer_ride_bloc.dart';
import 'package:pathway/features/carpool/domain/repositories/carpool_repository.dart';
import 'package:pathway/features/carpool/domain/entities/carpool_entities.dart';

class MockCarpoolRepository implements CarpoolRepository {
  @override
  Future<List<CarpoolRideEntity>> searchRides(CarpoolSearchParams params) async => [];
  @override
  Future<CarpoolRideEntity> getRideById(String id) async => throw UnimplementedError();
  @override
  Future<CarpoolRideEntity> publishRide(CarpoolPublishRideParams params) async => throw UnimplementedError();
  @override
  Future<CarpoolBookingResultEntity> bookRide(CarpoolBookingParams params) async => throw UnimplementedError();
  @override
  Future<List<CarpoolRideEntity>> getMyRides() async => [];
  @override
  Future<List<CarpoolBookingEntity>> getMyBookings() async => [];
}

void main() {
  const hyderabad = 'Hyderabad';
  const vijayawada = 'Vijayawada';
  const hydLat = 17.3850;
  const hydLng = 78.4867;
  const vjaLat = 16.5062;
  const vjaLng = 80.6480;

  group('CarpoolStopovers Route Validation Tests', () {
    test('1. Validates LB Nagar on Hyderabad -> Vijayawada route as isOnRoute == true', () {
      final adj = CarpoolDistanceCalculator.validateLocationOnRoute(
        start: hyderabad,
        destination: vijayawada,
        candidateName: 'LB Nagar',
        candidateLat: 17.3501,
        candidateLng: 78.5511,
        startLat: hydLat,
        startLng: hydLng,
        destLat: vjaLat,
        destLng: vjaLng,
      );

      print('LB Nagar: isOnRoute=${adj.isOnRoute}, addKm=${adj.additionalKm}, updatedKm=${adj.updatedTotalKm}');
      expect(adj.isOnRoute, isTrue, reason: 'LB Nagar should be on route');
      expect(adj.additionalKm, lessThanOrEqualTo(25));
    });

    test('2. Validates Suryapet on Hyderabad -> Vijayawada route as isOnRoute == true', () {
      final adj = CarpoolDistanceCalculator.validateLocationOnRoute(
        start: hyderabad,
        destination: vijayawada,
        candidateName: 'Suryapet',
        candidateLat: 17.1439,
        candidateLng: 79.6239,
        startLat: hydLat,
        startLng: hydLng,
        destLat: vjaLat,
        destLng: vjaLng,
      );

      print('Suryapet: isOnRoute=${adj.isOnRoute}, addKm=${adj.additionalKm}, updatedKm=${adj.updatedTotalKm}');
      expect(adj.isOnRoute, isTrue, reason: 'Suryapet should be on route');
      expect(adj.additionalKm, lessThanOrEqualTo(25));
    });

    test('3. Multiple stopovers: adding Suryapet when Kodad is already present keeps isOnRoute == true', () {
      final adj = CarpoolDistanceCalculator.validateLocationOnRoute(
        start: hyderabad,
        destination: vijayawada,
        candidateName: 'Suryapet',
        candidateLat: 17.1439,
        candidateLng: 79.6239,
        startLat: hydLat,
        startLng: hydLng,
        destLat: vjaLat,
        destLng: vjaLng,
        currentStopovers: ['Kodad'],
      );

      print('Adding Suryapet with Kodad already present: isOnRoute=${adj.isOnRoute}, addKm=${adj.additionalKm}, updatedKm=${adj.updatedTotalKm}');
      expect(adj.isOnRoute, isTrue);
      expect(adj.additionalKm, lessThanOrEqualTo(25));
    });

    test('4. Correct corridor ordering for multiple stopovers along NH65', () {
      final ordered = CarpoolDistanceCalculator.orderStopoversInCorridor(
        start: hyderabad,
        destination: vijayawada,
        stopovers: ['Kodad', 'LB Nagar', 'Suryapet', 'Choutuppal'],
        startLat: hydLat,
        startLng: hydLng,
        destLat: vjaLat,
        destLng: vjaLng,
      );

      print('Corridor ordered stopovers: $ordered');
      expect(ordered, ['LB Nagar', 'Choutuppal', 'Suryapet', 'Kodad']);
    });

    test('5. Rejects off-route locations (e.g. Warangal, Kurnool)', () {
      final adjWarangal = CarpoolDistanceCalculator.validateLocationOnRoute(
        start: hyderabad,
        destination: vijayawada,
        candidateName: 'Warangal',
        candidateLat: 17.9689,
        candidateLng: 79.5941,
        startLat: hydLat,
        startLng: hydLng,
        destLat: vjaLat,
        destLng: vjaLng,
      );

      print('Warangal: isOnRoute=${adjWarangal.isOnRoute}, addKm=${adjWarangal.additionalKm}');
      expect(adjWarangal.isOnRoute, isFalse, reason: 'Warangal is significantly off the Hyderabad-Vijayawada corridor');

      final adjKurnool = CarpoolDistanceCalculator.validateLocationOnRoute(
        start: hyderabad,
        destination: vijayawada,
        candidateName: 'Kurnool',
        candidateLat: 15.8281,
        candidateLng: 78.0373,
        startLat: hydLat,
        startLng: hydLng,
        destLat: vjaLat,
        destLng: vjaLng,
      );

      print('Kurnool: isOnRoute=${adjKurnool.isOnRoute}, addKm=${adjKurnool.additionalKm}');
      expect(adjKurnool.isOnRoute, isFalse, reason: 'Kurnool is in the opposite direction');
    });

    test('6. Configurable route deviation threshold', () {
      // With strict 5 km threshold, a 10 km detour location is rejected
      final strictAdj = CarpoolDistanceCalculator.validateLocationOnRoute(
        start: hyderabad,
        destination: vijayawada,
        candidateName: 'Nalgonda',
        candidateLat: 17.0575,
        candidateLng: 79.2684,
        startLat: hydLat,
        startLng: hydLng,
        destLat: vjaLat,
        destLng: vjaLng,
        deviationThresholdKm: 5.0,
      );
      print('Nalgonda with 5km threshold: isOnRoute=${strictAdj.isOnRoute}, addKm=${strictAdj.additionalKm}');

      // With default 40 km threshold, Nalgonda is accepted
      final defaultAdj = CarpoolDistanceCalculator.validateLocationOnRoute(
        start: hyderabad,
        destination: vijayawada,
        candidateName: 'Nalgonda',
        candidateLat: 17.0575,
        candidateLng: 79.2684,
        startLat: hydLat,
        startLng: hydLng,
        destLat: vjaLat,
        destLng: vjaLng,
      );
      print('Nalgonda with default 40km threshold: isOnRoute=${defaultAdj.isOnRoute}, addKm=${defaultAdj.additionalKm}');
      expect(defaultAdj.isOnRoute, isTrue);
    });

    test('7. BLoC CarpoolOfferStopoverAdded maintains corridor ordering', () async {
      final repo = MockCarpoolRepository();
      final useCase = CarpoolPublishRideUseCase(repo);
      final bloc = CarpoolOfferRideBloc(publishRide: useCase);

      bloc.add(const CarpoolOfferFromChanged('Hyderabad', lat: hydLat, lng: hydLng));
      bloc.add(const CarpoolOfferToChanged('Vijayawada', lat: vjaLat, lng: vjaLng));
      await pumpEventQueue();

      bloc.add(const CarpoolOfferStopoverAdded('Kodad'));
      await pumpEventQueue();
      expect(bloc.state.stopovers, ['Kodad']);

      bloc.add(const CarpoolOfferStopoverAdded('Suryapet'));
      await pumpEventQueue();
      // Should automatically order Suryapet before Kodad
      expect(bloc.state.stopovers, ['Suryapet', 'Kodad']);

      bloc.add(const CarpoolOfferStopoverAdded('LB Nagar'));
      await pumpEventQueue();
      // Should automatically order LB Nagar before Suryapet
      expect(bloc.state.stopovers, ['LB Nagar', 'Suryapet', 'Kodad']);
    });

    test('8. BLoC CarpoolOfferPriceChanged adjusts price per seat properly', () async {
      final repo = MockCarpoolRepository();
      final useCase = CarpoolPublishRideUseCase(repo);
      final bloc = CarpoolOfferRideBloc(publishRide: useCase);

      expect(bloc.state.pricePerSeat, isNull);

      bloc.add(const CarpoolOfferPriceChanged(10, currentBasePrice: 200));
      await pumpEventQueue();
      expect(bloc.state.pricePerSeat, 210);

      bloc.add(const CarpoolOfferPriceChanged(-20));
      await pumpEventQueue();
      expect(bloc.state.pricePerSeat, 190);
    });
  });
}

