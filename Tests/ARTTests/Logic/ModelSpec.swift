// Copyright © Rouven Strauss. MIT license.

import ART

import Foundation
import Nimble
import Quick

struct TestState: Equatable {
  var value: Int
  var anotherValue: String
}

extension TestState: StateProtocol {
  static func instance(from _: Data) throws -> Self {
    fatalErrorDueToMissingImplementation()
  }

  func data() throws -> Data {
    fatalErrorDueToMissingImplementation()
  }
}

final class ModelSpec: AsyncSpec {
  override class func spec() {
    context("observers") {
      context("key path observer") {
        var initialState: FakeState!
        var coeffects: TestCoeffects!
        var reducer: Reducer<FakeState, FakeRequest, TestCoeffects>!
        var model: Model<FakeState, FakeRequest, TestCoeffects>!

        beforeEach {
          initialState = FakeState.instance()
          coeffects = TestCoeffects()
          reducer = Reducer<FakeState, FakeRequest, TestCoeffects> { state, requests, _ in
            requests.forEach { request in
              switch request {
              case .a:
                state.stateA.stringValue = state.stateA.stringValue.copy(with: "bar")
              case .b:
                state.stateB.integerValue = 8
              }
            }
          }
          model = Model(state: initialState, reduce: reducer.reduce)
        }

        it("adds observer") {
          let observer = ModelObserver(for: \FakeState.stateA,
                                       initiallyObservedValue: { _ in },
                                       change: { _ in })
          await model.add(observer)
        }

        it("holds observer weakly") {
          weak var weaklyHeldObserver: ModelObserver<FakeState>?

          var observer: ModelObserver? = ModelObserver(
            for: \FakeState.stateA,
            initiallyObservedValue: { _ in },
            change: { _ in }
          )
          weaklyHeldObserver = observer

          await model.add(observer!)

          expect(weaklyHeldObserver).toNot(beNil())

          observer = nil

          expect(weaklyHeldObserver).to(beNil())
        }

        context("execution") {
          context("root key path") {
            context("initially observed value") {
              it("executes observer callback upon adding of observer") {
                let (receiver, observer) = receiverAndObserver(\FakeState.self, FakeState.self)


                await model.add(observer)

                try? await Task.sleep(for: .seconds(0.01))

                let receivedValue = await receiver.value

                expect(receivedValue).toNot(beNil())
                expect(receivedValue) == initialState
              }

              it("does not execute observer callback upon state change") {
                let (receiver, observer) = receiverAndObserver(\FakeState.self, FakeState.self)

                await model.add(observer)

                try? await Task.sleep(for: .seconds(0.01))

                await receiver.setValue(nil)

                await model.handle(.a(.updateOfValue), using: coeffects)

                let receivedValue = await receiver.value

                expect(receivedValue).to(beNil())
              }
            }

            context("change") {
              it("does not execute observer callback upon adding of observer") {
                let (receiver, observer) = receiverAndObserver(\FakeState.self, FakeState.self)

                await model.add(observer)

                try? await Task.sleep(for: .seconds(0.01))

                let receivedChange = await receiver.change

                expect(receivedChange).to(beNil())
              }

              it("executes observer callback upon state change") {
                let (receiver, observer) = receiverAndObserver(\FakeState.self, FakeState.self)

                await model.add(observer)

                try? await Task.sleep(for: .seconds(0.01))

                await model.handle(.a(.updateOfValue), using: coeffects)

                let expectedChange = Change(
                  initialState!,
                  copied(initialState!) {
                    $0.stateA.stringValue = $0.stateA.stringValue.copy(with: "bar")
                  }
                )

                try? await Task.sleep(for: .seconds(0.01))

                let receivedChange = await receiver.change

                expect(receivedChange).toNot(beNil())
                expect(receivedChange) == expectedChange
              }
            }
          }

          context("inner key path") {
            context("initially observed value") {
              it("executes observer callback upon adding of observer") {
                let (receiver, observer) = receiverAndObserver(\FakeState.stateA, FakeStateA.self)

                await model.add(observer)

                try? await Task.sleep(for: .seconds(0.01))

                let receivedValue = await receiver.value

                expect(receivedValue).toNot(beNil())
                expect(receivedValue) == initialState.stateA
              }

              it("does not execute observer callback upon state change") {
                let (receiver, observer) = receiverAndObserver(\FakeState.stateA, FakeStateA.self)

                await model.add(observer)

                try? await Task.sleep(for: .seconds(0.01))

                await receiver.setValue(nil)

                await model.handle(.a(.updateOfValue), using: coeffects)

                try? await Task.sleep(for: .seconds(0.01))

                let receivedValue = await receiver.value

                expect(receivedValue).to(beNil())
              }
            }

            context("change") {
              it("does not execute observer callback upon adding of observer") {
                let (receiver, observer) = receiverAndObserver(\FakeState.stateA, FakeStateA.self)

                await model.add(observer)

                try? await Task.sleep(for: .seconds(0.01))

                let receivedChange = await receiver.change

                expect(receivedChange).to(beNil())
              }

              it("executes observer callback upon state change") {
                let (receiver, observer) = receiverAndObserver(\FakeState.stateA, FakeStateA.self)

                await model.add(observer)

                try? await Task.sleep(for: .seconds(0.01))

                await model.handle(.a(.updateOfValue), using: coeffects)

                try? await Task.sleep(for: .seconds(0.01))

                let expectedChange = Change(
                  initialState.stateA,
                  copied(initialState.stateA) {
                    $0.stringValue = $0.stringValue.copy(with: "bar")
                  }
                )

                let receivedChange = await receiver.change

                expect(receivedChange).toNot(beNil())
                expect(receivedChange) == expectedChange
              }
            }
          }
        }
      }

      context("property path observer") {
        var initialState: TestState!
        var coeffects: TestCoeffects!
        var reducer: Reducer<TestState, FakeRequest, TestCoeffects>!
        var model: Model<TestState, FakeRequest, TestCoeffects>!

        beforeEach {
          initialState = .init(value: 0, anotherValue: "")
          coeffects = TestCoeffects()
          reducer = Reducer<TestState, FakeRequest, TestCoeffects> { state, requests, _ in
            requests.forEach { request in
              switch request {
              case .a:
                state.value = 7
              case .b:
                state.anotherValue = "foo"
              }
            }
          }
          model = Model(state: initialState, reduce: reducer.reduce)
        }

        it("adds observer") {
          let observer = ModelObserver(for: \TestState.value,
                                       initiallyObservedValue: { _ in },
                                       change: { _ in })
          await model.add(observer)
        }

        it("holds observer weakly") {
          weak var weakObserver: ModelObserver<TestState>?

          var observer: ModelObserver? = ModelObserver(
            for: \TestState.value,
            initiallyObservedValue: { _ in },
            change: { _ in }
          )
          weakObserver = observer
          await model.add(observer!)

          expect(weakObserver).toNot(beNil())

          observer = nil

          expect(weakObserver).to(beNil())
        }

        context("execution") {
          context("root property path") {
            context("initially observed value") {
              it("executes observer callback upon adding of observer") {
                let (receiver, observer) = receiverAndObserver(\TestState.self, TestState.self)

                await model.add(observer)

                try? await Task.sleep(for: .seconds(0.01))

                let receivedValue = await receiver.value

                expect(receivedValue).toNot(beNil())
                expect(receivedValue) == initialState
              }

              it("does not execute observer callback upon state change") {
                let (receiver, observer) = receiverAndObserver(\TestState.self, TestState.self)

                await model.add(observer)

                try? await Task.sleep(for: .seconds(0.01))

                await receiver.setValue(nil)

                await model.handle(.a(.updateOfValue), using: coeffects)

                try? await Task.sleep(for: .seconds(0.01))

                let receivedValue = await receiver.value

                expect(receivedValue).to(beNil())
              }
            }

            context("change") {
              it("does not execute observer callback upon adding of observer") {
                let (receiver, observer) = receiverAndObserver(\TestState.self, TestState.self)

                await model.add(observer)

                let receivedChange = await receiver.change

                expect(receivedChange).to(beNil())
              }

              it("executes observer callback upon state change") {
                let (receiver, observer) = receiverAndObserver(\TestState.self, TestState.self)

                await model.add(observer)

                try? await Task.sleep(for: .seconds(0.01))

                await model.handle(.a(.updateOfValue), using: coeffects)

                try? await Task.sleep(for: .seconds(0.01))

                let receivedChange = await receiver.change

                let expectedChange = Change<TestState>(
                  initialState!,
                  copied(initialState!) {
                    $0.value = 7
                  }
                )
                expect(receivedChange).toNot(beNil())
                expect(receivedChange) == expectedChange
              }
            }
          }

          context("inner property path, non-null change") {
            context("initially observed value") {
              it("executes observer callback upon adding of observer") {
                let (receiver, observer) = receiverAndObserver(\TestState.value, Int.self)

                await model.add(observer)

                try? await Task.sleep(for: .seconds(0.01))

                let receivedValue = await receiver.value

                expect(receivedValue).toNot(beNil())
                expect(receivedValue) == 0
              }

              it("does not execute observer callback upon state change") {
                let (receiver, observer) = receiverAndObserver(\TestState.value, Int.self)

                await model.add(observer)

                try? await Task.sleep(for: .seconds(0.01))

                await receiver.setValue(nil)

                await model.handle(.a(.updateOfValue), using: coeffects)

                try? await Task.sleep(for: .seconds(0.01))

                let receivedValue = await receiver.value

                expect(receivedValue).to(beNil())
              }
            }

            context("change") {
              it("does not execute observer callback upon adding of observer") {
                let (receiver, observer) = receiverAndObserver(\TestState.value, Int.self)

                await model.add(observer)

                try? await Task.sleep(for: .seconds(0.01))

                let receivedChange = await receiver.change

                expect(receivedChange).to(beNil())
              }

              it("executes observer callback upon state change") {
                let (receiver, observer) = receiverAndObserver(\TestState.value, Int.self)

                await model.add(observer)

                try? await Task.sleep(for: .seconds(0.01))

                await model.handle(.a(.updateOfValue), using: coeffects)

                try? await Task.sleep(for: .seconds(0.01))

                let receivedChange = await receiver.change

                let expectedChange = Change<Int>(
                  0,
                  7
                )
                expect(receivedChange).toNot(beNil())
                expect(receivedChange) == expectedChange
              }
            }
          }

          context("inner property path, null change") {
            context("initially observed value") {
              it("executes observer callback upon adding of observer") {
                let (receiver, observer) = receiverAndObserver(\TestState.anotherValue, String.self)

                await model.add(observer)

                try? await Task.sleep(for: .seconds(0.01))

                let receivedValue = await receiver.value

                expect(receivedValue) == ""
              }

              it("does not execute observer callback upon state change") {
                let (receiver, observer) = receiverAndObserver(\TestState.anotherValue, String.self)

                await model.add(observer)

                try? await Task.sleep(for: .seconds(0.01))

                await model.handle(.a(.updateOfValue), using: coeffects)

                try? await Task.sleep(for: .seconds(0.01))

                let receivedValue = await receiver.value

                expect(receivedValue) == ""
              }
            }

            context("change") {
              it("does not execute observer callback upon adding of observer") {
                let (receiver, observer) = receiverAndObserver(\TestState.anotherValue, String.self)

                await model.add(observer)

                try? await Task.sleep(for: .seconds(0.01))

                let receivedChange = await receiver.change

                expect(receivedChange).to(beNil())
              }

              it("executes observer callback upon state change") {
                let (receiver, observer) = receiverAndObserver(\TestState.anotherValue, String.self)

                await model.add(observer)

                try? await Task.sleep(for: .seconds(0.01))

                await model.handle(.b(.updateOfValue), using: coeffects)

                try? await Task.sleep(for: .seconds(0.01))

                let expectedChange = Change("", "foo")

                let receivedChange = await receiver.change

                expect(receivedChange).toNot(beNil())
                expect(receivedChange) == expectedChange
              }
            }
          }
        }
      }
    }
  }
}

private func receiverAndObserver<State: Equatable & Sendable, T: Equatable & Sendable>(
  _ keyPath: KeyPath<State, T>,
  _ type: T.Type
) -> (UpdateReceiver<T>, PropertyPathObserver<State, T>) {
  let receiver = UpdateReceiver<T>()
  let observer: PropertyPathObserver<State, T> = .observer(
    for: keyPath,
    initiallyObservedValue: { state in
      Task {
        await receiver.setValue(state)
      }
    },
    change: { change in
      Task {
        await receiver.setChange(change)
      }
    }
  )

  return (receiver, observer)
}

private actor UpdateReceiver<T: Equatable & Sendable> {
  private(set) var value: T?

  private(set) var change: Change<T>?

  func setValue(_ value: T?) {
    self.value = value
  }

  func setChange(_ change: Change<T>?) {
    self.change = change
  }
}

