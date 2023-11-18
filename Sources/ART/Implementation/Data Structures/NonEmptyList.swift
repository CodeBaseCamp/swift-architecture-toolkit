// Copyright © Rouven Strauss. MIT license.

public enum NonEmptyList<T: Equatable>: Equatable {
  case single(T)
  indirect case multiple(head: T, tail: NonEmptyList<T>)
}

extension NonEmptyList: Codable where T: Codable {}

public extension NonEmptyList {
  static func from<ElementCollection: Collection<T>>(_ collection: ElementCollection) -> Self {
    var reversedCollection = collection.reversed()

    let firstElement = requiredLet(reversedCollection.removeFirst(),
                                   "Given collection must not be empty")

    return reversedCollection.reduce(Self.single(firstElement)) {
      return Self.multiple(head: $1, tail: $0)
    }
  }

  var count: UInt {
    UInt(asArray.count)
  }

  var head: T {
    switch self {
    case let .single(head):
      return head
    case let .multiple(head, _):
      return head
    }
  }

  var tail: T {
    switch self {
    case let .single(head):
      return head
    case let .multiple(_, tail):
      return tail.tail
    }
  }

  var asArray: [T] {
    switch self {
    case let .single(head):
      return [head]
    case let .multiple(head, tail):
      return [head] + tail.asArray
    }
  }

  var reversed: Self {
    var list: Self?

    self.applyStartingAtHead { value in
      guard let safeList = list else {
        list = .single(value)
        return
      }

      list = .multiple(head: value, tail: safeList)
    }

    return requiredLet(list, "List must not be nil at this point")
  }

  private func applyStartingAtHead(_ closure: (T) -> Void) {
    switch self {
    case let .single(value):
      closure(value)
    case let .multiple(head: head, tail: tail):
      closure(head)
      tail.applyStartingAtHead(closure)
    }
  }

  func map<V>(_ closure: (T) -> V) -> NonEmptyList<V> {
    var list: NonEmptyList<V>?

    self.applyStartingAtTail { value in
      guard let safeList = list else {
        list = .single(closure(value))
        return
      }

      list = .multiple(head: closure(value), tail: safeList)
    }

    return requiredLet(list, "List must not be nil at this point")
  }

  private func applyStartingAtTail(_ closure: (T) -> Void) {
    switch self {
    case let .single(value):
      closure(value)
    case let .multiple(head: head, tail: tail):
      tail.applyStartingAtTail(closure)
      closure(head)
    }
  }

  func contains(_ element: T) -> Bool {
    self.contains { $0 == element }
  }

  func contains(where closure: (T) -> Bool) -> Bool {
    switch self {
    case let .single(head):
      return closure(head)
    case let .multiple(head: head, tail: tail):
      return closure(head) || tail.contains(where: closure)
    }
  }

  func withAppendedHead(_ head: T) -> Self {
    return .multiple(head: head, tail: self)
  }

  func withAppendedTail(_ tail: Self) -> Self {
    var list: Self?

    self.applyStartingAtTail { value in
      guard let safeList = list else {
        list = .multiple(head: value, tail: tail)
        return
      }

      list = .multiple(head: value, tail: safeList)
    }

    return requiredLet(list, "List must not be nil at this point")
  }
}

extension NonEmptyList: Hashable where T: Hashable {}

extension NonEmptyList: CustomDebugStringConvertible where T: HumanReadable {
  public var debugDescription: String {
    asArray.reduce("") { result, element -> String in
      result + "(\(element.humanReadableDescription)), "
    }
  }
}

extension NonEmptyList: HumanReadable where T: HumanReadable {
  public var humanReadableDescription: String {
    asArray.reduce("") { result, element -> String in
      result + "(\(element.humanReadableDescription)), "
    }
  }
}
