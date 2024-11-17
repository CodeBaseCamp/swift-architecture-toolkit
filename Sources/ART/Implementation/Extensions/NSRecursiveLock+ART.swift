// Copyright © Rouven Strauss. MIT license.

import Foundation

public extension NSRecursiveLock {
  /// Locks the receiver, executes the given `closure`, and unlocks the receiver again.
  @inlinable
  func executeWhileLocked<T>(_ closure: () throws -> T) rethrows -> T {
    self.lock()

    defer { self.unlock() }

    return try closure()
  }
}
