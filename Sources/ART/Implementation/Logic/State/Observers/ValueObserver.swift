// Copyright © Rouven Strauss. MIT license.

/// Object for observing a value being a subvalue of another value.
public class ValueObserver<R: Sendable, T: Equatable & Sendable>: @unchecked Sendable {
  /// Closure invoked with the initially observed value.
  public private(set) var initiallyObservedValue: @Sendable (T?) -> Void

  /// Closure invoked with changes of the observed value.
  public private(set) var change: @Sendable (Change<T?>) -> Void

  /// Indication whether `initiallyObservedValue` has already been invoked.
  private var didCallInitialValueClosure = false

  public init(
    initiallyObservedValue: @escaping @Sendable (T?) -> Void,
    change: @escaping @Sendable (Change<T?>) -> Void
  ) {
    self.initiallyObservedValue = initiallyObservedValue
    self.change = change

    self.initiallyObservedValue = { [weak self] in
      guard let sSelf = self else { return }
      ensure(!sSelf.didCallInitialValueClosure, "Second call to initiallyObservedValue")
      initiallyObservedValue($0)
      sSelf.didCallInitialValueClosure = true
    }

    self.change = { [weak self] in
      guard let sSelf = self else { return }
      ensure(sSelf.didCallInitialValueClosure, "Call to change before initiallyObservedValue")

      change($0)
    }
  }
}

/// Object for observing a value.
public typealias SimpleValueObserver<PropertyType: Equatable> =
  ValueObserver<PropertyType, PropertyType>
