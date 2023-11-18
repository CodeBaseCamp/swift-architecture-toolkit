// Copyright © Rouven Strauss. MIT license.

import ART

import CasePaths
import Foundation
import Nimble
import Quick

enum FakeEnum: Equatable {
  case value(Int)
  case anotherValue
}

extension FakeEnum: StateProtocol {
  static func instance(from _: Data) throws -> Self {
    fatalErrorDueToMissingImplementation()
  }

  func data() throws -> Data {
    fatalErrorDueToMissingImplementation()
  }
}

final class ModelSpec: QuickSpec {
  override func spec() {
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
        var initialState: FakeEnum!
        var coeffects: TestCoeffects!
        var reducer: Reducer<FakeEnum, FakeRequest, TestCoeffects>!
        var model: Model<FakeEnum, FakeRequest, TestCoeffects>!

        beforeEach {
          initialState = .value(0)
          coeffects = TestCoeffects()
          reducer = Reducer<FakeEnum, FakeRequest, TestCoeffects> { state, requests, _ in
            requests.forEach { request in
              switch request {
              case .a:
                state = .value(7)
              case .b:
                state = .anotherValue
              }
            }
          }
          model = Model(state: initialState, reduce: reducer.reduce)
        }

        it("adds observer") {
          let observer = ModelObserver(for: /FakeEnum.value,
                                       initiallyObservedValue: { _ in },
                                       change: { _ in })
          model.add(observer)
        }

        it("holds observer weakly") {
          weak var weakObserver: ModelObserver<FakeEnum>?

          autoreleasepool {
            let observer = ModelObserver(for: /FakeEnum.value,
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
              var receivedValue: FakeEnum?
              var observer: PropertyPathObserver<FakeEnum, FakeEnum>!

              beforeEach {
                receivedValue = nil
                observer = .observer(for: /FakeEnum.self,
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
              var receivedChange: Change<FakeEnum?>?
              var observer: PropertyPathObserver<FakeEnum, FakeEnum>!

              beforeEach {
                receivedChange = nil
                observer = .observer(for: /FakeEnum.self,
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

                let expectedChange = Change<FakeEnum?>(
                  initialState!,
                  copied(initialState!) {
                    $0 = .value(7)
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
              var observer: PropertyPathObserver<FakeEnum, Int>!

              beforeEach {
                receivedValue = nil
                observer = .observer(
                  for: /FakeEnum.value,
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
              var receivedChange: Change<Int?>?
              var observer: PropertyPathObserver<FakeEnum, Int>!

              beforeEach {
                receivedChange = nil
                observer = .observer(
                  for: /FakeEnum.value,
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

                let expectedChange = Change<Int?>(
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
              var receivedValue: Bool!
              var observer: PropertyPathObserver<FakeEnum, Bool>!

              beforeEach {
                receivedValue = true
                observer = .observer(
                  for: /FakeEnum.anotherValue,
                  initiallyObservedValue: { receivedValue = $0 },
                  change: { _ in }
                )
              }

              it("executes observer callback upon adding of observer") {
                model.add(observer)

                expect(receivedValue).to(beFalsy())
              }

              it("does not execute observer callback upon state change") {
                model.add(observer)
                receivedValue = true

                model.handle(.a(.updateOfValue), using: coeffects)

                expect(receivedValue).to(beTruthy())
              }
            }

            context("change") {
              var receivedChange: Change<Bool>?
              var observer: PropertyPathObserver<FakeEnum, Bool>!

              beforeEach {
                receivedChange = nil
                observer = .observer(
                  for: /FakeEnum.anotherValue,
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

                let expectedChange = Change(false, true)

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
