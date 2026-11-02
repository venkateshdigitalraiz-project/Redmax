abstract class PartyUseCase<Type, Params> {
  Future<Type> call(Params params);
}

class PartyNoParams {
  const PartyNoParams();
}
