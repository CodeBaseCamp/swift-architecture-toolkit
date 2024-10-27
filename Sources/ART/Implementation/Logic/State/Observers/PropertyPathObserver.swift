// Copyright © Rouven Strauss. MIT license.

/// Object for observing a value at a specific property path.
public class PropertyPathObserver<R: Equatable, T: Equatable>: ValueObserver<R, T> {
  private let modelObserverClosure: () -> ModelObserver<R>

  /// Object which can be used to observe values of type `R`.
  public lazy var modelObserver: ModelObserver<R> = {
    let changeClosure: (Change<T?>) -> Void = { [weak self] change in
      guard let sSelf = self else {
        fatalError("Observer deallocated before final change call")
      }

      sSelf.change(Change(change.previous, change.current))
    }

    return self.modelObserverClosure()
  }()

  /// Tuple containing the `ModelObserver` of this instance and this instance, cast to `Any`.
  public var tuple: (ModelObserver<R>, Any) {
    return (self.modelObserver, self)
  }

  private convenience init(
    for keyPath: KeyPath<R, T>,
    initiallyObservedValue: @escaping (T) -> Void,
    change changeClosure: @escaping (Change<T>) -> Void
  ) {
    self.init(
      for: PropertyPath(keyPath),
      initiallyObservedValue: { optionalValue in
        guard let value = optionalValue else {
          fatalError("Value observed at key path must not be `nil`")
        }

        initiallyObservedValue(value)
      }, change: { change in
        guard let previousValue = change.previous else {
          fatalError("Previous value received for \(change) must not be `nil`")
        }
        guard let currentValue = change.current else {
          fatalError("Current value received for \(change) must not be `nil`")
        }

        changeClosure(Change(previousValue, currentValue))
      }
    )
  }

  private init(
    for propertyPath: PropertyPath<R, Void>,
    initiallyObservedValue: @escaping (Bool) -> Void,
    change changeClosure: @escaping (Change<Bool>) -> Void
  ) where T == Bool {
    self.modelObserverClosure = {
      ModelObserver(
        for: propertyPath,
        initiallyObservedValue: initiallyObservedValue,
        change: changeClosure
      )
    }
    super.init(
      initiallyObservedValue: { optionalValue in
        guard let value = optionalValue else {
          fatalError("Value observed at property path \(propertyPath) must not be `nil`")
        }

        initiallyObservedValue(value)
      },
      change: { change in
        guard let previousValue = change.previous else {
          fatalError("Previous value received for \(change) must not be `nil`")
        }
        guard let currentValue = change.current else {
          fatalError("Current value received for \(change) must not be `nil`")
        }

        changeClosure(Change(previousValue, currentValue))
      }
    )
  }

  private init(
    for propertyPath: PropertyPath<R, T>,
    initiallyObservedValue: @escaping (T?) -> Void,
    change: @escaping (Change<T?>) -> Void
  ) {
    self.modelObserverClosure = Self.newModelObserverClosure(
      propertyPath,
      initiallyObservedValue,
      change
    )
    super.init(initiallyObservedValue: initiallyObservedValue, change: change)
  }

  private static func newModelObserverClosure(
    _ propertyPath: PropertyPath<R, T>,
    _ initiallyObservedValue: @escaping (T?) -> Void,
    _ change: @escaping (Change<T?>) -> Void
  ) -> (() -> ModelObserver<R>) {
    return {
      ModelObserver(
        for: propertyPath,
        initiallyObservedValue: initiallyObservedValue,
        change: change
      )
    }
  }
}

public extension PropertyPathObserver {
  static func observer(
    for path: KeyPath<R, T>,
    initiallyObservedValue: @escaping (T) -> Void,
    change: @escaping (Change<T>) -> Void
  ) -> PropertyPathObserver<R, T> {
    PropertyPathObserver(for: path, initiallyObservedValue: initiallyObservedValue, change: change)
  }

  static func observer(
    for path: PropertyPath<R, Void>,
    initiallyObservedValue: @escaping (Bool) -> Void,
    change: @escaping (Change<Bool>) -> Void
  ) -> PropertyPathObserver<R, Bool> where T == Bool {
    PropertyPathObserver(for: path, initiallyObservedValue: initiallyObservedValue, change: change)
  }

  static func observer(
    for path: PropertyPath<R, T>,
    initiallyObservedValue: @escaping (T?) -> Void,
    change: @escaping (Change<T?>) -> Void
  ) -> PropertyPathObserver<R, T> {
    PropertyPathObserver(for: path, initiallyObservedValue: initiallyObservedValue, change: change)
  }
}

public extension PropertyPathObserver {
  static func observer(
    for path: KeyPath<R, T>,
    alwaysExecuting closure: @escaping (T) -> Void
  ) -> PropertyPathObserver<R, T> {
    return .observer(for: path, initiallyObservedValue: closure, change: { closure($0.current) })
  }

  static func observer(
    for path: PropertyPath<R, Void>,
    alwaysExecuting closure: @escaping (Bool) -> Void
  ) -> PropertyPathObserver<R, Bool> where T == Bool {
    return .observer(for: path, initiallyObservedValue: closure, change: { closure($0.current) })
  }

  static func observer(
    for path: PropertyPath<R, T>,
    alwaysExecuting closure: @escaping (T?) -> Void
  ) -> PropertyPathObserver<R, T> {
    return .observer(for: path, initiallyObservedValue: closure, change: { closure($0.current) })
  }
}

/// Protocol implemented by objects providing an `PropertyPathObserver` via which the object can be
/// informed about changes of a value at a specific key path.
public protocol PropertyPathObserverProvider {
  associatedtype R: Equatable
  associatedtype T: Equatable

  /// Object via which the receiver can be informed about changes of a value at a specific key path.
  var propertyPathObserver: PropertyPathObserver<R, T> { get }
}
