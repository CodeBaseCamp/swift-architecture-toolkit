// Copyright © Rouven Strauss. MIT license.

import ART

import Foundation
import Nimble
import Quick

struct State: Equatable {
  var screen = Screen.main(MainState(), 0)
  var settings = Settings()
}

enum Screen: Equatable {
  case onboarding
  case main(MainState, Int)
}

struct Settings: Equatable {
  var bar: Int = 9
}

struct MainState: Equatable {
  var isLoaded = false
  var selection: Selection = .none
}

enum Selection: Equatable {
  case none
  case value(Int)
}

final class PropertyPathSpec: QuickSpec {
  override class func spec() {
    context("key paths") {
      struct Baz: Equatable {
        var string = "qux"
        var value = 8
      }

      struct Foo: Equatable {
        var bar = 7
        var baz = Baz()
      }

      let value = Foo()

      it("returns root") {
        expect((\Foo.self).value(in: value)) == Foo()
      }

      it("returns value") {
        expect((\Foo.bar).value(in: value)) == 7
        expect((\Foo.baz).value(in: value)) == Baz()
        expect((\Foo.baz.string).value(in: value)) == "qux"
        expect((\Foo.baz.value).value(in: value)) == 8
      }
    }
  }
}
