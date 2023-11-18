// Copyright © Rouven Strauss. MIT license.

import Foundation

/// Object responsible for the logic executed upon UI events.
public class UIEventLogicModule<
  Event: Equatable,
  State: StateProtocol,
  Request: RequestProtocol,
  SideEffectPerformer: SideEffectPerformerProtocol
> {
  public typealias Error = SideEffectPerformer.Error
  public typealias Coeffects = SideEffectPerformer.Coeffects
  public typealias BackgroundDispatchQueueID = SideEffectPerformer.BackgroundDispatchQueueID
  public typealias Module = LogicModule<State, Request, SideEffectPerformer>

  private let logicModule: Module
  private let coeffects: Coeffects
  private let handleEventClosure: (Event, State, Module.ExecutionOptions, Coeffects) -> Void
  private let shouldHandleClosure: (Event, State) -> Bool

  /// Initializes with the given `logicModule`, `coeffects`, `eventHandlingClosure`, and
  /// `shouldHandleClosure`.
  fileprivate init(
    _ logicModule: Module,
    _ coeffects: Coeffects,
    _ eventHandlingClosure: @escaping (Event, State, Module.ExecutionOptions, Coeffects) -> Void,
    _ shouldHandleClosure: @escaping (Event, State) -> Bool = { _, _ in return true }
  ) {
    self.logicModule = logicModule
    self.coeffects = coeffects
    self.handleEventClosure = eventHandlingClosure
    self.shouldHandleClosure = shouldHandleClosure
  }

  public func handle(_ event: Event, given state: State) {
    debugEnsure(Thread.isMainThread, "Code run on invalid thread: \(Thread.current)")

    guard self.shouldHandle(event, given: state) else {
      return
    }

    let executionOptions = Module.ExecutionOptions(
      handleInSingleTransaction: self.logicModule.handleInSingleTransaction,
      perform: self.logicModule.perform,
      executeSequentially: self.logicModule.executeSequentially
    )

    handleEventClosure(event, state, executionOptions, coeffects)
  }

  private func shouldHandle(_ event: Event, given state: State) -> Bool {
    return self.shouldHandleClosure(event, state)
  }
}

public extension LogicModule {
  struct ExecutionOptions {
    public let handleInSingleTransaction: ([Request]) -> Void

    public let perform: (
      CompositeSideEffect<SideEffect, Error, BackgroundDispatchQueueID>,
      @escaping CompletionClosure
    ) -> Void

    public let executeSequentially: ([Executable]) -> Void
  }

  func viewLogic<Event: Equatable>(
    handleEvent: @escaping (Event, State, ExecutionOptions, Coeffects) -> Void,
    shouldHandle: @escaping (Event, State) -> Bool = { _, _ in return true }
  ) -> UIEventLogicModule<
    Event,
    State,
    Request,
    SideEffectPerformer
  > {
    return .init(self, self.coeffects, handleEvent, shouldHandle)
  }
}

extension LogicModule.ExecutionOptions: ExecutableExecutor {
  public func perform(
    _ sideEffect: CompositeSideEffect<SideEffect, Error, BackgroundDispatchQueueID>
  ) {
    self.perform(sideEffect) {
      ensure(!$0.isFailure, "Received unexpected failure: \($0)")
    }
  }

  public func executeSequentially(_ executables: [LogicModule.Executable]) {
    self.executeSequentially(executables)
  }
}
