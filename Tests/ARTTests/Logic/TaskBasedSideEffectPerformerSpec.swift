// Copyright © Rouven Strauss. MIT license.

@testable import ART

import Foundation
import Nimble
import Quick

private enum TestRequest: RequestProtocol {}

extension TestRequest: HumanReadable {
  var humanReadableDescription: String { "" }
}

private typealias TestCompositeSideEffect =
  CompositeSideEffect<TestSideEffect, TestError, TestBackgroundDispatchQueueID>

private typealias TestSideEffectPerformer = TaskBasedSideEffectPerformer<
  TestSideEffect,
  TestError,
  TestCoeffects,
  TestBackgroundDispatchQueueID
>

private typealias TestSideEffectCompletionIndication =
  CompletionIndication<CompositeError<SideEffectExecutionError<TestError>>>

private final class TestObject {
  var receivedSideEffects = [TestSideEffect]()
  var successOrFailureMapping = [(TestSideEffect, TestError)]()
  var isRunningOnMainThread = [Bool]()
  static let dispatchQueue = DispatchQueue(label: "RandomDispatchQueue")

  func receivedSideEffects() async -> [TestSideEffect] {
    return self.receivedSideEffects
  }

  func isRunningOnMainThread() async -> [Bool] {
    return self.isRunningOnMainThread
  }

  func appendError(_ sideEffectAndError: (TestSideEffect, TestError)) async {
    self.successOrFailureMapping.append(sideEffectAndError)
  }

  func sideEffectClosure(
    _ sideEffect: TestSideEffect,
    using _: TestCoeffects
  ) -> CompletionIndication<CompositeError<SideEffectExecutionError<TestError>>> {
    self.receivedSideEffects.append(sideEffect)
    self.isRunningOnMainThread.append(Thread.isMainThread)

    var completionIndication: TestSideEffectCompletionIndication
    if let error = successOrFailureMapping.first(where: { $0.0 == sideEffect }) {
      completionIndication = .failure(.simpleError(.customError(error.1)))
    } else {
      completionIndication = .success
    }

    return completionIndication
  }
}

final class TaskBasedSideEffectPerformerSpec: AsyncSpec {
  override class func spec() {
    let error0: TestError = .inFileSystemScope(.creationOfFile(path: "foo"))

    var testObject: TestObject!
    var performer: TestSideEffectPerformer!
    var coeffects: TestCoeffects!

    beforeEach {
      let object = TestObject()
      testObject = object
      performer = .init(
        actors: [
          .mainThread: MainActor.shared,
          .backgroundThread: BackgroundActor(),
        ], 
        sideEffectClosure: object.sideEffectClosure
      )
      coeffects = .init()
    }

    context("side-effect-less side effect") {
      it("does not perform side effect") {
        await performer.perform(.doNothing, using: coeffects)
        
        let receivedSideEffects = await testObject.receivedSideEffects()
        expect(receivedSideEffects).to(beEmpty())
      }

      it("performs completion") {
        let receivedCompletionIndication = await performer.perform(.doNothing, using: coeffects)

        expect(receivedCompletionIndication == .success).to(beTruthy())
      }
    }

    context("non-composite side effect on correct thread") {
      let sideEffect: TestSideEffect =
        .inFileSystemScope(.creationOfFile(atPath: "foo", with: Data()))

      context("without follow-up side effects and wrapping error") {
        let compositeSideEffect: TestCompositeSideEffect = .only(sideEffect, on: .mainThread)

        it("performs side effect") {
          await performer.perform(compositeSideEffect, using: coeffects)

          let receivedSideEffects = await testObject.receivedSideEffects()
          expect(receivedSideEffects) == [sideEffect]
        }

        it("performs side effect on correct thread") {
          await performer.perform(compositeSideEffect, using: coeffects)

          let isRunningOnMainThread = await testObject.isRunningOnMainThread()
          expect(isRunningOnMainThread).to(equal([true]))
        }

        context("success") {
          it("performs completion") {
            let receivedCompletionIndication =
              await performer.perform(compositeSideEffect, using: coeffects)

            expect(receivedCompletionIndication == .success).to(beTruthy())
          }
        }

        context("error") {
          beforeEach {
            await testObject.appendError((sideEffect, error0))
          }

          it("performs completion") {
            let receivedCompletionIndication =
              await performer.perform(compositeSideEffect, using: coeffects)

            expect(receivedCompletionIndication.error) == .simpleError(.customError(error0))
          }
        }
      }

      context("without follow-up side effects but with wrapping error") {
        let compositeSideEffect: TestCompositeSideEffect =
          .only(sideEffect, on: .mainThread)

        it("performs side effect") {
          await performer.perform(compositeSideEffect, using: coeffects)

          let receivedSideEffects = await testObject.receivedSideEffects()
          expect(receivedSideEffects).to(equal([sideEffect]))
        }

        it("performs side effect on correct thread") {
          await performer.perform(compositeSideEffect, using: coeffects)

          let isRunningOnMainThread = await testObject.isRunningOnMainThread()
          expect(isRunningOnMainThread).to(equal([true]))
        }

        context("success") {
          it("performs completion") {
            let receivedCompletionIndication =
              await performer.perform(compositeSideEffect, using: coeffects)

            expect(receivedCompletionIndication == .success).to(beTruthy())
          }
        }

        context("error") {
          beforeEach {
            await testObject.appendError((sideEffect, error0))
          }

          it("performs completion") {
            let receivedCompletionIndication =
              await performer.perform(compositeSideEffect, using: coeffects)

            expect(receivedCompletionIndication.error) == .simpleError(.customError(error0))
          }
        }
      }
    }
  }
}
