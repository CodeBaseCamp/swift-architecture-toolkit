// Copyright © Rouven Strauss. MIT license.

/// Value type holding a function which reduces given `State` and `Request` instances to a new
/// `State` instance, in-place.
public struct Reducer<
  State,
  Request: RequestProtocol,
  Coeffects
>: ReducerProtocol {
  /// Reduces the given `State` instance and the given `Request` instance to a new `State` value,
  /// in-place. The given `Coeffects` can be used for functional access to required coeffects.
  public let reduce: @Sendable (inout State, [Request], Coeffects) -> Void

  public init(_ reduce: @escaping @Sendable (inout State, [Request], Coeffects) -> Void) {
    self.reduce = reduce
  }
}

// MARK: - Extensions

public extension Reducer {
  /// Returns a reducer with the behavior of the receiver but invoking the given `closure` with the
  /// current state and request before reducing.
  func augmented(_ closure: @escaping @Sendable (State, [Request]) -> Void) -> Self {
    return Self { state, request, coeffects in
      closure(state, request)
      self.reduce(&state, request, coeffects)
    }
  }

  /// Returns a reducer with the behavior of the receiver but printing every request it receives.
  func agumentedWithRequestPrintingFunctionality() -> Self {
    return self.augmented { print($1) }
  }

  /// Returns a new reducer which first updates a given `State` instance using the receiver and then
  /// using the given `reducer`.
  func combined(
    with reducer: Reducer<State, Request, Coeffects>
  ) -> Reducer<State, Request, Coeffects> {
    return Reducer<State, Request, Coeffects> { state, request, coeffects in
      self.reduce(&state, request, coeffects)
      reducer.reduce(&state, request, coeffects)
    }
  }

  /// Returns a new reducer constructed from the receiver, applicable to state of type `SuperState`
  /// and requests of type `SuperRequest`.
  func reducerForSuperState<SuperState: Sendable, SuperRequest: Sendable>(
    stateKeyPath: @escaping @Sendable () -> WritableKeyPath<SuperState, State>,
    requestFromSuperRequest: @escaping @Sendable (SuperRequest) -> Request?
  ) -> Reducer<SuperState, SuperRequest, Coeffects> {
    Reducer<SuperState, SuperRequest, Coeffects> { superState, superRequests, coeffects in
      self.reduce(
        &superState[keyPath: stateKeyPath()],
        superRequests.compactMap { requestFromSuperRequest($0) },
        coeffects
      )
    }
  }

  /// Returns a new reducer constructed from the receiver, applicable to requests of type
  /// `SuperRequest`.
  func reducer<SuperRequest: Sendable>(
    requestFromSuperRequest: @escaping @Sendable (SuperRequest) -> Request?
  ) -> Reducer<State, SuperRequest, Coeffects> {
    Reducer<State, SuperRequest, Coeffects> { state, superRequests, coeffects in
      self.reduce(
        &state,
        superRequests.compactMap { requestFromSuperRequest($0) },
        coeffects
      )
    }
  }
}
