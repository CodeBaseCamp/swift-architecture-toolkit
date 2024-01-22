// Copyright © Rouven Strauss. MIT license.

import Foundation

public protocol SideEffectPerformerActor: Actor {
}

extension MainActor: SideEffectPerformerActor {}

public actor BackgroundActor: SideEffectPerformerActor {
  public init() {}
}

public protocol TaskBasedSideEffectPerformerProtocol: Actor {
  associatedtype SideEffect: SideEffectProtocol
  associatedtype SideEffectError: ErrorProtocol
  associatedtype Coeffects: CoeffectsProtocol
  associatedtype BackgroundDispatchQueueID: BackgroundDispatchQueueIDProtocol

  typealias CompositeSideEffect = 
    ART.CompositeSideEffect<SideEffect, SideEffectError, BackgroundDispatchQueueID>
  typealias Result<Error: ErrorProtocol> =
    CompletionIndication<CompositeError<SideEffectExecutionError<Error>>>

  @discardableResult
  func task(
    performing sideEffect: CompositeSideEffect,
    using coeffects: Coeffects
  ) async -> Task<Result<SideEffectError>, Error>

  @discardableResult
  func perform(
    _ sideEffect: CompositeSideEffect,
    using coeffects: Coeffects
  ) async -> Result<SideEffectError>
}

public actor TaskBasedSideEffectPerformer<
  SideEffect: SideEffectProtocol,
  SideEffectError: ErrorProtocol,
  Coeffects: CoeffectsProtocol,
  BackgroundDispatchQueueID: BackgroundDispatchQueueIDProtocol
>: TaskBasedSideEffectPerformerProtocol {
  public typealias CompositeSideEffect =
    ART.CompositeSideEffect<SideEffect, SideEffectError, BackgroundDispatchQueueID>
  public typealias Result<Error: ErrorProtocol> =
    CompletionIndication<CompositeError<SideEffectExecutionError<Error>>>
  public typealias SideEffectClosure = (SideEffect, Coeffects) async -> Result<SideEffectError>

  private let actors: [DispatchQueueID<BackgroundDispatchQueueID>: SideEffectPerformerActor]
  private let sideEffectClosure: SideEffectClosure

  private let defaultActor = BackgroundActor()

  public init(
    actors: [DispatchQueueID<BackgroundDispatchQueueID>: SideEffectPerformerActor],
    sideEffectClosure: @escaping SideEffectClosure
  ) {
    self.actors = actors
    self.sideEffectClosure = sideEffectClosure
  }

  @discardableResult
  public func task(
    performing sideEffect: CompositeSideEffect,
    using coeffects: Coeffects
  ) async -> Task<Result<SideEffectError>, Error> {
    return Task { [unowned self] in
      return await self.defaultActor.perform(
        sideEffect: sideEffect,
        using: coeffects,
        actors: self.actors,
        sideEffectClosure: self.sideEffectClosure
      )
    }
  }

  @discardableResult
  public func perform(
    _ sideEffect: CompositeSideEffect,
    using coeffects: Coeffects
  ) async -> Result<SideEffectError> {
    return await self.defaultActor.perform(
      sideEffect: sideEffect,
      using: coeffects,
      actors: self.actors,
      sideEffectClosure: self.sideEffectClosure
    )
  }
}

extension SideEffectPerformerActor {
  typealias Result<Error: ErrorProtocol> =
    CompletionIndication<CompositeError<SideEffectExecutionError<Error>>>

  fileprivate func perform<
    SideEffect: SideEffectProtocol,
    Error: ErrorProtocol,
    Coeffects: CoeffectsProtocol
  >(
    sideEffect: SideEffect,
    using coeffects: Coeffects,
    sideEffectClosure: @escaping (SideEffect, Coeffects) async -> Result<Error>
  ) async -> Result<Error> {
    return await sideEffectClosure(sideEffect, coeffects)
  }

  fileprivate func perform<
    SideEffect: SideEffectProtocol,
    BackgroundDispatchQueueID: BackgroundDispatchQueueIDProtocol,
    Error: ErrorProtocol,
    Coeffects: CoeffectsProtocol
  >(
    sideEffect: CompositeSideEffect<SideEffect, Error, BackgroundDispatchQueueID>,
    using coeffects: Coeffects,
    actors: [DispatchQueueID<BackgroundDispatchQueueID>: SideEffectPerformerActor],
    sideEffectClosure: @escaping (SideEffect, Coeffects) async -> Result<Error>
  ) async -> Result<Error> {
    switch sideEffect {
    case .doNothing:
      return .success

    case .switchToDispatchQueue:
      return .success

    case let .only(sideEffect, actorID):
      let actor = requiredLet(actors[actorID], "Actor must exist for ID: \(actorID)")

      return await actor.perform(
        sideEffect: sideEffect,
        using: coeffects,
        sideEffectClosure: sideEffectClosure
      )

    case let .asynchronously(
      sideEffect,
      on: actorID,
      andUponSuccess: successSideEffect,
      uponFailure: failureSideEffect,
      andWrapErrorInside: wrappingError
    ):
      let actor = requiredLet(actors[actorID], "Actor must exist for ID: \(actorID)")
      let result = await actor.perform(
        sideEffect: sideEffect,
        using: coeffects,
        actors: actors,
        sideEffectClosure: sideEffectClosure
      )

      switch result {
      case .success:
        let result = await self.perform(
          sideEffect: successSideEffect,
          using: coeffects,
          actors: actors,
          sideEffectClosure: sideEffectClosure
        )
        switch result {
        case .success:
          return .success
        case let .failure(errorOfSuccessSideEffect):
          let error: SideEffectExecutionError<Error>?

          if let wrappingError = wrappingError {
            error = .customError(wrappingError)
          } else {
            error = nil
          }

          return .failure(.error(error, withUnderlyingError: errorOfSuccessSideEffect))
        }
      case let .failure(errorOfSideEffect):
        let result = await self.perform(
          sideEffect: failureSideEffect,
          using: coeffects,
          actors: actors,
          sideEffectClosure: sideEffectClosure
        )

        let error: SideEffectExecutionError<Error>?

        if let wrappingError = wrappingError {
          error = .customError(wrappingError)
        } else {
          error = nil
        }

        switch result {
        case .success:
          return .failure(.error(error, withUnderlyingError: errorOfSideEffect))
        case let .failure(errorOfFailureSideEffect):
          return .failure(
            .error(
              error,
              withUnderlyingError: .compositeError(
                errorOfFailureSideEffect,
                underlyingErrors: .single(errorOfSideEffect)
              )
            )
          )
        }
      }

    case let .concurrently(sideEffects):
      let result: Result<Error> = await withTaskGroup(of: Result<Error>.self) { taskGroup in
        for sideEffect in sideEffects {
          taskGroup.addTask {
            await self.perform(
              sideEffect: sideEffect,
              using: coeffects,
              actors: actors,
              sideEffectClosure: sideEffectClosure
            )
          }
        }

        let errors: [CompositeError<SideEffectExecutionError<Error>>] = await taskGroup
          .compactMap { $0.error }
          .reduce([]) { $0 + [$1] }

        guard !errors.isEmpty else {
          return .success
        }

        return .failure(
          .compositeError(
            .simpleError(.sideEffectBulkExecutionError),
            underlyingErrors: .from(errors)
          )
        )
      }

      return result
    }
  }
}
