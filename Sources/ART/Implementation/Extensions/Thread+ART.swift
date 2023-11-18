// Copyright © Rouven Strauss. MIT license.

import Foundation

public extension Thread {
  /// Executes the given `closure` on the main thread.
  @inline(__always) static func synchronouslyPerformOnMainThread(_ closure: () -> Void) {
    let closure: () throws -> Void = { closure() }
    try! Self.synchronouslyPerformOnMainThread(closure)
  }

  /// Executes the given `potentiallyThrowingClosure` on the main thread.
  @inline(__always) static func synchronouslyPerformOnMainThread(
    _ potentiallyThrowingClosure: () throws -> Void
  ) throws {
    guard !Thread.isMainThread else {
      try potentiallyThrowingClosure()
      return
    }

    try DispatchQueue.main.sync {
      try potentiallyThrowingClosure()
    }
  }
}
