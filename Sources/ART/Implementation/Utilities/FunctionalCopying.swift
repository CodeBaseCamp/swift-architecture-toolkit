// Copyright © Rouven Strauss. MIT license.

public extension Optional {
  /// Applies the given `closure` to the receiver if it is not `nil`.
  func apply(closure: (Wrapped) -> Void) {
    guard let unwrappedSelf = self else { return }
    closure(unwrappedSelf)
  }
}

public func copied<T>(_ value: T, closure: (inout T) -> Void) -> T {
  var copyOfValue = value
  closure(&copyOfValue)
  return copyOfValue
}

public func copied<T, S>(_ value: T, with keyPath: WritableKeyPath<T, S>, _ current: S) -> T {
  return copied(value) { $0[keyPath: keyPath] = current }
}
