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

final class ModelSpec: QuickSpec {
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
          model.add(observer)
        }

        it("holds observer weakly") {
          weak var weakObserver: ModelObserver<FakeState>?

          autoreleasepool {
            let observer = ModelObserver(for: \FakeState.stateA,
                                         initiallyObservedValue: { _ in },
                                         change: { _ in })
            weakObserver = observer
            model.add(observer)

            expect(weakObserver).toNot(beNil())
          }

          expect(weakObserver).to(beNil())
        }

        context("execution") {
          context("root key path") {
            context("initially observed value") {
              var receivedValue: FakeState?
              var observer: PropertyPathObserver<FakeState, FakeState>!

              beforeEach {
                receivedValue = nil
                observer = .observer(for: \FakeState.self,
                                     initiallyObservedValue: { receivedValue = $0 },
                                     change: { _ in })
              }

              it("executes observer callback upon adding of observer") {
                model.add(observer)

                expect(receivedValue).toNot(beNil())
                expect(receivedValue) == initialState
              }

              it("does not execute observer callback upon state change") {
                model.add(observer)
                receivedValue = nil

                model.handle(.a(.updateOfValue), using: coeffects)

                expect(receivedValue).to(beNil())
              }
            }

            context("change") {
              var receivedChange: Change<FakeState>?
              var observer: PropertyPathObserver<FakeState, FakeState>!

              beforeEach {
                receivedChange = nil
                observer = .observer(for: \FakeState.self,
                                     initiallyObservedValue: { _ in },
                                     change: { change in receivedChange = change })
              }

              it("does not execute observer callback upon adding of observer") {
                model.add(observer)

                expect(receivedChange).to(beNil())
              }

              it("executes observer callback upon state change") {
                model.add(observer)

                model.handle(.a(.updateOfValue), using: coeffects)

                let expectedChange = Change(
                  initialState!,
                  copied(initialState!) {
                    $0.stateA.stringValue = $0.stateA.stringValue.copy(with: "bar")
                  }
                )
                expect(receivedChange).toNot(beNil())
                expect(receivedChange) == expectedChange
              }
            }
          }

          context("inner key path") {
            context("initially observed value") {
              var receivedValue: FakeStateA?
              var observer: PropertyPathObserver<FakeState, FakeStateA>!

              beforeEach {
                receivedValue = nil
                observer = .observer(
                  for: \FakeState.stateA,
                  initiallyObservedValue: { receivedValue = $0 },
                  change: { _ in }
                )
              }

              it("executes observer callback upon adding of observer") {
                model.add(observer)

                expect(receivedValue).toNot(beNil())
                expect(receivedValue) == initialState.stateA
              }

              it("does not execute observer callback upon state change") {
                model.add(observer)
                receivedValue = nil

                model.handle(.a(.updateOfValue), using: coeffects)

                expect(receivedValue).to(beNil())
              }
            }

            context("change") {
              var receivedChange: Change<FakeStateA>?
              var observer: PropertyPathObserver<FakeState, FakeStateA>!

              beforeEach {
                receivedChange = nil
                observer = .observer(
                  for: \FakeState.stateA,
                  initiallyObservedValue: { _ in },
                  change: { change in receivedChange = change }
                )
              }

              it("does not execute observer callback upon adding of observer") {
                model.add(observer)

                expect(receivedChange).to(beNil())
              }

              it("executes observer callback upon state change") {
                model.add(observer)

                model.handle(.a(.updateOfValue), using: coeffects)

                let expectedChange = Change(
                  initialState.stateA,
                  copied(initialState.stateA) {
                    $0.stringValue = $0.stringValue.copy(with: "bar")
                  }
                )
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
          model.add(observer)
        }

        it("holds observer weakly") {
          weak var weakObserver: ModelObserver<TestState>?

          autoreleasepool {
            let observer = ModelObserver(for: \TestState.value,
                                         initiallyObservedValue: { _ in },
                                         change: { _ in })
            weakObserver = observer
            model.add(observer)

            expect(weakObserver).toNot(beNil())
          }

          expect(weakObserver).to(beNil())
        }

        context("execution") {
          context("root property path") {
            context("initially observed value") {
              var receivedValue: TestState?
              var observer: PropertyPathObserver<TestState, TestState>!

              beforeEach {
                receivedValue = nil
                observer = .observer(for: \TestState.self,
                                     initiallyObservedValue: { receivedValue = $0 },
                                     change: { _ in })
              }

              it("executes observer callback upon adding of observer") {
                model.add(observer)

                expect(receivedValue).toNot(beNil())
                expect(receivedValue) == initialState
              }

              it("does not execute observer callback upon state change") {
                model.add(observer)
                receivedValue = nil

                model.handle(.a(.updateOfValue), using: coeffects)

                expect(receivedValue).to(beNil())
              }
            }

            context("change") {
              var receivedChange: Change<TestState>?
              var observer: PropertyPathObserver<TestState, TestState>!

              beforeEach {
                receivedChange = nil
                observer = .observer(for: \TestState.self,
                                     initiallyObservedValue: { _ in },
                                     change: { change in receivedChange = change })
              }

              it("does not execute observer callback upon adding of observer") {
                model.add(observer)

                expect(receivedChange).to(beNil())
              }

              it("executes observer callback upon state change") {
                model.add(observer)

                model.handle(.a(.updateOfValue), using: coeffects)

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
              var receivedValue: Int?
              var observer: PropertyPathObserver<TestState, Int>!

              beforeEach {
                receivedValue = nil
                observer = .observer(
                  for: \TestState.value,
                  initiallyObservedValue: { receivedValue = $0 },
                  change: { _ in }
                )
              }

              it("executes observer callback upon adding of observer") {
                model.add(observer)

                expect(receivedValue).toNot(beNil())
                expect(receivedValue) == 0
              }

              it("does not execute observer callback upon state change") {
                model.add(observer)
                receivedValue = nil

                model.handle(.a(.updateOfValue), using: coeffects)

                expect(receivedValue).to(beNil())
              }
            }

            context("change") {
              var receivedChange: Change<Int>?
              var observer: PropertyPathObserver<TestState, Int>!

              beforeEach {
                receivedChange = nil
                observer = .observer(
                  for: \TestState.value,
                  initiallyObservedValue: { _ in },
                  change: { change in receivedChange = change }
                )
              }

              it("does not execute observer callback upon adding of observer") {
                model.add(observer)

                expect(receivedChange).to(beNil())
              }

              it("executes observer callback upon state change") {
                model.add(observer)

                model.handle(.a(.updateOfValue), using: coeffects)

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
              var receivedValue: String!
              var observer: PropertyPathObserver<TestState, String>!

              beforeEach {
                observer = .observer(
                  for: \TestState.anotherValue,
                  initiallyObservedValue: { receivedValue = $0 },
                  change: { _ in }
                )
              }

              it("executes observer callback upon adding of observer") {
                model.add(observer)

                expect(receivedValue) == ""
              }

              it("does not execute observer callback upon state change") {
                model.add(observer)

                model.handle(.a(.updateOfValue), using: coeffects)

                expect(receivedValue) == ""
              }
            }

            context("change") {
              var receivedChange: Change<String>?
              var observer: PropertyPathObserver<TestState, String>!

              beforeEach {
                receivedChange = nil
                observer = .observer(
                  for: \TestState.anotherValue,
                  initiallyObservedValue: { _ in },
                  change: { change in receivedChange = change }
                )
              }

              it("does not execute observer callback upon adding of observer") {
                model.add(observer)

                expect(receivedChange).to(beNil())
              }

              it("executes observer callback upon state change") {
                model.add(observer)

                model.handle(.b(.updateOfValue), using: coeffects)

                let expectedChange = Change("", "foo")

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
