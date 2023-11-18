// Copyright © Rouven Strauss. MIT license.

import Foundation

/// Description of a composite asynchronously executed side effect.
public enum CompositeSideEffect<
  SideEffect: SideEffectProtocol,
  Error: ErrorProtocol,
  BackgroundDispatchQueueID: BackgroundDispatchQueueIDProtocol
>: Equatable {
  case doNothing

  case switchToDispatchQueue(DispatchQueueID<BackgroundDispatchQueueID>)

  case only(SideEffect, on: DispatchQueueID<BackgroundDispatchQueueID>)

  indirect case asynchronously(Self,
                               on: DispatchQueueID<BackgroundDispatchQueueID>,
                               andUponSuccess: Self,
                               uponFailure: Self,
                               andWrapErrorInside: Error?)

  indirect case concurrently([Self])
}

public extension CompositeSideEffect {
  /// Returns a side effect which first performs the given `sideEffect` asynchronously on the given
  /// `queueWithID` and afterwards performs the given `successSideEffect` in case of success and the
  /// given `failureSideEffect` in case of failure.
  ///
  /// If the given `error` is not `nil`, it is used to wrap a potential error generated due to the
  /// execution of the given `sideEffect` and `successSideEffect` or `failureSideEffect`,
  /// respectively.
  static func asynchronously(
    _ sideEffect: SideEffect,
    on queueWithID: DispatchQueueID<BackgroundDispatchQueueID>,
    andUponSuccess successSideEffect: CompositeSideEffect,
    uponFailure failureSideEffect: CompositeSideEffect,
    andWrapErrorInside error: Error?
  ) -> Self {
    return .asynchronously(
      .only(sideEffect, on: queueWithID),
      on: queueWithID,
      andUponSuccess: successSideEffect,
      uponFailure: failureSideEffect,
      andWrapErrorInside: error
    )
  }

  /// Returns a side effect which performs the given `sideEffect` asynchronously on the given
  /// `queueWithID` and which does nothing else upon both success and failure.
  /// If the given `error` is not `nil`, it is used to wrap a potential error generated due to the
  /// execution of the given `sideEffect`.
  static func asynchronously(_ sideEffect: SideEffect,
                             on queueWithID: DispatchQueueID<BackgroundDispatchQueueID>,
                             andWrapErrorInside error: Error? = nil) -> Self {
    return .asynchronously(
      sideEffect,
      on: queueWithID,
      andUponSuccess: .doNothing,
      uponFailure: .doNothing,
      andWrapErrorInside: error
    )
  }

  /// Returns a side effect which performs the given `sideEffect` asynchronously on the main thread
  /// and which does nothing else upon both success and failure.
  /// If the given `error` is not `nil`, it is used to wrap a potential error generated due to the
  /// execution of the given `sideEffect`.
  static func onMainThread(_ sideEffect: SideEffect,
                           andWrapErrorInside error: Error? = nil) -> Self {
    return .asynchronously(sideEffect, on: .mainThread, andWrapErrorInside: error)
  }

  /// Returns a side effect which performs the given `sideEffect` asynchronously on the background
  /// thread and which does nothing else upon both success and failure.
  /// If the given `error` is not `nil`, it is used to wrap a potential error generated due to the
  /// execution of the given `sideEffect`.
  static func inBackground(onThreadWithID threadID: BackgroundDispatchQueueID,
                           _ sideEffect: SideEffect,
                           andWrapErrorInside error: Error? = nil) -> Self {
    return .asynchronously(sideEffect, on: .backgroundThread(threadID), andWrapErrorInside: error)
  }

  /// Mode indicating which follow-up side effect another side effect should follow.
  enum FollowUpSideEffectMode {
    /// The side effect should only follow the success side effect.
    case success

    /// The side effect should only follow the failure side effect.
    case failure
  }

  /// Returns a side effect which performs the receiver asynchronously and afterwards performs the
  /// given `sideEffect` according to the given `mode`.
  func andInCaseOf(
    _ mode: FollowUpSideEffectMode,
    perform sideEffect: Self
  ) -> Self {
    let successSideEffect: Self
    let failureSideEffect: Self

    switch mode {
    case .success:
      successSideEffect = sideEffect
      failureSideEffect = .doNothing
    case .failure:
      successSideEffect = .doNothing
      failureSideEffect = sideEffect
    }

    switch self {
    case .doNothing:
      return sideEffect
    case let .switchToDispatchQueue(queueWithID):
      return .asynchronously(
        self,
        on: queueWithID,
        andUponSuccess: successSideEffect,
        uponFailure: failureSideEffect,
        andWrapErrorInside: nil
      )
    case let .only(_, queueWithID):
      return .asynchronously(
        self,
        on: queueWithID,
        andUponSuccess: successSideEffect,
        uponFailure: failureSideEffect,
        andWrapErrorInside: nil
      )
    case let .asynchronously(_, queueWithID, _, _, _):
      return .asynchronously(
        self,
        on: queueWithID,
        andUponSuccess: successSideEffect,
        uponFailure: failureSideEffect,
        andWrapErrorInside: nil
      )
    case .concurrently:
      return .asynchronously(
        self,
        on: .mainThread,
        andUponSuccess: successSideEffect,
        uponFailure: failureSideEffect,
        andWrapErrorInside: nil
      )
    }
  }

  /// Returns a side effect which performs the receiver asynchronously and afterwards performs the
  /// given `sideEffect`, regardless of whether performing the receiver failed.
  func andThenPerform(_ sideEffect: Self) -> Self {
    return self
      .andInCaseOf(.success, perform: sideEffect)
      .andInCaseOf(.failure, perform: sideEffect)
  }
}
