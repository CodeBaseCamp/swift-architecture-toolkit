// Copyright © Rouven Strauss. MIT license.

import Foundation

/// Object maintaining a mutable instance of `State`. The `State` instance can be mutated by
/// invoking the `handleInSingleTransaction` method with appropriate `Request` instances.
actor Store<
  State: StateProtocol,
  Request: RequestProtocol,
  Coeffects: CoeffectsProtocol
>: RequestHandler {
  /// Closure called upon changes of the state.
  private var subscriptionFunction: @Sendable (Change<State>) -> Void = { _ in }

  /// Current state.
  var state: State { self.change.current }

  /// Most recent potential change.
  private var change: PotentialChange<State>

  /// Closure used for manipulating the state.
  private let reduce: (inout State, [Request], Coeffects) -> Void

  /// Initializes with the given `state` and `reduce` closure. The given `reduce` closure is invoked
  /// upon calls to the `handleInSingleTransaction` method.
  init(
    state: State,
    reduce: @escaping (inout State, [Request], Coeffects) -> Void
  ) {
    self.change = PotentialChange(state, state)
    self.reduce = reduce
  }

  func setSubscriptionFunction(_ closure: @escaping @Sendable (Change<State>) -> Void) {
    self.subscriptionFunction = closure
  }

  /// Handles the given `requests` by updating the `state` of this instance accordingly, using the
  /// given `coeffects`.
  func handleInSingleTransaction(_ requests: [Request], using coeffects: Coeffects) async {
    guard !requests.isEmpty else {
      return
    }

    let stateBeforeChange = self.state
    var stateAfterChange = stateBeforeChange

    self.reduce(&stateAfterChange, requests, coeffects)

    let potentialChange = PotentialChange(stateBeforeChange, stateAfterChange)

    guard let change = Change.safeInstance(from: potentialChange) else {
      if requests.mustResultInChange() {
        debugPrint("No state change for request <\(requests.humanReadableDescription)>")
      }
      return
    }

    self.change = potentialChange

    self.subscriptionFunction(change)
  }
}

// MARK: - Store Extensions

extension Store {
  func save(in userDefaults: SendableUserDefaults, forKey key: String) throws {
    try userDefaults.set(self.state.data(), forKey: key)
  }

  func load(from userDefaults: SendableUserDefaults, forKey key: String) throws {
    guard let data: Data = userDefaults.object(forKey: key) else {
      return
    }

    let loadedState = try State.instance(from: data)
    let potentialChange = PotentialChange(self.state, loadedState)

    guard let change = Change.safeInstance(from: potentialChange) else {
      return
    }

    self.change = potentialChange

    self.subscriptionFunction(change)
  }
}
