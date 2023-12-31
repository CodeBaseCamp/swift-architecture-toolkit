// Copyright © Rouven Strauss. MIT license.

import Foundation

/// Object responsible for updating the application state according to received requests and 
/// manipulating the system state by performing side effects. Typically, an application holds a 
/// single logic module.
public class LogicModule<
  State: StateProtocol,
  Request: RequestProtocol,
  SideEffectPerformer: SideEffectPerformerProtocol
>: ExecutableExecutor {
  public typealias SideEffect = SideEffectPerformer.SideEffect
  public typealias Error = SideEffectPerformer.Error
  public typealias Coeffects = SideEffectPerformer.Coeffects
  public typealias BackgroundDispatchQueueID = SideEffectPerformer.BackgroundDispatchQueueID
  public typealias Model = ART.Model<State, Request, Coeffects>
  public typealias CompletionClosure = SideEffectPerformer.CompletionClosure
  public typealias SideEffectClosure = SideEffectPerformer.SideEffectClosure
  public typealias Executable =
    ART.Executable<Request, SideEffect, Error, BackgroundDispatchQueueID>

  /// Underlying model provided upon initialization.
  private let model: Model

  /// Performer of side effects provided upon initialization.
  private let sideEffectPerformer: SideEffectPerformer

  /// Strongly held references to the static model observers.
  private let observerReferences: [Any]

  /// Objects providing co-effect functionality.
  public let coeffects: Coeffects

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
  public func executeSequentially(_ executables: [Executable]) {
    guard let currentExecutable = executables.first else {
      return
    }

    self.model.handleInSingleTransaction(currentExecutable.initialRequests, using: self.coeffects)

    self.perform(currentExecutable.sideEffect) {
      self.model.handleInSingleTransaction(currentExecutable.completion($0), using: self.coeffects)

      self.executeSequentially(Array(executables.dropFirst()))
    }
  }

  /// Performs the given `sideEffect`. Upon completion of the side effect, the given `completion`
  /// closure is invoked with the corresponding completion indication.
  public func perform(
    _ sideEffect: CompositeSideEffect<SideEffect, Error, BackgroundDispatchQueueID>,
    completion: @escaping SideEffectPerformer.CompletionClosure = {
      if let error = $0.error {
        fatalError("Received unexpected failure: \(error)")
      }
    }
  ) {
    self.sideEffectPerformer.perform(sideEffect, using: self.coeffects, completion: completion)
  }

  /// Performs the given `sideEffect` and deliberately ignores any occurring failure.
  public func performWhileIgnoringFailure(
    _ sideEffect: CompositeSideEffect<SideEffect, Error, BackgroundDispatchQueueID>
  ) {
    self.sideEffectPerformer.perform(sideEffect, using: self.coeffects) { _ in }
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
