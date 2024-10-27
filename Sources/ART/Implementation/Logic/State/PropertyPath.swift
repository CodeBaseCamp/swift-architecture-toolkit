// Copyright © Rouven Strauss. MIT license.

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

  public func value(in root: Root) -> Value? {
    return self.extractor(root)
  }
}

public extension KeyPath {
  func value(in root: Root) -> Value {
    return root[keyPath: self]
  }
}
