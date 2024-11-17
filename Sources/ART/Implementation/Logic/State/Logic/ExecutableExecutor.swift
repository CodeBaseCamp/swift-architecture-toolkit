// Copyright © Rouven Strauss. MIT license.

import Foundation

/// Protocol implemented by objects allowing for the execution of `Executable`s.
public protocol ExecutableExecutor {
  associatedtype Request: RequestProtocol
  associatedtype SideEffect: SideEffectProtocol
  associatedtype SideEffectError: ErrorProtocol

  typealias Executable = ART.Executable<Request, SideEffect, SideEffectError>
  typealias ExecutableResult =
    CompletionIndication<CompositeError<SideEffectExecutionError<SideEffectError>>>

  /// Executes the given `executable`.
  @discardableResult
  func execute(_ executable: Executable) async -> ExecutableResult

  /// Sequentially executes the given `executables`.
  @discardableResult
  func executeSequentially(_ executables: [Executable]) async -> [ExecutableResult]

  /// Handles the given `requests` in a single transaction.
  func handleInSingleTransaction(_ requests: [Request]) async
}

public extension ExecutableExecutor {
  /// Executes the given `executable`.
  func execute(_ executable: Executable) async {
    await self.executeSequentially([executable])
  }

  /// Handles the given `request`.
  func handle(_ request: Request) async {
    await self.handleInSingleTransaction([request])
  }
}
