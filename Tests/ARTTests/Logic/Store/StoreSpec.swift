// Copyright © Rouven Strauss. MIT license.

@testable import ART

import Foundation
import Nimble
import Quick

// MARK: - States

struct FakeStateA: Equatable {
  var stringValue: ValueWithDefault<String>

  static func instance() -> Self {
    Self(stringValue: ValueWithDefault("foo"))
  }
}

extension FakeStateA: StateProtocol {
  static func instance(from data: Data) throws -> FakeStateA {
    return try PropertyListDecoder().decode(FakeStateA.self, from: data)
  }

  func data() throws -> Data {
    return try PropertyListEncoder().encode(self)
  }

  enum Key: CodingKey {
    case stringValue
    case defaultStringValue
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: Key.self)
    let stringValue = try container.decode(String.self, forKey: Key.stringValue)
    let defaultStringValue = try container.decode(String.self, forKey: Key.defaultStringValue)
    self.stringValue = ValueWithDefault(defaultStringValue).copy(with: stringValue)
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: Key.self)
    try container.encode(self.stringValue.value, forKey: Key.stringValue)
    try container.encode(self.stringValue.defaultValue, forKey: Key.defaultStringValue)
  }
}

struct FakeStateB: Codable, Equatable {
  var integerValue: Int

  static func instance() -> Self {
    Self(integerValue: 7)
  }
}

struct FakeError: Codable, Equatable, Error {
  var string: String
}

struct FakeState: Equatable {
  var stateA: FakeStateA
  var stateB: FakeStateB
  var temporaryState: Int = 0

  static func instance() -> Self {
    Self(stateA: FakeStateA.instance(), stateB: FakeStateB.instance())
  }
}

extension FakeState: StateProtocol {
  static func instance(from data: Data) throws -> FakeState {
    return try PropertyListDecoder().decode(FakeState.self, from: data)
  }

  func data() throws -> Data {
    return try PropertyListEncoder().encode(self)
  }

  enum Key: CodingKey {
    case stateA
    case stateB
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: Key.self)
    self.stateA = try container.decode(FakeStateA.self, forKey: Key.stateA)
    self.stateB = try container.decode(FakeStateB.self, forKey: Key.stateB)
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: Key.self)
    try container.encode(self.stateA, forKey: Key.stateA)
    try container.encode(self.stateB, forKey: Key.stateB)
  }
}

// MARK: - Requests

enum FakeRequestA: RequestProtocol {
  case updateOfValue

  var humanReadableDescription: String {
    switch self {
    case .updateOfValue:
      return "Update of value"
    }
  }
}

enum FakeRequestB: RequestProtocol {
  case updateOfValue

  var humanReadableDescription: String {
    switch self {
    case .updateOfValue:
      return "Update of value"
    }
  }
}

enum FakeRequest: RequestProtocol {
  case a(FakeRequestA)
  case b(FakeRequestB)

  static let requestA: (FakeRequest) -> FakeRequestA? = { request in
    guard case let .a(subrequest) = request else { return nil }
    return subrequest
  }

  static let requestB: (FakeRequest) -> FakeRequestB? = { request in
    guard case let .b(subrequest) = request else { return nil }
    return subrequest
  }

  var humanReadableDescription: String {
    switch self {
    case let .a(request):
      return "a(\(request))"
    case let .b(request):
      return "b(\(request))"
    }
  }
}

// MARK: - Subscribers

class FakeSubscriberA {
  var receivedChange: Change<FakeStateA>?
}

class FakeSubscriber {
  var receivedChange: Change<FakeState>?
}

// MARK: - UserDefaults

class FakeUserDefaults: UserDefaults {
  var savedObject: Any?

  override func set(_ object: Any?, forKey _: String) {
    self.savedObject = object
  }

  override func object(forKey _: String) -> Any? {
    return self.savedObject
  }
}

