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
  CompositeSideEffect<TestSideEffect, TestError>

private typealias TestSideEffectPerformer = SideEffectPerformer<
  TestSideEffect,
  TestError,
  TestCoeffects
>

private typealias TestSideEffectCompletionIndication =
  CompletionIndication<CompositeError<SideEffectExecutionError<TestError>>>

private actor TestObject {
  var receivedSideEffects = [TestSideEffect]()
  var successOrFailureMapping = [(TestSideEffect, TestError)]()

  func receivedSideEffects() async -> [TestSideEffect] {
    return self.receivedSideEffects
  }

  func appendError(_ sideEffectAndError: (TestSideEffect, TestError)) async {
    self.successOrFailureMapping.append(sideEffectAndError)
  }

  func sideEffectClosure(
    _ sideEffect: TestSideEffect,
    using _: TestCoeffects
  ) async -> CompletionIndication<CompositeError<SideEffectExecutionError<TestError>>> {
    self.receivedSideEffects.append(sideEffect)

    var completionIndication: TestSideEffectCompletionIndication
    if let error = successOrFailureMapping.first(where: { $0.0 == sideEffect }) {
      completionIndication = .failure(.simpleError(.customError(error.1)))
    } else {
      completionIndication = .success
    }

    return completionIndication
  }
}

final class SideEffectPerformerSpec: AsyncSpec {
  override class func spec() {
    let error0: TestError = .inFileSystemScope(.creationOfFile(path: "foo"))

    var testObject: TestObject!
    var performer: TestSideEffectPerformer!
    var coeffects: TestCoeffects!

    beforeEach {
      let object = TestObject()
      testObject = object
      performer = .init(
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
        let compositeSideEffect: TestCompositeSideEffect = .only(sideEffect)

        it("performs side effect") {
          await performer.perform(compositeSideEffect, using: coeffects)

          let receivedSideEffects = await testObject.receivedSideEffects()
          expect(receivedSideEffects) == [sideEffect]
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
        let compositeSideEffect: TestCompositeSideEffect = .only(sideEffect)

        it("performs side effect") {
          await performer.perform(compositeSideEffect, using: coeffects)

          let receivedSideEffects = await testObject.receivedSideEffects()
          expect(receivedSideEffects).to(equal([sideEffect]))
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
