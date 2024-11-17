// Copyright © Rouven Strauss. MIT license.

import ART

import Foundation
import Nimble
import Quick

/// Object solely existing for the purpose of explaining how `ART` works. Typically, applications
/// relying on `ART` maintain a single object similar to the one documented here which is
/// responsible for
/// a) holding the `LogicModule` instance,
/// b) holding a collection of observers which cannot be added to the `LogicModule` already during
///    its creation and must be held since the `LogicModule` does not hold dynamically added
///    observers strongly,
/// c) sending requests and/or side effects to the `LogicModule` due to changes of the system state
///    (e.g., due to the app transitioning into the background) and/or incoming events/requests from
///    external means of interaction, such as an API.
class App {
  private let logicModule: LogicModule

  private let uiLogicModule: UIEventLogicModule?

  init(with logicModule: LogicModule, uiLogicModule: UIEventLogicModule? = nil) {
    self.logicModule = logicModule
    self.uiLogicModule = uiLogicModule
  }

  /// Function implementing the state reduction logic. There are several ways of encapsulating the
  /// reduction logic and the chosen way of using a static function of `App` is solely an example.
  fileprivate static func reduce(
    state: inout App.State,
    requests: [App.Request],
    coeffects: App.Coeffects
  ) {
    requests.forEach { request in
      switch request {
      case let .completionOfDataDownload(downloadResult):
        switch downloadResult {
        case let .failure(error):
          state.errorMessage = error.localizedDescription
        case let .success(data):
          state.downloadedData = data
        }
      case .dismissalOfErrorMessage:
        state.errorMessage = nil
      }
    }
  }

  /// Function implementing side effect performing.
  fileprivate static func sideEffectClosure(
    _ handle: @escaping @Sendable (Request, Coeffects) -> Void
  ) -> SideEffectPerformer.SideEffectClosure {
    return { sideEffect, coeffects in
      switch sideEffect {
      case .downloadOfData:
        // For the sake of the example, success in downloading the data is assumed.
        handle(.completionOfDataDownload(.success(App.ArbitraryDownloadableResource())), coeffects)
        return .success
      }
    }
  }
}

//final class UsageExampleSpec: AsyncSpec {
//  override class func spec() {
//    context("minimal example application") {
//      context("setup") {
//        it("sets up application with logic module") {
//          let logicModule: App.LogicModule = .newInstance()
//          _ = App(with: logicModule)
//        }
//
//        it("sets up application with logic module and UI") {
//          let (logicModule, view, observer) = await App.LogicModule.newInstanceWithUI()
//          _ = App(with: logicModule)
//
//          connect(view)
//
//          // Make sure to hold hold observer strongly to allow for UI updates.
//          holdStrongly(observer)
//        }
//
//        // Dummy functions for example purposes.
//
//        func connect(_ view: App.MainView) {}
//        func holdStrongly(_ observer: Any) {}
//      }
//
//      context("state update and observation") {
//        it("observes current state when adding observer") {
//          let logicModule: App.LogicModule = .newInstance()
//          var observedData: App.ArbitraryDownloadableResource? = .init()
//          let observer: PropertyPathObserver = .observer(
//            for: \App.State.downloadedData,
//            initiallyObservedValue: {
//              observedData = $0
//            }
//          ) { _ in
//            fatalErrorDueToMissingImplementation()
//          }
//          await logicModule.add(observer.modelObserver)
//
//          expect(observedData).to(beNil())
//        }
//
//        it("observes state change triggered by request handling") {
//          let logicModule: App.LogicModule = .newInstance()
//          var observedData: App.ArbitraryDownloadableResource?
//          let observer: PropertyPathObserver = .observer(for: \App.State.downloadedData) {
//            observedData = $0
//          }
//          await logicModule.add(observer.modelObserver)
//
//          expect(observedData).to(beNil())
//
//          logicModule.handle(.completionOfDataDownload(.success(.init())))
//
//          expect(observedData).toNot(beNil())
//        }
//
//        it("observes state change triggered by side effect") {
//          let logicModule: App.LogicModule = .newInstance()
//          var observedData: App.ArbitraryDownloadableResource?
//          let observer: PropertyPathObserver = .observer(for: \App.State.downloadedData) {
//            observedData = $0
//          }
//          await logicModule.add(observer.modelObserver)
//
//          expect(observedData).to(beNil())
//
//          await logicModule.perform(.downloadOfData(from: URL(string: "fakeURL")!))
//
//          await expect(observedData).toEventuallyNot(beNil())
//        }
//
//        it("observes state change triggered by UI event") {
//          let (logicModule, view, _) = await App.LogicModule.newInstanceWithUI()
//          var observedData: App.ArbitraryDownloadableResource?
//          let dataObserver: PropertyPathObserver = .observer(for: \App.State.downloadedData) {
//            observedData = $0
//          }
//          await logicModule.add(dataObserver.modelObserver)
//
//          expect(observedData).to(beNil())
//
//          await view.handle(.downloadButtonPress)
//
//          await expect(observedData).toEventuallyNot(beNil())
//        }
//      }
//    }
//  }
//}
//
//private extension App.LogicModule {
//  static func newInstance() -> App.LogicModule {
//    let coeffects = App.Coeffects()
//    let model = App.Model(state: App.State(), reduce: App.reduce)
//    let sideEffectPerformer = App.SideEffectPerformer(
//      sideEffectClosure: App.sideEffectClosure(model.handle)
//    )
//
//    return App.LogicModule(
//      model: model,
//      sideEffectPerformer: sideEffectPerformer,
//      coeffects: coeffects,
//      staticObservers: []
//    )
//  }
//
//  static func newInstanceWithUI() async -> (App.LogicModule, App.MainView, Any) {
//    let coeffects = App.Coeffects()
//    let model = App.Model(state: App.State(), reduce: App.reduce)
//    let sideEffectPerformer = App.SideEffectPerformer(
//      sideEffectClosure: App.sideEffectClosure(model.handle)
//    )
//    let logicModule = App.LogicModule(
//      model: model,
//      sideEffectPerformer: sideEffectPerformer,
//      coeffects: coeffects,
//      staticObservers: []
//    )
//    let uiLogicModule = await logicModule.newUILogicModule()
//    let (view, observer) = await App.MainView.instance(
//      observing: \.self,
//      of: model,
//      using: coeffects
//    ) { event in
//      uiLogicModule.handle(event, given: model.state)
//    }
//
//    return (logicModule, view, observer)
//  }
//
//  private func newUILogicModule() -> App.UIEventLogicModule {
//    return self.viewLogic { event, state, then, _ in
//      switch event {
//      case .downloadButtonPress:
//        Task {
//          let result = await then.perform(.downloadOfData(from: URL(string: "fakeURL")!))
//
//          switch result {
//          case .success:
//            break
//          case let .failure(error):
//            print("Failed downloading data: \(error.localizedDescription)")
//          }
//        }
//      case .errorMessageView(.buttonPress):
//        self.handle(.dismissalOfErrorMessage)
//      }
//    }
//  }
//}