final class StoreSpec: QuickSpec {
  override class func spec() {
    var initialStateA: FakeStateA!
    var coeffects: TestCoeffects!
    var reducerA: Reducer<FakeStateA, FakeRequestA, TestCoeffects>!
    var subscriberA: FakeSubscriberA!
    var subscriptionFunctionA: ((Change<FakeStateA>) -> Void)!
    var storeA: Store<FakeStateA, FakeRequestA, TestCoeffects>!

    beforeEach {
      initialStateA = .instance()
      coeffects = TestCoeffects()
      reducerA = Reducer<FakeStateA, FakeRequestA, TestCoeffects> { state, requests, _ in
        requests.forEach { request in
          switch request {
          case .updateOfValue:
            state.stringValue = state.stringValue.copy(with: "bar")
          }
        }
      }
      subscriberA = FakeSubscriberA()
      subscriptionFunctionA = { change in
        subscriberA.receivedChange = change
      }
      storeA = Store(state: initialStateA, reduce: reducerA.reduce)
    }

    context("simple store") {
      context("initialization") {
        it("initializes") {
          expect(storeA.state) == initialStateA
        }
      }

      context("reduction of state") {
        it("updates state according to request") {
          storeA.handle(.updateOfValue, using: coeffects)

          expect(storeA.state) == FakeStateA(stringValue: ValueWithDefault("foo").copy(with: "bar"))
        }
      }

      context("execution of subscription function") {
        beforeEach {
          storeA.subscriptionFunction = subscriptionFunctionA
        }

        it("executes subscription function") {
          storeA.handle(.updateOfValue, using: coeffects)

          let expectedChange = Change(
            initialStateA!,
            FakeStateA(stringValue: ValueWithDefault("foo").copy(with: "bar"))
          )
          expect(subscriberA.receivedChange) == expectedChange
        }
      }

      context("user defaults") {
        var userDefaults: FakeUserDefaults!
        var key: String!

        beforeEach {
          userDefaults = FakeUserDefaults()
          key = "key"
        }

        it("saves in given user defaults for given key") {
          try! storeA.save(in: userDefaults, forKey: key)
          expect(userDefaults.savedObject).toNot(beNil())
        }

        context("loading from given user defaults for given key") {
          beforeEach {
            try! storeA.save(in: userDefaults, forKey: key)
            storeA.handle(.updateOfValue, using: coeffects)

            storeA.subscriptionFunction = subscriptionFunctionA

            try! storeA.load(from: userDefaults, forKey: key)
          }

          it("updates the state of the store") {
            expect(storeA.state) == initialStateA
          }

          it("executes subscription function") {
            let expectedChange = Change(
              FakeStateA(stringValue: ValueWithDefault("foo").copy(with: "bar")),
              initialStateA!
            )
            expect(subscriberA.receivedChange) == expectedChange
          }
        }
      }
    }

    context("store with composed state") {
      var initialState: FakeState!
      var reducer: Reducer<FakeState, FakeRequest, TestCoeffects>!
      var subscriber: FakeSubscriber!
      var subscriptionFunction: ((Change<FakeState>) -> Void)!
      var store: Store<FakeState, FakeRequest, TestCoeffects>!

      beforeEach {
        initialState = FakeState(stateA: .instance(), stateB: FakeStateB(integerValue: 0))
        let reducerB = Reducer<FakeStateB, FakeRequestB, TestCoeffects> { state, requests, _ in
          requests.forEach { request in
            switch request {
            case .updateOfValue:
              state.integerValue = 2
            }
          }
        }
        reducer = reducerA.reducerForSuperState(
          stateKeyPath: \FakeState.stateA,
          requestFromSuperRequest: FakeRequest.requestA
        )
        .combined(
          with: reducerB.reducerForSuperState(
            stateKeyPath: \FakeState.stateB,
            requestFromSuperRequest: FakeRequest.requestB
          )
        )
        subscriber = FakeSubscriber()
        subscriptionFunction = { change in
          subscriber.receivedChange = change
        }
        store = Store(state: initialState, reduce: reducer.reduce)
      }

      context("initialization") {
        it("initializes") {
          expect(store.state) == initialState
        }
      }

      context("reduction of state") {
        it("updates state according to request for substate A") {
          store.handle(.a(.updateOfValue), using: coeffects)
          let expectedState = copied(initialState) {
            $0.stateA.stringValue = $0.stateA.stringValue.copy(with: "bar")
          }
          expect(store.state) == expectedState
        }

        it("computes state change according to request for substate B") {
          store.handle(.b(.updateOfValue), using: coeffects)
          expect(store.state) == copied(initialState) { $0.stateB.integerValue = 2 }
        }

        it("computes state change according to requests") {
          store.handleInSingleTransaction([.a(.updateOfValue), .b(.updateOfValue)],
                                          using: coeffects)
          let expectedPreviousState: FakeState = copied(initialState) {
            $0.stateA.stringValue = $0.stateA.stringValue.copy(with: "bar")
          }
          let expectedCurrentState: FakeState = copied(expectedPreviousState) {
            $0.stateB.integerValue = 2
          }
          expect(store.state) == expectedCurrentState
        }
      }

      context("execution of subscription function") {
        beforeEach {
          store.subscriptionFunction = subscriptionFunction
        }

        it("executes subscription function when handling request for substate A") {
          store.handle(.a(.updateOfValue), using: coeffects)

          let expectedChange = Change(initialState!, store.state)
          expect(subscriber.receivedChange) == expectedChange
        }

        it("executes subscription function when handling request for substate B") {
          store.handle(.b(.updateOfValue), using: coeffects)

          let expectedChange = Change(
            initialState!,
            store.state
          )
          expect(subscriber.receivedChange) == expectedChange
        }
      }

      context("user defaults") {
        var userDefaults: FakeUserDefaults!
        var key: String!

        beforeEach {
          userDefaults = FakeUserDefaults()
          key = "key"
        }

        it("saves in given user defaults for given key") {
          try! store.save(in: userDefaults, forKey: key)
          expect(userDefaults.savedObject).toNot(beNil())
        }

        context("loading from given user defaults for given key") {
          var previousState: FakeState!
          var currentState: FakeState!

          beforeEach {
            previousState = copied(initialState!) {
              $0.stateA.stringValue = $0.stateA.stringValue.copy(with: "bar")
            }
            currentState = initialState!

            try! store.save(in: userDefaults, forKey: key)
            store.handle(.a(.updateOfValue), using: coeffects)

            store.subscriptionFunction = subscriptionFunction

            try! store.load(from: userDefaults, forKey: key)
          }

          it("updates the state of the store") {
            expect(store.state) == currentState
          }

          it("executes subscription function") {
            let expectedChange = Change(previousState!, currentState!)
            expect(subscriber.receivedChange) == expectedChange
          }
        }
      }
    }
  }
}
