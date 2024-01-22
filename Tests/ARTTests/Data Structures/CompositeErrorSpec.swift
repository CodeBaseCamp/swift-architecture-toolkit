// Copyright © Rouven Strauss. MIT license.

import ART

import Foundation
import Nimble
import Quick

final class CompositeErrorSpec: QuickSpec {
  override class func spec() {
    context("initialization") {
      it("initializes as simple error") {
        _ = CompositeError<TestError>.simpleError(.inFileSystemScope(.creationOfFile(path: "foo")))
      }

      it("initializes as composite error") {
        _ = CompositeError<TestError>
          .compositeError(
            .simpleError(.ignoredError),
            underlyingErrors: .single(
              .simpleError(.inFileSystemScope(.creationOfFile(path: "foo")))
            )
          )
        _ = CompositeError<TestError>
          .compositeError(
            .simpleError(.ignoredError),
            underlyingErrors: .multiple(
              head: .simpleError(.inFileSystemScope(.creationOfFile(path: "foo"))),
              tail: .single(.simpleError(.inFileSystemScope(.creationOfFile(path: "bar"))))
            )
          )
      }
    }
  }
}
