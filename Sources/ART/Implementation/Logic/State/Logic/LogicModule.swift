// Copyright © Rouven Strauss. MIT license.

import Foundation

/// Object responsible for updating the application state according to received requests and
/// manipulating the system state by performing side effects. Typically, an application holds a
/// single logic module.
public actor LogicModule<
  State: StateProtocol,
  Request: RequestProtocol,
  SideEffectPerformer: SideEffectPerformerProtocol
>: ExecutableExecutor {
  public typealias SideEffect = SideEffectPerformer.SideEffect
  public typealias SideEffectError = SideEffectPerformer.SideEffectError
  public typealias Coeffects = SideEffectPerformer.Coeffects
  public typealias CompositeSideEffect = ART.CompositeSideEffect<SideEffect, SideEffectError>
  public typealias CompletionIndication = SideEffectPerformer.CompletionIndication
  public typealias Model = ART.Model<State, Request, Coeffects>
  public typealias Executable = ART.Executable<Request, SideEffect, SideEffectError>

  /// Underlying model provided upon initialization.
  private let model: Model

  /// Performer of side effects provided upon initialization.
  private let sideEffectPerformer: SideEffectPerformer

  /// Strongly held references to the static model observers.
  private let observerReferences: [Any]

  /// Objects providing co-effect functionality.
  public nonisolated let coeffects: Coeffects

  /// Initializes with the given `model` and the given `staticObservers` tuple consisting of a model
  /// observer which is weakly held by the initialized instance and a type-erased reference to an
  /// arbitrary object strongly holding the aforementioned model observer. The aforementioned
  /// type-erased reference is held strongly by the initialized instance in order to prevent the
  /// deallocation of the aforementioned model observer.
  ///
  /// - important The given model observers are added to the given `model` and are informed about
  ///             relevant observations until the deallocation of the initialized instance.
  /// - important Observers which should be deallocated before the returned object is deallocated
  ///             should not be part of the initialization but should be added using the `add`
  ///             method of the returned object.
  public init(
    model: Model,
    sideEffectPerformer: SideEffectPerformer,
    coeffects: Coeffects,
    staticObservers: [(ModelObserver<State>, Any)] = []
  ) {
    self.model = model
    self.sideEffectPerformer = sideEffectPerformer
    self.coeffects = coeffects
    self.observerReferences = staticObservers.map(\.1)

    staticObservers.map(\.0).forEach {
      model.add($0)
    }
  }

  /// Sequentially executes the given `executables`.
  @discardableResult
  public func execute(_ executable: Executable) async -> CompletionIndication {
    self.model.handleInSingleTransaction(executable.initialRequests, using: self.coeffects)

    let result = await self.perform(executable.sideEffect)

    switch executable.followUpBehavior {
    case .nothing:
      break
    
    case let .crashUponFailure(requests):
      if let error = result.error {
        fatalError("Error: \(error)")
      }

      self.model.handleInSingleTransaction(requests, using: self.coeffects)
    
    case let .requests(requests):
      self.model.handleInSingleTransaction(
        requiredLet(requests[result.successIndication], "Must exist"),
        using: self.coeffects
      )
    }

    return result
  }

  /// Sequentially executes the given `executables`.
  @discardableResult
  public func executeSequentially(_ executables: [Executable]) async -> [CompletionIndication] {
    guard let currentExecutable = executables.first else {
      return []
    }

    let completionIndication = await self.execute(currentExecutable)
    let completionIndications = await self.executeSequentially(Array(executables.dropFirst()))

    return [completionIndication] + completionIndications
  }

  /// Returns a task performing the given `sideEffect`. Upon completion of the side effect, the
  /// given `completion` closure is invoked with the corresponding completion indication.
  @discardableResult
  public func task(
    performing sideEffect: CompositeSideEffect
  ) async -> Task<CompletionIndication, Error> {
    return await self.sideEffectPerformer.task(performing: sideEffect, using: self.coeffects)
  }

  /// Performs the given `sideEffect` and returns the corresponding completion indication.
  @discardableResult
  public func perform(
    _ sideEffect: CompositeSideEffect
  ) async -> CompletionIndication {
    return await self.sideEffectPerformer.perform(sideEffect, using: self.coeffects)
  }

  /// Performs the given `sideEffect` asynchronously, ensuring that the side effect completed
  /// successfully.
  public nonisolated func performSuccessfully(_ sideEffect: CompositeSideEffect) {
    Task {
      let completionIndication =
        await self.sideEffectPerformer.perform(sideEffect, using: self.coeffects)
      if let error = completionIndication.error {
        fatalError("Side effect failed with error: \(error.humanReadableDescription)")
      }
    }
  }

  /// Returns a task performing the given `sideEffect`. Upon completion of the side effect, the
  /// given `completion` closure is invoked with the corresponding completion indication.
  @discardableResult
  public func perform(
    _ sideEffect: SideEffect
  ) async -> CompletionIndication {
    return await self.perform(.only(sideEffect))
  }

  /// Performs the given `sideEffect` asynchronously, ignoring any completion indication.
  public nonisolated func performSuccessfully(_ sideEffect: SideEffect) {
    self.performSuccessfully(.only(sideEffect))
  }

  public nonisolated func handleInSingleTransaction(_ requests: [Request]) {
    self.model.handleInSingleTransaction(requests, using: self.coeffects)
  }

  /// Adds the given `observer` to the receiver. The `observer` is immediately informed about the
  /// current value at the `keyPath` of the `observer`. Upon every change of the value at the
  /// `keyPath` of the `observer`, the `observer` is informed about the change.
  ///
  /// - important: The given `observer` is held weakly by the receiver.
  public func add(_ observer: ModelObserver<State>) {
    self.model.add(observer)
  }
}
