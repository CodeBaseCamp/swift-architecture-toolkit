// Copyright © Rouven Strauss. MIT license.

import Foundation

/// Object responsible for the logic executed upon UI events.
public actor TaskBasedUIEventLogicModule<
  Event: Equatable,
  State: StateProtocol,
  Request: RequestProtocol,
  SideEffectPerformer: TaskBasedSideEffectPerformerProtocol
> {
  public typealias SideEffectError = SideEffectPerformer.SideEffectError
  public typealias Coeffects = SideEffectPerformer.Coeffects
  public typealias Module = TaskBasedLogicModule<State, Request, SideEffectPerformer>

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

public extension TaskBasedLogicModule {
  struct ExecutionOptions {
    public typealias CompositeSideEffect = TaskBasedCompositeSideEffect<SideEffect, SideEffectError>
    public typealias CompletionIndication = SideEffectPerformer.CompletionIndication

    public let handleInSingleTransaction: ([Request]) -> Void

    public let perform: (CompositeSideEffect) async -> CompletionIndication

    public let executeSequentially: ([Executable]) async -> Void

    public init(
      handleInSingleTransaction: @escaping ([Request]) -> Void,
      perform: @escaping (CompositeSideEffect) async -> CompletionIndication,
      executeSequentially: @escaping ([Executable]) async -> Void
    ) {
      self.handleInSingleTransaction = handleInSingleTransaction
      self.perform = perform
      self.executeSequentially = executeSequentially
    }
  }

  nonisolated func viewLogic<Event: Equatable>(
    handleEvent: @escaping (Event, State, ExecutionOptions, Coeffects) -> Void,
    shouldHandle: @escaping (Event, State) -> Bool = { _, _ in return true }
  ) -> TaskBasedUIEventLogicModule<
    Event,
    State,
    Request,
    SideEffectPerformer
  > {
    return .init(self, self.coeffects, handleEvent, shouldHandle)
  }
}

extension TaskBasedLogicModule.ExecutionOptions: TaskBasedExecutableExecutor {
  public func executeSequentially(_ executables: [TaskBasedLogicModule.Executable]) async {
    await self.executeSequentially(executables)
  }

  public nonisolated func perform(_ sideEffect: CompositeSideEffect) {
    Task {
      _ = await self.perform(sideEffect)
    }
  }

  public func perform(_ sideEffect: SideEffect) async -> CompletionIndication {
    return await self.perform(.only(sideEffect))
  }

  public nonisolated func handleInSingleTransaction(_ requests: [Request]) {
    self.handleInSingleTransaction(requests)
  }
}
