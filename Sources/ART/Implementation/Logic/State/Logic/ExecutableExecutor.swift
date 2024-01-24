// Copyright © Rouven Strauss. MIT license.

import Foundation

/// Protocol implemented by objects allowing for the execution of `Executable`s.
public protocol ExecutableExecutor {
  associatedtype Request: RequestProtocol
  associatedtype SideEffect: SideEffectProtocol
  associatedtype Error: ErrorProtocol
  associatedtype BackgroundDispatchQueueID: BackgroundDispatchQueueIDProtocol

  /// Sequentially executes the given `executables`.
  func executeSequentially(
    _ executables: [Executable<Request, SideEffect, Error, BackgroundDispatchQueueID>]
  )
}

public extension ExecutableExecutor {
  /// Executes the given `executable`.
  func execute(
    _ executable: Executable<Request, SideEffect, Error, BackgroundDispatchQueueID>
  ) {
    self.executeSequentially([executable])
  }

  /// Handles the given `request`.
  func handle(_ request: Request) {
    self.handleInSingleTransaction([request])
  }

  /// Handles the given `requests` in a single transaction.
  func handleInSingleTransaction(_ requests: [Request]) {
    self.execute(.requests(requests))
  }
}
