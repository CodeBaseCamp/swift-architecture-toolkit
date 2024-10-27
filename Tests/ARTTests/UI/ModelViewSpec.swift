// Copyright © Rouven Strauss. MIT license.

import ART

import Nimble
import Quick
import SwiftUI

struct FakeViewModel: ViewModel, Codable {
  var id: UUID = .zero

  let shouldBeVisible: Bool

  // MARK: ViewModel

  static func makeInstance(from state: FakeStateB?) -> Self {
    guard let state = state else {
      return Self(shouldBeVisible: false)
    }

    return Self(shouldBeVisible: state.integerValue.isMultiple(of: 2))
  }

  static func makeChange(
    from change: Change<FakeStateB?>,
    previousModel: Self
  ) -> Change<Self>? {
    let model = Self.makeInstance(from: change.current)
    return previousModel != model ? Change(previousModel, model) : nil
  }
}

struct FakeModelView: View, ModelView {
  enum Event: Hashable {
    case value(String)
  }

  typealias Model = FakeViewModel

  @ObservedObject
  private(set) var context: Context<TestCoeffects>

  var body: some View {
    return Button("Press me!") {
      self.handle(.value("Button pressed!"))
    }
  }
}

final class ModelViewSpec: AsyncSpec {
  override class func spec() {
    var view: FakeModelView!

    context("model observations") {
      typealias TestModel = Model<FakeState, FakeRequest, TestCoeffects>

      var model: TestModel!
      var coeffects: TestCoeffects!
      var observers: ModelViewObservers!

      beforeEach {
        coeffects = TestCoeffects()
        model = Model(
          state: FakeState.instance(),
          reduce: { state, requests, _ in
            requests.forEach { request in
              switch request {
              case .a:
                state.stateA.stringValue = .init("")
              case .b:
                state.stateB.integerValue = state.stateB.integerValue + 1
              }
            }
          }
        )

        (view, observers) = await FakeModelView.instance(
          observing: \FakeState.stateB,
          of: model,
          using: coeffects
        ) { _ in }
      }

      it("creates observers") {
        expect(observers).toNot(beNil())
      }

      it("holds observers weakly") {
        weak var weaklyHeldObserver: ModelViewObservers?

        var stronglyHeldObserver: ModelViewObservers?
        (view, stronglyHeldObserver) = await FakeModelView.instance(
          observing: \FakeState.stateB,
          of: model,
          using: coeffects
        ) { _ in }
        weaklyHeldObserver = stronglyHeldObserver

        expect(view).toNot(beNil())
        expect(weaklyHeldObserver).toNot(beNil())

        stronglyHeldObserver = nil

        expect(view).toNot(beNil())
        expect(weaklyHeldObserver).to(beNil())
      }
    }
  }
}
