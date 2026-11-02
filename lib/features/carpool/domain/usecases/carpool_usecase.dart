/// Base contract for every use case.
abstract class CarpoolUseCase<Type, Params> {
  Future<Type> call(Params params);
}

class CarpoolNoParams {
  const CarpoolNoParams();
}
