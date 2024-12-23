// Copyright © Rouven Strauss. MIT license.

import Foundation

/// Object for observing the value of a `State` of a `ModelProtocol` instance, following a
/// specific property path.
public final class ModelObserver<R: Equatable & Sendable>: Sendable {
  fileprivate let propertyPath: PartialPropertyPath<R>
  fileprivate let handleInitiallyObservedState: @Sendable (R) -> Void
  fileprivate let handleStateChange: @Sendable (Change<R>) -> Void

  public convenience init<T: Equatable>(
    for keyPath: KeyPath<R, T>,
    initiallyObservedValue: @escaping @Sendable (T) -> Void,
    change changeClosure: @escaping @Sendable (Change<T>) -> Void
  ) {
    self.init(
      for: PropertyPath(keyPath),
      initiallyObservedValue: {
        guard let value = $0 else {
          fatalError("Optional value received for key path must never be `nil`")
        }

        initiallyObservedValue(value)
      }, change: { change in
        guard let previousValue = change.previous else {
          fatalError("Previous value received for key path must never be `nil`")
        }
        guard let currentValue = change.current else {
          fatalError("Current value received for key path must never be `nil`")
        }

        changeClosure(Change(previousValue, currentValue))
      }
    )
  }

  public convenience init(
    for propertyPath: PropertyPath<R, Void>,
    initiallyObservedValue: @escaping @Sendable (Bool) -> Void,
    change changeClosure: @escaping @Sendable (Change<Bool>) -> Void
  ) {
    self.init(
      for: propertyPath,
      initiallyObservedValue: initiallyObservedValue,
      change: changeClosure
    ) {
      return $0 != nil ? true : false
    }
  }

  public convenience init<T: Equatable>(
    for propertyPath: PropertyPath<R, T>,
    initiallyObservedValue: @escaping @Sendable (T?) -> Void,
    change changeClosure: @escaping @Sendable (Change<T?>) -> Void
  ) {
    self.init(
      for: propertyPath,
      initiallyObservedValue: initiallyObservedValue,
      change: changeClosure
    ) {
      return $0
    }
  }

  private init<T: Equatable, S>(
    for propertyPath: PropertyPath<R, S>,
    initiallyObservedValue: @escaping @Sendable (T) -> Void,
    change changeClosure: @escaping @Sendable (Change<T>) -> Void,
    t: @escaping @Sendable (S?) -> T
  ) {
    self.propertyPath = propertyPath
    self.handleInitiallyObservedState = {
      let value = propertyPath.value(in: $0)
      initiallyObservedValue(t(value))
    }

    self.handleStateChange = { change in
      let previousValue = t(propertyPath.value(in: change.previous))
      let currentValue = t(propertyPath.value(in: change.current))

      guard previousValue != currentValue else {
        return
      }

      changeClosure(Change(previousValue, currentValue))
    }
  }
}

/// Object maintaining mutable, observable state. The state can be mutated using so-called requests.
/// `ModelObserver` instances can be be added to the model in order to observe changes at
/// specific key paths.
public actor Model<
  State: StateProtocol,
  Request: RequestProtocol,
  Coeffects: CoeffectsProtocol
>: ModelProtocol, RequestHandler {
  /// Currently added observers.
  private var observers = [WeakContainer<ModelObserver<State>>]()

  /// Internally used store.
  private let store: Store<State, Request, Coeffects>

  /// Returns the current state.
  public func state() async -> State {
    return await self.store.state
  }

  public init(
    state: State,
    reduce: @escaping @Sendable (inout State, [Request], Coeffects) -> Void
  ) {
    self.store = Store(state: state, reduce: reduce)
  }

  public func handleInSingleTransaction(_ requests: [Request], using coeffects: Coeffects) async {
    await store.handleInSingleTransaction(requests, using: coeffects)
  }

  /// See homonymous method of `ModelProtocol`.
  public func add(_ observer: ModelObserver<State>) async {
    self.observers.append(WeakContainer(containing: observer))

    await self.updateSubscriptionFunction()

    observer.handleInitiallyObservedState(await self.store.state)
  }

  private func updateSubscriptionFunction() async {
    let remainingObservers = self.remainingObservers

    await self.store.setSubscriptionFunction { change in
      remainingObservers.forEach {
        $0.weaklyHeldInstance?.handleStateChange(change)
      }
    }
  }

  private var remainingObservers: [WeakContainer<ModelObserver<State>>] {
    var remainingObservers = [WeakContainer<ModelObserver<State>>]()
    var containersToRemove = [WeakContainer<ModelObserver<State>>]()

    self.observers.forEach { container in
      guard container.weaklyHeldInstance != nil else {
        containersToRemove.append(container)
        return
      }

      remainingObservers.append(container)
    }

    containersToRemove.forEach { containerToRemove in
      self.observers.removeAll(where: { $0 === containerToRemove })
    }

    return remainingObservers
  }
}

public extension Model {
  func save(in userDefaults: SendableUserDefaults, forKey key: String) async throws {
    try await store.save(in: userDefaults, forKey: key)
  }

