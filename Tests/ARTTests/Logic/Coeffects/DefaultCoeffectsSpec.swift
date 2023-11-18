// Copyright © Rouven Strauss. MIT license.

import ART

import Foundation
import Nimble
import Quick

final class DefaultCoeffectsSpec: QuickSpec {
  override func spec() {
    context("initialization") {
      it("initializes with the given closures") {
        let coeffects = DefaultCoeffects(dateClosure: { Date.distantPast },
                                         uuidClosure: { UUID.zero })

        expect(coeffects.currentDate()) == .distantPast
        expect(coeffects.newUUID()) == .zero
      }
    }
  }
}
