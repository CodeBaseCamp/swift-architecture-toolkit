// Copyright © Rouven Strauss. MIT license.

import ART

import Foundation
import Nimble
import Quick

private enum TestRequest: RequestProtocol {}

extension TestRequest: HumanReadable {
  var humanReadableDescription: String { "" }
}

private typealias TestCompositeSideEffect =
  CompositeSideEffect<TestSideEffect, TestError, TestBackgroundDispatchQueueID>

private typealias TestSideEffectPerformer =
  SideEffectPerformer<TestSideEffect, TestError, TestCoeffects, TestBackgroundDispatchQueueID>

private typealias TestSideEffectCompletionIndication =
  CompletionIndication<CompositeError<SideEffectExecutionError<TestError>>>

private final class TestObject {
  var receivedSideEffectRequests = [TestSideEffect]()
  var successOrFailureMapping = [(TestSideEffect, TestError)]()
  var isRunningOnMainThread = [Bool]()
  private var lock = NSRecursiveLock()
  static let dispatchQueue = DispatchQueue(label: "RandomDispatchQueue")

  func closure(_ sideEffect: TestSideEffect,
               using _: TestCoeffects,
               completion: @escaping TestSideEffectPerformer.CompletionClosure) {
    self.receivedSideEffectRequests.append(sideEffect)
    self.lock.executeWhileLocked {
      self.isRunningOnMainThread.append(Thread.isMainThread)
    }

    var completionIndication: TestSideEffectCompletionIndication
    if let error = successOrFailureMapping[sideEffect] {
      completionIndication = .failure(.simpleError(.customError(error)))
    } else {
      completionIndication = .success
    }

    completion(completionIndication)
  }
}

