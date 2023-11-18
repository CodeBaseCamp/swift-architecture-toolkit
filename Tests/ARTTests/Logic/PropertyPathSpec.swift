// Copyright © Rouven Strauss. MIT license.

import ART

import CasePaths
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
  override func spec() {
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

    context("enums") {
      context("enums without associated values") {
        enum Enum {
          case a
          case b
        }

        let value = Enum.a

        it("returns root") {
          expect((/Enum.self).value(in: value)) == .a
        }

        it("returns existence indication") {
          expect((/Enum.a).value(in: value)) == ()
          expect((/Enum.b).value(in: value)).to(beNil())
        }
      }

      context("enums without with associated values, including structs") {
        struct Foo: Equatable {
          var bar: Int
        }

        enum Enum: Equatable {
          case a
          case b(Int)
          case c(Foo, Int)
        }

        let singleValueEnum = Enum.b(7)
        let doubleValueEnum = Enum.c(Foo(bar: 7), 8)

        it("returns root") {
          expect((/Enum.self).value(in: singleValueEnum)) == .b(7)
          expect((/Enum.self).value(in: doubleValueEnum)) == .c(Foo(bar: 7), 8)
        }

        it("returns associated value") {
          expect((/Enum.b).value(in: singleValueEnum)) == 7
          expect((/Enum.b).value(in: doubleValueEnum)).to(beNil())

          expect((/Enum.c).value(in: singleValueEnum)).to(beNil())
          expect((/Enum.c).value(in: doubleValueEnum)) == (Foo(bar: 7), 8)
        }
      }
    }

    context("property paths") {
      context("structs containing enums without associated values") {
        struct Foo {
          var value: Enum
        }

        enum Enum {
          case a
          case b
        }

        let value = Foo(value: .a)

        it("returns existence indication") {
          expect((\Foo.value~Enum.a).value(in: value)) == ()
          expect((\Foo.value~Enum.b).value(in: value)).to(beNil())
        }
      }

      context("structs containing enums with associated values, including structs") {
        struct Foo: Equatable {
          var value: Enum
        }

        enum Enum: Equatable {
          case a
          case b(Int)
          case c(Bar, Int)
        }

        enum AnotherEnum: Equatable {
          case x
        }

        struct Bar: Equatable {
          var baz: String
          var value: AnotherEnum
        }

        let singleValueStruct = Foo(value: .b(7))
        let doubleValueStruct = Foo(value: .c(Bar(baz: "qux", value: .x), 8))

        it("returns associated value") {
          expect((\Foo.value~Enum.b).value(in: singleValueStruct)) == 7
          expect((\Foo.value~Enum.b).value(in: doubleValueStruct)).to(beNil())

          expect((\Foo.value~Enum.c).value(in: singleValueStruct)).to(beNil())
          expect((\Foo.value~Enum.c).value(in: doubleValueStruct))
            == (Bar(baz: "qux", value: .x), 8)
        }

        it("returns nested value") {
          expect((\Foo.value~Enum.c~\.0.baz).value(in: doubleValueStruct)) == "qux"
        }

        it("returns existence indication") {
          expect((\Foo.value~Enum.c~\.0.value~AnotherEnum.x).value(in: doubleValueStruct)) == ()
          expect((\Foo.value~Enum.c~\.0.value~AnotherEnum.x).value(in: singleValueStruct))
            .to(beNil())
        }
      }
    }
  }
}
