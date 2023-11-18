// Copyright © Rouven Strauss. MIT license.

import Foundation

public enum SideEffectExecutionError<Error: ErrorProtocol>: ErrorProtocol {
  case customError(Error)
  case sideEffectBulkExecutionError
}

public protocol SideEffectPerformerProtocol {
  associatedtype SideEffect: SideEffectProtocol
  associatedtype Error: ErrorProtocol
  associatedtype Coeffects: CoeffectsProtocol
  associatedtype BackgroundDispatchQueueID: BackgroundDispatchQueueIDProtocol

  typealias ResultError = CompositeError<SideEffectExecutionError<Error>>
  typealias CompletionClosure = (CompletionIndication<ResultError>) -> Void
  typealias SideEffectClosure = (SideEffect, Coeffects, @escaping CompletionClosure) -> Void

  func perform(
    _ sideEffect: CompositeSideEffect<SideEffect, Error, BackgroundDispatchQueueID>,
    using coeffects: Coeffects,
    completion: @escaping CompletionClosure
  )
}

public class SideEffectPerformer<
  SideEffect: SideEffectProtocol,
  Error: ErrorProtocol,
  Coeffects: CoeffectsProtocol,
  BackgroundDispatchQueueID: BackgroundDispatchQueueIDProtocol
>: SideEffectPerformerProtocol {
  public typealias ResultError = CompositeError<SideEffectExecutionError<Error>>
  public typealias CompletionClosure = (CompletionIndication<ResultError>) -> Void
  public typealias SideEffectClosure = (SideEffect,
                                        Coeffects,
                                        @escaping CompletionClosure) -> Void
  private typealias QueueID = DispatchQueueID<BackgroundDispatchQueueID>

  /// Available dispatch queues.
  private let dispatchQueues: [QueueID: DispatchQueue]

  /// Closure for performing side effects specified by `SideEffect` instances.
  private let sideEffectClosure: SideEffectClosure

  public init(dispatchQueues: [DispatchQueueID<BackgroundDispatchQueueID>: DispatchQueue],
              sideEffectClosure: @escaping SideEffectClosure) {
    Self.validate(dispatchQueues)

    self.dispatchQueues = dispatchQueues
    self.sideEffectClosure = sideEffectClosure
  }

  private static func validate(_ dispatchQueues: [QueueID: DispatchQueue]) {
    DispatchQueueID.allCases.forEach { id in
      ensure(dispatchQueues[id] != nil,
             "Incomplete dispatch queues dictionary: \(dispatchQueues.keys)")
    }
  }

  public func perform(
    _ sideEffect: CompositeSideEffect<SideEffect, Error, BackgroundDispatchQueueID>,
    using coeffects: Coeffects,
    completion: @escaping CompletionClosure
  ) {
    switch sideEffect {
    case .doNothing:
      completion(.success)

    case let .switchToDispatchQueue(dispatchQueueID):
      let dispatchQueue = self.dispatchQueues[dispatchQueueID]!

      dispatchQueue.async {
        completion(.success)
      }

    case let .only(sideEffect, on: dispatchQueueID):
      let dispatchQueue = self.dispatchQueues[dispatchQueueID]!

      dispatchQueue.async { [weak self] in
        self?.sideEffectClosure(sideEffect, coeffects) {
          switch $0 {
          case .success:
            completion(.success)
          case let .failure(error):
            completion(.failure(error))
          }
        }
      }

    case let .asynchronously(
      sideEffect,
      on: dispatchQueueID,
      andUponSuccess: successSideEffect,
      uponFailure: failureSideEffect,
      andWrapErrorInside: wrappingError
    ):
      let dispatchQueue = self.dispatchQueues[dispatchQueueID]!

      let nextCompletion: CompletionClosure = { result in
        // Executed by the dispatch queue used by the executed `sideEffect`.
        switch result {
        case .success:
          self.perform(successSideEffect, using: coeffects, completion: { result in

            // Make sure to execute on thread of dispatch queue determined by the given
            // `dispatchQueueID`.
            dispatchQueue.async {
              switch result {
              case .success:
                completion(.success)
              case let .failure(errorOfSuccessSideEffect):
                let error: SideEffectExecutionError<Error>?

                if let wrappingError = wrappingError {
                  error = .customError(wrappingError)
                } else {
                  error = nil
                }

                completion(.failure(.error(error, withUnderlyingError: errorOfSuccessSideEffect)))
              }
            }
          })
        case let .failure(errorOfSideEffect):
          self.perform(failureSideEffect, using: coeffects, completion: { result in

            // Make sure to execute on thread of dispatch queue determined by the given
            // `dispatchQueueID`.
            dispatchQueue.async {
              let error: SideEffectExecutionError<Error>?

              if let wrappingError = wrappingError {
                error = .customError(wrappingError)
              } else {
                error = nil
              }

              switch result {
              case .success:
                completion(.failure(.error(error, withUnderlyingError: errorOfSideEffect)))
              case let .failure(errorOfFailureSideEffect):
                let finalError: ResultError = .error(
                  error,
                  withUnderlyingError: .compositeError(
                    errorOfFailureSideEffect,
                    underlyingErrors: .single(errorOfSideEffect)
                  )
                )
                completion(.failure(finalError))
              }
            }
          })
        }
      }

      dispatchQueue.async { [weak self] in
        self?.perform(sideEffect, using: coeffects, completion: nextCompletion)
      }

    case let .concurrently(sideEffects):
      let lock = NSRecursiveLock()

      var accumulatedErrors: [ResultError] = []
      var indices = Set<Int>()
      var completion: CompletionClosure? = completion

      sideEffects.enumerated().forEach {
        let sideEffect = $0.element
        let index = $0.offset

        self.perform(sideEffect, using: coeffects) { result in
          lock.executeWhileLocked {
            indices.insert(index)

            switch result {
            case .success:
              break
            case let .failure(error):
              accumulatedErrors.append(error)
            }

            guard indices.count != sideEffects.count else {
              if accumulatedErrors.count == 0 {
                completion?(.success)
              } else {
                completion?(.failure(.compositeError(.simpleError(.sideEffectBulkExecutionError),
                                                     underlyingErrors: .from(accumulatedErrors))))
              }

              completion = nil
              return
            }
          }
        }
      }
    }
  }
}

public extension SideEffectExecutionError {
  var humanReadableDescription: String {
    switch self {
    case let .customError(customError):
      return customError.humanReadableDescription
    case .sideEffectBulkExecutionError:
      return "side effect bulk execution error"
    }
  }
}
