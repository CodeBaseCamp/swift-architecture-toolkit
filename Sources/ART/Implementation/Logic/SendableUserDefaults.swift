// Copyright © Rouven Strauss. MIT license.

import Foundation

public final class SendableUserDefaults: @unchecked Sendable {
  private let underlyingUserDefaults: UserDefaults

  private let lock = NSLock()

  public init(_ underlyingUserDefaults: UserDefaults) {
    self.underlyingUserDefaults = underlyingUserDefaults
  }

  public func set<T: Sendable>(_ object: T?, forKey key: String) {
    self.lock.withLock {
      self.underlyingUserDefaults.set(object, forKey: key)
    }
  }

  public func object<T: Sendable>(forKey key: String) -> T? {
    return self.lock.withLock {
      return self.underlyingUserDefaults.object(forKey: key) as? T
    }
  }
}
