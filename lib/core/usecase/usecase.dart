/// Base contract every domain use case implements.
///
/// [R] is what the use case returns, [Params] is its input. Use [NoParams]
/// when a use case takes no arguments.
abstract class UseCase<R, Params> {
  Future<R> call(Params params);
}

class NoParams {
  const NoParams();
}
