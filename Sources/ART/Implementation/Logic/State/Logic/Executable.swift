// Copyright © Rouven Strauss. MIT license.

import Foundation

/// Object representing an executable consisting of requests which are initially handled in a single
/// transaction and in a synchronous fashion and pairs of side effects and completion closures. The
/// side effects are performed asynchronously and their corresponding completion closures are
/// executed once the corresponding side effect completes. The requests returned by the completion
/// closures are handled in single transactions and in a synchronous fashion.
public struct Executable<
  Request: RequestProtocol,
  SideEffect: SideEffectProtocol,
  Error: ErrorProtocol,
  BackgroundDispatchQueueID: BackgroundDispatchQueueIDProtocol
> {
  public typealias ExecutableSideEffect =
    CompositeSideEffect<SideEffect, Error, BackgroundDispatchQueueID>
  public typealias ExecutableCompletionClosure =
    (CompletionIndication<CompositeError<SideEffectExecutionError<Error>>>) -> [Request]

  let initialRequests: [Request]

  let sideEffect: ExecutableSideEffect

  let completion: ExecutableCompletionClosure

  private init(
    initialRequests: [Request] = [],
    sideEffect: ExecutableSideEffect = .doNothing,
    completion: @escaping ExecutableCompletionClosure = { _ in [] }
  ) {
    self.initialRequests = initialRequests
    self.sideEffect = sideEffect
    self.completion = completion
  }
}

public extension Executable {
  func withMappedRequest<NewRequest: RequestProtocol>(
    _ closure: @escaping (Request) -> NewRequest
  ) -> Executable<NewRequest, SideEffect, Error, BackgroundDispatchQueueID> {
    return Executable<NewRequest, SideEffect, Error, BackgroundDispatchQueueID>(
      initialRequests: self.initialRequests.map(closure),
      sideEffect: self.sideEffect,
      completion: { self.completion($0).map(closure) }
    )
  }

  static func request(_ request: Request) -> Self {
    return Self(initialRequests: [request])
  }

  static func requests(_ requests: Request ...) -> Self {
    return Self(initialRequests: requests)
  }

  static func requests(_ requests: [Request]) -> Self {
    return Self(initialRequests: requests)
  }

  static func sideEffect(
    _ sideEffect: ExecutableSideEffect,
    _ completion: @escaping ExecutableCompletionClosure = { _ in [] }
  ) -> Self {
    return Self(sideEffect: sideEffect, completion: completion)
  }

  static func successfulSideEffect(
    _ sideEffect: ExecutableSideEffect,
    _ completion: @escaping ExecutableCompletionClosure = { _ in [] }
  ) -> Self {
    return Self(sideEffect: sideEffect) {
      if let error = $0.error {
        fatalError(error.humanReadableDescription)
      }

      return completion($0)
    }
  }

  static func requestAndSideEffect(
    _ initialRequest: Request,
    sideEffect: ExecutableSideEffect,
    _ completion: @escaping ExecutableCompletionClosure = { _ in [] }
  ) -> Self {
    return Self(initialRequests: [initialRequest],
                sideEffect: sideEffect,
                completion: completion)
  }

  static func requestsAndSideEffect(
    _ initialRequests: Request ...,
    sideEffect: ExecutableSideEffect,
    _ completion: @escaping ExecutableCompletionClosure = { _ in [] }
  ) -> Self {
    return Self(initialRequests: initialRequests,
                sideEffect: sideEffect,
                completion: completion)
  }

  static func requestsAndSideEffect(
    _ initialRequests: [Request],
    _ sideEffect: ExecutableSideEffect,
    _ completion: @escaping ExecutableCompletionClosure = { _ in [] }
  ) -> Self {
    return Self(initialRequests: initialRequests,
                sideEffect: sideEffect,
                completion: completion)
  }

  static func requestsAndSuccessfulSideEffect(
    _ initialRequests: Request ...,
    sideEffect: ExecutableSideEffect,
    _ completion: @escaping ExecutableCompletionClosure = { _ in [] }
  ) -> Self {
    return Self(initialRequests: initialRequests,
                sideEffect: sideEffect) {
      if let error = $0.error {
        fatalError(error.humanReadableDescription)
      }

      return completion($0)
    }
  }
}