final class SideEffectPerformerSpec: QuickSpec {
  override class func spec() {
    let dispatchQueues: [DispatchQueueID: DispatchQueue] = [
      .mainThread: DispatchQueue.main,
      .backgroundThread: DispatchQueue(label: "Background"),
    ]

    let error0: TestError = .inFileSystemScope(.creationOfFile(path: "foo"))
    let error1: TestError = .inFileSystemScope(.creationOfFile(path: "bar"))
    let error2: TestError = .inFileSystemScope(.creationOfFile(path: "baz"))
    let error3: TestError = .inFileSystemScope(.creationOfFile(path: "qux"))
    let error4: TestError = .inFileSystemScope(.creationOfFile(path: "fred"))

    var testObject: TestObject!
    var performer: TestSideEffectPerformer!
    var coeffects: TestCoeffects!

    beforeEach {
      testObject = TestObject()
      performer = .init(dispatchQueues: dispatchQueues, sideEffectClosure: testObject.closure)
      coeffects = .init()
    }

    context("side-effect-less side effect") {
      it("does not perform side effect") {
        performer.perform(.doNothing, using: coeffects) { _ in }

        expect(testObject.receivedSideEffectRequests).to(beEmpty())
      }

      it("performs completion") {
        var receivedCompletionIndication: TestSideEffectCompletionIndication?

        performer.perform(.doNothing, using: coeffects) { receivedCompletionIndication = $0 }

        expect(receivedCompletionIndication).toNot(beNil())
        expect(receivedCompletionIndication?.error).to(beNil())
      }
    }

    context("non-composite side effect on correct thread") {
      let sideEffect: TestSideEffect =
        .inFileSystemScope(.creationOfFile(atPath: "foo", with: Data()))

      context("without follow-up side effects and wrapping error") {
        let compositeSideEffect: TestCompositeSideEffect = .only(sideEffect, on: .mainThread)

        it("performs side effect") {
          performer.perform(compositeSideEffect, using: coeffects) { _ in }

          expect(testObject.receivedSideEffectRequests).toEventually(equal([sideEffect]))
        }

        it("performs side effect on correct thread") {
          performer.perform(compositeSideEffect, using: coeffects) { _ in }

          expect(testObject.isRunningOnMainThread).toEventually(equal([true]))
        }

        context("success") {
          it("performs completion") {
            var receivedCompletionIndication: TestSideEffectCompletionIndication?

            performer.perform(compositeSideEffect, using: coeffects) {
              receivedCompletionIndication = $0
            }

            expect(receivedCompletionIndication).toEventuallyNot(beNil())
            expect(receivedCompletionIndication?.error).to(beNil())
          }

          it("performs completion on correct thread") {
            var isRunningOnMainThread = false

            performer.perform(compositeSideEffect, using: coeffects) { _ in
              isRunningOnMainThread = Thread.isMainThread
            }

            expect(isRunningOnMainThread).toEventually(beTruthy())
          }
        }

        context("error") {
          beforeEach {
            testObject.successOrFailureMapping[sideEffect] = error0
          }

          it("performs completion") {
            var receivedCompletionIndication: TestSideEffectCompletionIndication?

            performer.perform(compositeSideEffect, using: coeffects) {
              receivedCompletionIndication = $0
            }

            expect(receivedCompletionIndication).toEventuallyNot(beNil())
            expect(receivedCompletionIndication?.error) == .simpleError(.customError(error0))
          }

          it("performs completion on correct thread") {
            var isRunningOnMainThread = false

            performer.perform(compositeSideEffect, using: coeffects) { _ in
              isRunningOnMainThread = true
            }

            expect(isRunningOnMainThread).toEventually(beTruthy())
          }
        }
      }

      context("without follow-up side effects but with wrapping error") {
        let compositeSideEffect: TestCompositeSideEffect =
          .only(sideEffect, on: .mainThread)

        it("performs side effect") {
          performer.perform(compositeSideEffect, using: coeffects) { _ in }

          expect(testObject.receivedSideEffectRequests).toEventually(equal([sideEffect]))
        }

        it("performs side effect on correct thread") {
          performer.perform(compositeSideEffect, using: coeffects) { _ in }

          expect(testObject.isRunningOnMainThread).toEventually(equal([true]))
        }

        context("success") {
          it("performs completion") {
            var receivedCompletionIndication: TestSideEffectCompletionIndication?

            performer.perform(compositeSideEffect, using: coeffects) {
              receivedCompletionIndication = $0
            }

            expect(receivedCompletionIndication).toEventuallyNot(beNil())
            expect(receivedCompletionIndication?.error).to(beNil())
          }

          it("performs completion on correct thread") {
            var isRunningOnMainThread = false

            performer.perform(compositeSideEffect, using: coeffects) { _ in
              isRunningOnMainThread = Thread.isMainThread
            }

            expect(isRunningOnMainThread).toEventually(beTruthy())
          }
        }

        context("error") {
          beforeEach {
            testObject.successOrFailureMapping[sideEffect] = error0
          }

          it("performs completion") {
            var receivedCompletionIndication: TestSideEffectCompletionIndication?

            performer.perform(compositeSideEffect, using: coeffects) {
              receivedCompletionIndication = $0
            }

            expect(receivedCompletionIndication).toEventuallyNot(beNil())
            expect(receivedCompletionIndication?.error) == .simpleError(.customError(error0))
          }

          it("performs completion on correct thread") {
            var isRunningOnMainThread = false

            performer.perform(compositeSideEffect, using: coeffects) { _ in
              isRunningOnMainThread = Thread.isMainThread
            }

            expect(isRunningOnMainThread).toEventually(beTruthy())
          }
        }
      }
    }

    context("composite side effects on correct thread") {
      let sideEffect: TestSideEffect =
        .inFileSystemScope(.creationOfFile(atPath: "foo", with: Data()))

      context("without follow-up side effects and wrapping error") {
        let compositeSideEffect: TestCompositeSideEffect =
          .asynchronously(sideEffect, on: .mainThread, andUponSuccess: .doNothing,
                          uponFailure: .doNothing, andWrapErrorInside: nil)

        it("performs side effect") {
          performer.perform(compositeSideEffect, using: coeffects) { _ in }

          expect(testObject.receivedSideEffectRequests).toEventually(equal([sideEffect]))
        }

        it("performs side effect on correct thread") {
          performer.perform(compositeSideEffect, using: coeffects) { _ in }

          expect(testObject.isRunningOnMainThread).toEventually(equal([true]))
        }

        context("success") {
          it("performs completion") {
            var receivedCompletionIndication: TestSideEffectCompletionIndication?

            performer.perform(compositeSideEffect, using: coeffects) {
              receivedCompletionIndication = $0
            }

            expect(receivedCompletionIndication).toEventuallyNot(beNil())
            expect(receivedCompletionIndication?.error).to(beNil())
          }

          it("performs completion on correct thread") {
            var isRunningOnMainThread = false

            performer.perform(compositeSideEffect, using: coeffects) { _ in
              isRunningOnMainThread = Thread.isMainThread
            }

            expect(isRunningOnMainThread).toEventually(beTruthy())
          }
        }

        context("error") {
          beforeEach {
            testObject.successOrFailureMapping[sideEffect] = error0
          }

          it("performs completion") {
            var receivedCompletionIndication: TestSideEffectCompletionIndication?

            performer.perform(compositeSideEffect, using: coeffects) {
              receivedCompletionIndication = $0
            }

            expect(receivedCompletionIndication).toEventuallyNot(beNil())
            expect(receivedCompletionIndication?.error) == .simpleError(.customError(error0))
          }

          it("performs completion on correct thread") {
            var isRunningOnMainThread = false

            performer.perform(compositeSideEffect, using: coeffects) { _ in
              isRunningOnMainThread = Thread.isMainThread
            }

            expect(isRunningOnMainThread).toEventually(beTruthy())
          }
        }
      }

      context("without follow-up side effects but with wrapping error") {
        let compositeSideEffect: TestCompositeSideEffect =
          .asynchronously(sideEffect, on: .mainThread, andUponSuccess: .doNothing,
                          uponFailure: .doNothing, andWrapErrorInside: .ignoredError)

        it("performs side effect") {
          performer.perform(compositeSideEffect, using: coeffects) { _ in }

          expect(testObject.receivedSideEffectRequests).toEventually(equal([sideEffect]))
        }

        it("performs side effect on correct thread") {
          performer.perform(compositeSideEffect, using: coeffects) { _ in }

          expect(testObject.isRunningOnMainThread).toEventually(equal([true]))
        }

        context("success") {
          it("performs completion") {
            var receivedCompletionIndication: TestSideEffectCompletionIndication?

            performer.perform(compositeSideEffect, using: coeffects) {
              receivedCompletionIndication = $0
            }

            expect(receivedCompletionIndication).toEventuallyNot(beNil())
            expect(receivedCompletionIndication?.error).to(beNil())
          }

          it("performs completion on correct thread") {
            var isRunningOnMainThread = false

            performer.perform(compositeSideEffect, using: coeffects) { _ in
              isRunningOnMainThread = Thread.isMainThread
            }

            expect(isRunningOnMainThread).toEventually(beTruthy())
          }
        }

        context("error") {
          beforeEach {
            testObject.successOrFailureMapping[sideEffect] = error0
          }

          it("performs completion") {
            var receivedCompletionIndication: TestSideEffectCompletionIndication?

            performer.perform(compositeSideEffect, using: coeffects) {
              receivedCompletionIndication = $0
            }

            expect(receivedCompletionIndication).toEventuallyNot(beNil())
            expect(receivedCompletionIndication?.error) == .compositeError(
              .simpleError(.customError(.ignoredError)),
              underlyingErrors: .single(.simpleError(.customError(error0)))
            )
          }

          it("performs completion on correct thread") {
            var isRunningOnMainThread = false

            performer.perform(compositeSideEffect, using: coeffects) { _ in
              isRunningOnMainThread = Thread.isMainThread
            }

            expect(isRunningOnMainThread).toEventually(beTruthy())
          }
        }
      }

      context("with follow-up side effects but without wrapping error") {
        let successSideEffect: TestSideEffect =
          .inFileSystemScope(.movingOfItem(fromPath: "foo", toPath: "bar"))
        let failureSideEffect: TestSideEffect = .inFileSystemScope(.removalOfItem(atPath: "baz"))
        let compositeSideEffect: TestCompositeSideEffect =
          .asynchronously(sideEffect, on: .mainThread,
                          andUponSuccess: .asynchronously(successSideEffect,
                                                          on: .backgroundThread,
                                                          andUponSuccess: .doNothing,
                                                          uponFailure: .doNothing,
                                                          andWrapErrorInside: nil),
                          uponFailure: .asynchronously(failureSideEffect, on: .backgroundThread,
                                                       andUponSuccess: .doNothing,
                                                       uponFailure: .doNothing,
                                                       andWrapErrorInside: nil),
                          andWrapErrorInside: nil)

        it("performs side effects in correct order") {
          performer.perform(compositeSideEffect, using: coeffects) { _ in }

          expect(testObject.receivedSideEffectRequests).toEventually(equal([sideEffect,
                                                                            successSideEffect]))
        }

        it("performs side effects on correct threads") {
          performer.perform(compositeSideEffect, using: coeffects) { _ in }

          expect(testObject.isRunningOnMainThread).toEventually(equal([true, false]))
        }

        context("success") {
          it("performs completion") {
            var receivedCompletionIndication: TestSideEffectCompletionIndication?

            performer.perform(compositeSideEffect, using: coeffects) {
              receivedCompletionIndication = $0
            }

            expect(receivedCompletionIndication).toEventuallyNot(beNil())
            expect(receivedCompletionIndication?.error).to(beNil())
          }

          it("performs completion with failing success side effect") {
            testObject.successOrFailureMapping[successSideEffect] = error0

            var receivedCompletionIndication: TestSideEffectCompletionIndication?

            performer.perform(compositeSideEffect, using: coeffects) {
              receivedCompletionIndication = $0
            }

            expect(receivedCompletionIndication).toEventuallyNot(beNil())
            expect(receivedCompletionIndication?.error) == .simpleError(.customError(error0))
          }

          it("performs completion on correct thread") {
            var isRunningOnMainThread = false

            performer.perform(compositeSideEffect, using: coeffects) { _ in
              isRunningOnMainThread = Thread.isMainThread
            }

            expect(isRunningOnMainThread).toEventually(beTruthy())
          }
        }

        context("error") {
          beforeEach {
            testObject.successOrFailureMapping[sideEffect] = error0
          }

          it("performs completion") {
            var receivedCompletionIndication: TestSideEffectCompletionIndication?

            performer.perform(compositeSideEffect, using: coeffects) {
              receivedCompletionIndication = $0
            }

            expect(receivedCompletionIndication).toEventuallyNot(beNil())
            expect(receivedCompletionIndication?.error) == .simpleError(.customError(error0))
          }

          it("performs completion with failing failure side effect") {
            testObject.successOrFailureMapping[failureSideEffect] = error1

            var receivedCompletionIndication: TestSideEffectCompletionIndication?

            performer.perform(compositeSideEffect, using: coeffects) {
              receivedCompletionIndication = $0
            }

            expect(receivedCompletionIndication).toEventuallyNot(beNil())
            expect(receivedCompletionIndication?.error) == .compositeError(
              .simpleError(.customError(error1)),
              underlyingErrors: .single(.simpleError(.customError(error0)))
            )
          }

          it("performs completion on correct thread") {
            var isRunningOnMainThread = false

            performer.perform(compositeSideEffect, using: coeffects) { _ in
              isRunningOnMainThread = Thread.isMainThread
            }

            expect(isRunningOnMainThread).toEventually(beTruthy())
          }
        }
      }

      context("with follow-up side effects but with wrapping error") {
        let testPath = "foo"
        let otherTestPath = "bar"
        let successSideEffect: TestSideEffect =
          .inFileSystemScope(.movingOfItem(fromPath: testPath, toPath: otherTestPath))
        let failureSideEffect: TestSideEffect = .inFileSystemScope(.removalOfItem(atPath: testPath))
        let compositeSideEffect: TestCompositeSideEffect =
          .asynchronously(sideEffect, on: .mainThread,
                          andUponSuccess: .asynchronously(successSideEffect,
                                                          on: .backgroundThread,
                                                          andUponSuccess: .doNothing,
                                                          uponFailure: .doNothing,
                                                          andWrapErrorInside: error2),
                          uponFailure: .asynchronously(failureSideEffect, on: .backgroundThread,
                                                       andUponSuccess: .doNothing,
                                                       uponFailure: .doNothing,
                                                       andWrapErrorInside: error3),
                          andWrapErrorInside: error4)

        it("performs side effects in correct order") {
          performer.perform(compositeSideEffect, using: coeffects) { _ in }

          expect(testObject.receivedSideEffectRequests).toEventually(equal([sideEffect,
                                                                            successSideEffect]))
        }

        it("performs side effects on correct threads") {
          performer.perform(compositeSideEffect, using: coeffects) { _ in }

          expect(testObject.isRunningOnMainThread).toEventually(equal([true, false]))
        }

        context("success") {
          it("performs completion") {
            var receivedCompletionIndication: TestSideEffectCompletionIndication?

            performer.perform(compositeSideEffect, using: coeffects) {
              receivedCompletionIndication = $0
            }

            expect(receivedCompletionIndication).toEventuallyNot(beNil())
            expect(receivedCompletionIndication?.error).to(beNil())
          }

          it("performs completion with failing success side effect") {
            testObject.successOrFailureMapping[successSideEffect] = error0

            var receivedCompletionIndication: TestSideEffectCompletionIndication?

            performer.perform(compositeSideEffect, using: coeffects) {
              receivedCompletionIndication = $0
            }

            expect(receivedCompletionIndication).toEventuallyNot(beNil())
            expect(receivedCompletionIndication?.error) ==
              .compositeError(
                .simpleError(.customError(error4)),
                underlyingErrors: .single(
                  .compositeError(
                    .simpleError(.customError(error2)),
                    underlyingErrors: .single(.simpleError(.customError(error0)))
                  )
                )
              )
          }

          it("performs completion on correct thread") {
            var isRunningOnMainThread = false

            performer.perform(compositeSideEffect, using: coeffects) { _ in
              isRunningOnMainThread = Thread.isMainThread
            }

            expect(isRunningOnMainThread).toEventually(beTruthy())
          }
        }

        context("error") {
          beforeEach {
            testObject.successOrFailureMapping[sideEffect] = error0
          }

          it("performs completion") {
            var receivedCompletionIndication: TestSideEffectCompletionIndication?

            performer.perform(compositeSideEffect, using: coeffects) {
              receivedCompletionIndication = $0
            }

            expect(receivedCompletionIndication).toEventuallyNot(beNil())
            expect(receivedCompletionIndication?.error) == .compositeError(
              .simpleError(.customError(error4)),
              underlyingErrors: .single(.simpleError(.customError(error0)))
            )
          }

          it("performs completion with failing failure side effect") {
            testObject.successOrFailureMapping[failureSideEffect] = error1

            var receivedCompletionIndication: TestSideEffectCompletionIndication?

            performer.perform(compositeSideEffect, using: coeffects) {
              receivedCompletionIndication = $0
            }

            expect(receivedCompletionIndication).toEventuallyNot(beNil())
            expect(receivedCompletionIndication?.error) ==
              .compositeError(
                .simpleError(.customError(error4)),
                underlyingErrors: .single(
                  .compositeError(
                    .compositeError(.simpleError(.customError(error3)),
                                    underlyingErrors: .single(.simpleError(.customError(error1)))),
                    underlyingErrors: .single(.simpleError(.customError(error0)))
                  )
                )
              )
          }

          it("performs completion on correct thread") {
            var isRunningOnMainThread = false

            performer.perform(compositeSideEffect, using: coeffects) { _ in
              isRunningOnMainThread = Thread.isMainThread
            }

            expect(isRunningOnMainThread).toEventually(beTruthy())
          }
        }
      }
    }
  }
}

private extension Array where Element == (TestSideEffect, TestError) {
  subscript(key: TestSideEffect) -> TestError? {
    get {
      return self.first(where: { $0.0 == key })?.1
    }
    set(newValue) {
      if let index = self.firstIndex(where: { $0.0 == key }) {
        if let error = newValue {
          self[index] = (key, error)
        } else {
          self.removeAll { $0.0 == key }
        }
        return
      }

      if let error = newValue {
        self.append((key, error))
      }
    }
  }
}
