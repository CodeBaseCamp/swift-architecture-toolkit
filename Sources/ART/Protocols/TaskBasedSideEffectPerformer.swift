// Copyright © Rouven Strauss. MIT license.

import Foundation

public protocol TaskBasedSideEffectPerformerProtocol: Actor {
  associatedtype SideEffect: SideEffectProtocol
  associatedtype SideEffectError: ErrorProtocol
  associatedtype Coeffects: CoeffectsProtocol

  typealias CompositeSideEffect =
    TaskBasedCompositeSideEffect<SideEffect, SideEffectError>
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
  Coeffects: CoeffectsProtocol
>: TaskBasedSideEffectPerformerProtocol {
  public typealias CompositeSideEffect =
    TaskBasedCompositeSideEffect<SideEffect, SideEffectError>
  public typealias Result<Error: ErrorProtocol> =
    CompletionIndication<CompositeError<SideEffectExecutionError<Error>>>
  public typealias SideEffectClosure = (SideEffect, Coeffects) async -> Result<SideEffectError>

  private let sideEffectClosure: SideEffectClosure

  public init(sideEffectClosure: @escaping SideEffectClosure) {
    self.sideEffectClosure = sideEffectClosure
  }

  @discardableResult
  public func task(
    performing sideEffect: CompositeSideEffect,
    using coeffects: Coeffects
  ) async -> Task<Result<SideEffectError>, Error> {
    return Task { [unowned self] in
      return await self.perform(sideEffect, using: coeffects)
    }
  }

  @discardableResult
  public func perform(
    _ sideEffect: CompositeSideEffect,
    using coeffects: Coeffects
  ) async -> Result<SideEffectError> {
    switch sideEffect {
    case .doNothing:
      return .success

    case let .only(sideEffect):
      return await sideEffectClosure(sideEffect, coeffects)

    case let .asynchronously(
      sideEffect,
      andUponSuccess: successSideEffect,
      uponFailure: failureSideEffect,
      andWrapErrorInside: wrappingError
    ):
      let result = await self.perform(sideEffect, using: coeffects)

      switch result {
      case .success:
        switch await self.perform(successSideEffect, using: coeffects) {
        case .success:
          return .success
        case let .failure(errorOfSuccessSideEffect):
          let error: SideEffectExecutionError<SideEffectError>?

          if let wrappingError = wrappingError {
            error = .customError(wrappingError)
          } else {
            error = nil
          }

          return .failure(.error(error, withUnderlyingError: errorOfSuccessSideEffect))
        }
      case let .failure(errorOfSideEffect):
        let error: SideEffectExecutionError<SideEffectError>?

        if let wrappingError = wrappingError {
          error = .customError(wrappingError)
        } else {
          error = nil
        }

        switch await self.perform(failureSideEffect, using: coeffects) {
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
      let result: Result<SideEffectError> = 
        await withTaskGroup(of: Result<SideEffectError>.self) { taskGroup in
          for sideEffect in sideEffects {
            taskGroup.addTask {
              await self.perform(sideEffect, using: coeffects)
            }
          }

          let errors: [CompositeError<SideEffectExecutionError<SideEffectError>>] = await taskGroup
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