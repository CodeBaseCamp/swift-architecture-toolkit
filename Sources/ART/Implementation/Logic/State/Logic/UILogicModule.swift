// Copyright © Rouven Strauss. MIT license.

import Foundation

/// Object responsible for the logic executed upon UI events.
public final class UIEventLogicModule<
  Event: Equatable,
  State: StateProtocol,
  Request: RequestProtocol,
  SideEffectPerformer: SideEffectPerformerProtocol
>: Sendable {
  public typealias SideEffectError = SideEffectPerformer.SideEffectError
  public typealias Coeffects = SideEffectPerformer.Coeffects
  public typealias Module = LogicModule<State, Request, SideEffectPerformer>

  private let logicModule: Module
  private let coeffects: Coeffects
  private let handleEventClosure: @Sendable (Event, State, Module.ExecutionOptions, Coeffects) async -> Void
  private let shouldHandleClosure: @Sendable (Event, State) -> Bool

  /// Initializes with the given `logicModule`, `coeffects`, `eventHandlingClosure`, and
  /// `shouldHandleClosure`.
  fileprivate init(
    _ logicModule: Module,
    _ coeffects: Coeffects,
    _ eventHandlingClosure: @escaping @Sendable (Event, State, Module.ExecutionOptions, Coeffects) async -> Void,
    _ shouldHandleClosure: @escaping @Sendable (Event, State) -> Bool = { _, _ in return true }
  ) {
    self.logicModule = logicModule
    self.coeffects = coeffects
    self.handleEventClosure = eventHandlingClosure
    self.shouldHandleClosure = shouldHandleClosure
  }

  public func handle(_ event: Event, given state: State) async {
    guard self.shouldHandle(event, given: state) else {
      return
    }

    let executionOptions = Module.ExecutionOptions(
      handleInSingleTransaction: self.logicModule.handleInSingleTransaction,
      perform: self.logicModule.perform,
      executeSequentially: self.logicModule.executeSequentially
    )
    await handleEventClosure(event, state, executionOptions, coeffects)
  }

  private func shouldHandle(_ event: Event, given state: State) -> Bool {
    return self.shouldHandleClosure(event, state)
  }
}

public extension LogicModule {
  struct ExecutionOptions: Sendable {
    public typealias CompositeSideEffect = ART.CompositeSideEffect<SideEffect, SideEffectError>
    public typealias CompletionIndication = SideEffectPerformer.CompletionIndication

    public let handleInSingleTransaction: @Sendable ([Request]) async -> Void

    public let perform: @Sendable (CompositeSideEffect) async -> CompletionIndication

    public let executeSequentially: @Sendable ([Executable]) async -> [CompletionIndication]

    public init(
      handleInSingleTransaction: @escaping @Sendable ([Request]) async -> Void,
      perform: @escaping @Sendable (CompositeSideEffect) async -> CompletionIndication,
      executeSequentially: @escaping @Sendable ([Executable]) async -> [CompletionIndication]
    ) {
      self.handleInSingleTransaction = handleInSingleTransaction
      self.perform = perform
      self.executeSequentially = executeSequentially
    }
  }

  nonisolated func viewLogic<Event: Equatable>(
    handleEvent: @escaping @Sendable (Event, State, ExecutionOptions, Coeffects) async -> Void,
    shouldHandle: @escaping @Sendable (Event, State) -> Bool = { _, _ in return true }
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
  public func execute(_ executable: LogicModule.Executable) async -> CompletionIndication {
    let completionIndications = await self.executeSequentially([executable])

    debugEnsure(completionIndications.count == 1,
                "Invalid completion indications: \(completionIndications)")

    return completionIndications[0]
  }
  
  public func executeSequentially(
    _ executables: [LogicModule.Executable]
  ) async -> [CompletionIndication] {
    await self.executeSequentially(executables)
  }

  public func performSuccessfully(_ sideEffect: CompositeSideEffect) async {
    let completionIndication = await self.perform(sideEffect)
    if let error = completionIndication.error {
      fatalError("Side effect failed with error: \(error.humanReadableDescription)")
    }
  }

  public func perform(_ sideEffect: SideEffect) async -> CompletionIndication {
    return await self.perform(.only(sideEffect))
  }

  public func handleInSingleTransaction(_ requests: [Request]) async {
    await self.handleInSingleTransaction(requests)
  }
}
