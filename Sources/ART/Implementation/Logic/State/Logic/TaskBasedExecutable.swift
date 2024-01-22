// Copyright © Rouven Strauss. MIT license.

import Foundation

/// Object representing an executable consisting of requests which are initially handled in a single
/// transaction and in a synchronous fashion and pairs of side effects and completion closures. The
/// side effects are performed asynchronously and their corresponding completion closures are
/// executed once the corresponding side effect completes. The requests returned by the completion
/// closures are handled in single transactions and in a synchronous fashion.
public struct TaskBasedExecutable<
  Request: RequestProtocol,
  SideEffect: SideEffectProtocol,
  Error: ErrorProtocol,
  BackgroundDispatchQueueID: BackgroundDispatchQueueIDProtocol
> {
  public typealias ExecutableSideEffect =
    CompositeSideEffect<SideEffect, Error, BackgroundDispatchQueueID>

  let initialRequests: [Request]

  let sideEffect: ExecutableSideEffect

  let finalRequests: [Request]

  private init(
    initialRequests: [Request] = [],
    sideEffect: ExecutableSideEffect = .doNothing,
    finalRequests: [Request] = []
  ) {
    self.initialRequests = initialRequests
    self.sideEffect = sideEffect
    self.finalRequests = finalRequests
  }
}

public extension TaskBasedExecutable {
  func withMappedRequest<NewRequest: RequestProtocol>(
    _ closure: @escaping (Request) -> NewRequest
  ) -> TaskBasedExecutable<NewRequest, SideEffect, Error, BackgroundDispatchQueueID> {
    return TaskBasedExecutable<NewRequest, SideEffect, Error, BackgroundDispatchQueueID>(
      initialRequests: self.initialRequests.map(closure),
      sideEffect: self.sideEffect,
      finalRequests: self.finalRequests.map(closure)
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

  static func sideEffect(_ sideEffect: ExecutableSideEffect) -> Self {
    return Self(sideEffect: sideEffect)
  }

  static func requestAndSideEffect(
    _ initialRequest: Request,
    sideEffect: ExecutableSideEffect
  ) -> Self {
    return Self(initialRequests: [initialRequest], sideEffect: sideEffect)
  }

  static func requestsAndSideEffect(
    _ initialRequests: Request ...,
    sideEffect: ExecutableSideEffect
  ) -> Self {
    return Self(initialRequests: initialRequests,
                sideEffect: sideEffect)
  }

  static func requestsAndSideEffect(
    _ initialRequests: [Request],
    _ sideEffect: ExecutableSideEffect
  ) -> Self {
    return Self(initialRequests: initialRequests,
                sideEffect: sideEffect)
  }
}
