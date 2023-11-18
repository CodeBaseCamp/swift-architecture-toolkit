// Copyright © Rouven Strauss. MIT license.

/// Object weakly holding another instance.
public final class WeakContainer<T: AnyObject> {
  /// Weakly held instance.
  weak var weaklyHeldInstance: T?

  /// Initializes with the given `instance`.
  init(containing instance: T) {
    self.weaklyHeldInstance = instance
  }
}
