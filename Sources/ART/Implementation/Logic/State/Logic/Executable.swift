// Copyright © Rouven Strauss. MIT license.

import Foundation

public enum ExecutableFollowUpBehavior<Request: RequestProtocol>: Equatable, Sendable {
  case nothing
  case crashUponFailure(successRequests: [Request])
  case debugCrashUponFailure([SuccessIndication: [Request]])
  case requests([SuccessIndication: [Request]])
}

/// Object representing an executable consisting of requests which are initially handled in a single
/// transaction and in a synchronous fashion and pairs of side effects and completion closures. The
/// side effects are performed asynchronously and their corresponding completion closures are
/// executed once the corresponding side effect completes. The requests returned by the completion
/// closures are handled in single transactions and in a synchronous fashion.
public struct Executable<
  Request: RequestProtocol,
  SideEffect: SideEffectProtocol,
  Error: ErrorProtocol
> {
  public typealias ExecutableSideEffect = CompositeSideEffect<SideEffect, Error>
  public typealias FollowUpBehavior = ExecutableFollowUpBehavior<Request>

  let initialRequests: [Request]

  let sideEffect: ExecutableSideEffect

  let followUpBehavior: FollowUpBehavior

  private init(
    initialRequests: [Request] = [],
    sideEffect: ExecutableSideEffect = .doNothing,
    followUpBehavior: FollowUpBehavior = .crashUponFailure
  ) {
    Self.validate(followUpBehavior)

    self.initialRequests = initialRequests
    self.sideEffect = sideEffect
    self.followUpBehavior = followUpBehavior
  }

  private static func validate(_ followUpBehavior: FollowUpBehavior) {
    switch followUpBehavior {
    case .nothing, .crashUponFailure, .debugCrashUponFailure:
      break
    case let .requests(finalRequests):
      ensure(finalRequests[.success] != nil && finalRequests[.failure] != nil,
             "Invalid final requests: \(finalRequests)")
    }
  }
}

public extension Executable {
  func withMappedRequest<NewRequest: RequestProtocol>(
    _ closure: @escaping (Request) -> NewRequest
  ) -> Executable<NewRequest, SideEffect, Error> {
    return Executable<NewRequest, SideEffect, Error>(
      initialRequests: self.initialRequests.map(closure),
      sideEffect: self.sideEffect
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

  static func successfulSideEffect(_ sideEffect: ExecutableSideEffect) -> Self {
    return Self(
      sideEffect: sideEffect,
      followUpBehavior: .crashUponFailure
    )
  }

  static func sideEffect(
    _ sideEffect: ExecutableSideEffect,
    followedBy followUpBehavior: FollowUpBehavior = .nothing
  ) -> Self {
    return Self(
      sideEffect: sideEffect,
      followUpBehavior: followUpBehavior
    )
  }

  static func requestAndSuccessfulSideEffect(
    _ initialRequest: Request,
    sideEffect: ExecutableSideEffect
  ) -> Self {
    return Self(
      initialRequests: [initialRequest],
      sideEffect: sideEffect,
      followUpBehavior: .crashUponFailure
    )
  }

  static func requestAndSideEffect(
    _ initialRequest: Request,
    sideEffect: ExecutableSideEffect,
    followedBy followUpBehavior: FollowUpBehavior = .nothing
  ) -> Self {
    return Self(
      initialRequests: [initialRequest],
      sideEffect: sideEffect,
      followUpBehavior: followUpBehavior
    )
  }

  static func requestsAndSuccessfulSideEffect(
    _ initialRequests: Request ...,
    sideEffect: ExecutableSideEffect
  ) -> Self {
    return Self(
      initialRequests: initialRequests,
      sideEffect: sideEffect,
      followUpBehavior: .crashUponFailure
    )
  }

  static func requestsAndSideEffect(
    _ initialRequests: Request ...,
    sideEffect: ExecutableSideEffect,
    followedBy followUpBehavior: FollowUpBehavior = .nothing
  ) -> Self {
    return Self(
      initialRequests: initialRequests,
      sideEffect: sideEffect,
      followUpBehavior: followUpBehavior
    )
  }

  static func requestsAndSuccessfulSideEffect(
    _ initialRequests: [Request],
    _ sideEffect: ExecutableSideEffect
  ) -> Self {
    return Self(
      initialRequests: initialRequests,
      sideEffect: sideEffect,
      followUpBehavior: .crashUponFailure
    )
  }

  static func requestsAndSideEffect(
    _ initialRequests: [Request],
    _ sideEffect: ExecutableSideEffect,
    followedBy followUpBehavior: FollowUpBehavior = .nothing
  ) -> Self {
    return Self(
      initialRequests: initialRequests,
      sideEffect: sideEffect,
      followUpBehavior: followUpBehavior
    )
  }
}

public extension ExecutableFollowUpBehavior {
  static var crashUponFailure: Self {
    return .crashUponFailure(successRequests: [])
  }

  static var debugCrashUponFailure: Self {
    return .debugCrashUponFailure([.failure: [], .success: []])
  }

  static func  requestsUponSuccess(_ requests: [Request]) -> Self {
    return .requests(
      [
        .success: requests,
        .failure: [],
      ]
    )
  }

  static func  requestsUponFailure(_ requests: [Request]) -> Self {
    return .requests(
      [
        .success: [],
        .failure: requests,
      ]
    )
  }

  static func requests(_ requests: [Request]) -> Self {
    return .requests(
      [
        .success: requests,
        .failure: requests,
      ]
    )
  }
}
