// Copyright © Rouven Strauss. MIT license.

import Foundation

/// Protocol implemented by objects allowing for the execution of `Executable`s.
public protocol TaskBasedExecutableExecutor {
  associatedtype Request: RequestProtocol
  associatedtype SideEffect: SideEffectProtocol
  associatedtype SideEffectError: ErrorProtocol

  typealias Executable =  TaskBasedExecutable<Request, SideEffect, SideEffectError>

  /// Serially executes the given `executables`.
  func executeSequentially(_ executables: [Executable]) async

  /// Handles the given `requests` in a single transaction.
  nonisolated func handleInSingleTransaction(_ requests: [Request])
}

public extension TaskBasedExecutableExecutor {
  /// Executes the given `executable`.
  func execute(_ executable: Executable) async {
    await self.executeSequentially([executable])
  }

  /// Handles the given `request`.
  nonisolated func handle(_ request: Request) {
    self.handleInSingleTransaction([request])
  }
}