  func load(from userDefaults: SendableUserDefaults, forKey key: String) async throws {
    try await store.load(from: userDefaults, forKey: key)
  }
}

/// Object serving as a functional lens on some state by converting the state to some different
/// state. `ModelObserver` instances can be be added to the object in order to observe changes at
/// specific key paths.
public final class LensModel<
  State: Equatable & Sendable, ObservedModel: ModelProtocol, ObservedProperty: Equatable & Sendable
>: @unchecked Sendable {
  /// Closure returning an optional change of `State`, given a current `State` and a change of the
  /// `ObservedProperty`. Returns `nil` if there is no change for the given parameters.
  public typealias ChangeConversionClosure =
    (State, Change<ObservedProperty?>) -> Change<State>?

  /// Path of the property which is observed by this instance.
  public let propertyPath: PropertyPath<ObservedModel.State, ObservedProperty>

  /// Internally used observed model.
  private weak var model: ObservedModel?

  /// Internally used value conversion closure.
  private var valueConversion: (ObservedProperty?) -> State

  /// Internally used change conversion closure.
  private var changeConversion: ChangeConversionClosure

  /// Internally held state.
  private var state: State!

  /// Collection of weakly held observers.
  private var observers = [UUID: PropertyPathObserver<ObservedModel.State, ObservedProperty>]()

  /// Returns a new instance observing the property at the given `propertyPath` of the given
  /// `model`, converting values with the given `valueConversion` closure and changes with the given
  /// `changeConversion` closure.
  ///
  /// - important The given `model` is not held strongly by the returned instance.
  public static func instance(
    observing propertyPath: PropertyPath<ObservedModel.State, ObservedProperty>,
    of model: ObservedModel,
    convertingValueUsing valueConversion: @escaping (ObservedProperty?) -> State,
    andChangeUsing changeConversion: @escaping ChangeConversionClosure
  ) -> Self {
    Self(
      model: model,
      propertyPath: propertyPath,
      valueConversion: valueConversion,
      changeConversion: changeConversion
    )
  }

  required init(
    model: ObservedModel,
    propertyPath: PropertyPath<ObservedModel.State, ObservedProperty>,
    valueConversion: @escaping (ObservedProperty?) -> State,
    changeConversion: @escaping ChangeConversionClosure
  ) {
    self.model = model
    self.propertyPath = propertyPath
    self.valueConversion = valueConversion
    self.changeConversion = changeConversion
  }

  /// Returns an observer which is added to this instance. The returned observer observes changes of
  /// this instance. The given `initiallyObservedValue` closure is invoked synchronously as part of
  /// the execution of this method. The given `change` closure is invoked whenever a change of the
  /// observed property occurs.
  ///
  /// - important The model provided upon creation of this instance must still exist upon calls to
  ///             this method.
  /// - important The returned observer is held weakly by this instance. It is the responsibility of
  ///             the caller to hold the returned observer strongly as long as required.
  public func observer(
    initiallyObservedValue: @escaping @Sendable (State) -> Void,
    change changeClosure: @escaping @Sendable (Change<State>) -> Void
  ) async -> SimpleValueObserver<State> {
    let observer = SimpleValueObserver<State>(
      initiallyObservedValue: {
        guard let value = $0 else {
          fatalError("Invoked with nil value")
        }

        initiallyObservedValue(value)
      },
      change: { change in
        guard let previousValue = change.previous else {
          fatalError("Invoked with nil previous value in \(change)")
        }
        guard let currentValue = change.current else {
          fatalError("Invoked with nil current value in \(change)")
        }

        changeClosure(Change(previousValue, currentValue))
      }
    )

    await self.add(observer)

    return observer
  }

  /// Adds the given `observer`.
  ///
  /// - important The model provided upon creation of this instance must still exist when the
  ///             callback methods of the given `observer` are called.
  public func add(_ observer: SimpleValueObserver<State>) async {
    guard let model = self.model else {
      fatalError("Added observer after model deallocation")
    }

    let observerContainer = WeakContainer(containing: observer)

    let propertyPathObserverID = UUID()

    let propertyPathObserver: PropertyPathObserver = .observer(
      for: self.propertyPath,
      initiallyObservedValue: { [weak self] value in
        guard let self = self else {
          fatalError("Received value after deallocation")
        }

        guard let observer = observerContainer.weaklyHeldInstance else {
          self.observers[propertyPathObserverID] = nil
          return
        }

        let convertedValue = self.valueConversion(value)
        self.state = convertedValue
        observer.initiallyObservedValue(convertedValue)
      },
      change: { [weak self] observedChange in
        guard let self = self else {
          fatalError("Received change after deallocation")
        }

        guard let observer = observerContainer.weaklyHeldInstance else {
          self.observers[propertyPathObserverID] = nil
          return
        }

        guard let change = self.changeConversion(self.state, observedChange) else {
          return
        }

        self.state = change.current
        observer.change(Change(change.previous, change.current))
      }
    )

    let modelObserver = propertyPathObserver.modelObserver
    self.observers[propertyPathObserverID] = propertyPathObserver
    await model.add(modelObserver)
  }
}
