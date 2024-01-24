// Copyright © Rouven Strauss. MIT license.

import Foundation

/// Protocol implemented by objects allowing for the execution of `Executable`s.
public protocol TaskBasedExecutableExecutor {
  associatedtype Request: RequestProtocol
  associatedtype SideEffect: SideEffectProtocol
  associatedtype SideEffectError: ErrorProtocol

  typealias Executable = TaskBasedExecutable<Request, SideEffect, SideEffectError>
  typealias ExecutableResult =
    CompletionIndication<CompositeError<SideEffectExecutionError<SideEffectError>>>

  /// Executes the given `executable`.
  @discardableResult
  func execute(_ executable: Executable) async -> ExecutableResult

  /// Sequentially executes the given `executables`.
  @discardableResult
  func executeSequentially(_ executables: [Executable]) async -> [ExecutableResult]

  /// Handles the given `requests` in a single transaction.
  nonisolated func handleInSingleTransaction(_ requests: [Request])
}

public extension TaskBasedExecutableExecutor {
  /// Executes the given `executable`.
  func execute(_ executable: Executable) async {
    await self.executeSequentially([executable])
  }

  /// Executes the given `executable` asynchronously.
  func executeAsynchronously(_ executable: Executable) {
    Task {
      await self.execute(executable)
    }
  }

  /// Handles the given `request`.
  nonisolated func handle(_ request: Request) {
    self.handleInSingleTransaction([request])
  }
}
