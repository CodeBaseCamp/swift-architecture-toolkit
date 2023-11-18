// Copyright © Rouven Strauss. MIT license.

@discardableResult
public func make<T>(_ value: T, closure: (inout T) -> Void) -> T {
  var copyOfValue = value
  closure(&copyOfValue)
  return copyOfValue
}

@discardableResult
public func make<T>(_ value: T, closure: (inout T) throws -> Void) throws -> T {
  var copyOfValue = value
  try closure(&copyOfValue)
  return copyOfValue
}

public func update<T>(_ value: T, closure: (T) -> Void) {
  closure(value)
}

public func update<T>(_ value: T, closure: (T) throws -> Void) throws {
  try closure(value)
}
