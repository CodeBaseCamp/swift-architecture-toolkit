// Copyright © Rouven Strauss. MIT license.

import CasePaths
import Foundation

precedencegroup PropertyPathCombine {
  associativity: left
  lowerThan: AssignmentPrecedence
}

infix operator ~: PropertyPathCombine

public class PartialPropertyPath<Root> {}

/// Object constituting the path from the root of a `struct` to an internal property.
public class PropertyPath<Root, Value>: PartialPropertyPath<Root> {
  private let extractor: (Root) -> Value?

  private init(_ extractor: @escaping (Root) -> Value?) {
    self.extractor = extractor
  }

  public init(_ keyPath: KeyPath<Root, Value>) {
    self.extractor = { $0[keyPath: keyPath] }
  }

  public init(_ casePath: AnyCasePath<Root, Value>) {
    self.extractor = { casePath.extract(from: $0) }
  }

  fileprivate func append<Subvalue>(
    _ element: PropertyPath<Value, Subvalue>
  ) -> PropertyPath<Root, Subvalue> {
    return PropertyPath<Root, Subvalue> {
      guard let value = self.extractor($0) else {
        return nil
      }

      return element.extractor(value)
    }
  }

  public static func ~ <Subvalue>(
    lhs: PropertyPath,
    rhs: KeyPath<Value, Subvalue>
  ) -> PropertyPath<Root, Subvalue> {
    return lhs.append(PropertyPath<Value, Subvalue>(rhs))
  }

  public static func ~ <Subvalue>(
    lhs: PropertyPath,
    rhs: @escaping (Subvalue) -> Value
  ) -> PropertyPath<Root, Subvalue> {
    return lhs.append(PropertyPath<Value, Subvalue>(/rhs))
  }

  public static func ~ (
    lhs: PropertyPath,
    rhs: Value
  ) -> PropertyPath<Root, Void> {
    return lhs.append(PropertyPath<Value, Void>(/rhs))
  }

  public func value(in root: Root) -> Value? {
    return self.extractor(root)
  }
}

public extension KeyPath {
  static func ~ <Subvalue>(
    lhs: KeyPath,
    rhs: @escaping (Subvalue) -> Value
  ) -> PropertyPath<Root, Subvalue> {
    return PropertyPath(lhs).append(PropertyPath(/rhs))
  }

  static func ~ (
    lhs: KeyPath,
    rhs: Value
  ) -> PropertyPath<Root, Void> {
    return PropertyPath(lhs).append(PropertyPath<Value, Void>(/rhs))
  }

  func value(in root: Root) -> Value {
    return root[keyPath: self]
  }
}

public extension AnyCasePath {
  static func ~ <Subvalue>(
    lhs: AnyCasePath,
    rhs: KeyPath<Value, Subvalue>
  ) -> PropertyPath<Root, Subvalue> {
    return PropertyPath(lhs).append(PropertyPath(rhs))
  }

  static func ~ <Subvalue>(
    lhs: AnyCasePath,
    rhs: @escaping (Subvalue) -> Value
  ) -> PropertyPath<Root, Subvalue> {
    return PropertyPath(lhs).append(PropertyPath(/rhs))
  }

  static func ~ (
    lhs: AnyCasePath,
    rhs: Value
  ) -> PropertyPath<Root, Void> {
    return PropertyPath(lhs).append(PropertyPath<Value, Void>(/rhs))
  }

  func value(in root: Root) -> Value? {
    return self.extract(from: root)
  }
}
