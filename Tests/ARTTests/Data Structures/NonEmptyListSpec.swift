// Copyright © Rouven Strauss. MIT license.

import ART

import Foundation
import Nimble
import Quick

final class NonEmptyListSpec: QuickSpec {
  override func spec() {
    context("initialization") {
      it("initializes with single element") {
        _ = NonEmptyList.single(0)
        _ = NonEmptyList.from([0])
      }

      it("initializes with multiple elements") {
        _ = NonEmptyList.multiple(head: 1, tail: .single(0))
        _ = NonEmptyList.multiple(head: 2, tail: .multiple(head: 1, tail: .single(0)))
        _ = NonEmptyList.from([1, 0])
        _ = NonEmptyList.from([2, 1, 0])
      }
    }

    context("factory methods") {
      it("returns instance from collection") {
        expect(NonEmptyList.from([0])) ==
          NonEmptyList.single(0)
        expect(NonEmptyList.from([1, 0])) ==
          NonEmptyList.multiple(head: 1, tail: .single(0))
        expect(NonEmptyList.from([2, 1, 0])) ==
          NonEmptyList.multiple(head: 2, tail: .multiple(head: 1, tail: .single(0)))
      }
    }

    context("properties") {
      var list1: NonEmptyList<Int>!
      var list2: NonEmptyList<Int>!
      var list3: NonEmptyList<Int>!

      beforeEach {
        list1 = NonEmptyList.single(0)
        list2 = NonEmptyList.multiple(head: 1, tail: .single(0))
        list3 = NonEmptyList.multiple(head: 2, tail: .multiple(head: 1, tail: .single(0)))
      }

      it("provides count") {
        expect(list1.count) == 1
        expect(list2.count) == 2
        expect(list3.count) == 3
      }

      it("provides head") {
        expect(list1.head) == 0
        expect(list2.head) == 1
        expect(list3.head) == 2
      }

      it("provides tail") {
        expect(list1.tail) == 0
        expect(list2.tail) == 0
        expect(list3.tail) == 0
      }

      it("provides elements as array") {
        expect(list1.asArray) == [0]
        expect(list2.asArray) == [1, 0]
        expect(list3.asArray) == [2, 1, 0]
      }

      it("provides reversed copy") {
        expect(list1.reversed) == list1
        expect(list2.reversed) == NonEmptyList.from([0, 1])
        expect(list3.reversed) == NonEmptyList.from([0, 1, 2])
      }

      it("returns copy with mapped values") {
        expect(list1.map { $0 + 1 }) == NonEmptyList.from([1])
        expect(list2.map { $0 + 1 }) == NonEmptyList.from([2, 1])
        expect(list3.map { $0 + 1 }) == NonEmptyList.from([3, 2, 1])
      }

      it("returns containment indication") {
        [0, 1, 2].forEach {
          expect(list3.contains($0)).to(beTruthy())
        }

        expect(list3.contains(3)).to(beFalsy())
      }

      it("returns indication of customizable containment") {
        expect(list3.contains(where: { $0 <= 2 })).to(beTruthy())

        expect(list3.contains(where: { $0 > 2 })).to(beFalsy())
      }

      it("returns copy with appended head") {
        expect(list1.withAppendedHead(1)) == NonEmptyList.from([1, 0])
        expect(list2.withAppendedHead(2)) == NonEmptyList.from([2, 1, 0])
        expect(list3.withAppendedHead(3)) == NonEmptyList.from([3, 2, 1, 0])
      }

      it("returns copy with appended tail") {
        expect(list1.withAppendedTail(list3)) == NonEmptyList.from([0, 2, 1, 0])
        expect(list2.withAppendedTail(list3)) == NonEmptyList.from([1, 0, 2, 1, 0])
        expect(list3.withAppendedTail(list3)) == NonEmptyList.from([2, 1, 0, 2, 1, 0])
      }
    }
  }
}
