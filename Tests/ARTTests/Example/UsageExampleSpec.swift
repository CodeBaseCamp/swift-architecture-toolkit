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

  init(with logicModule: LogicModule) {
    self.logicModule = logicModule
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
    _ handle: @escaping (Request, Coeffects) -> Void
  ) -> SideEffectPerformer.SideEffectClosure {
    return { sideEffect, coeffects, completion in
      switch sideEffect {
      case .downloadOfData:
        // For the sake of the example, success in downloading the data is assumed.
        handle(.completionOfDataDownload(.success(App.ArbitraryDownloadableResource())), coeffects)
        completion(.success)
      }
    }
  }

  /// Function implementing the UI event handling.
  fileprivate static func eventClosure(
    _ logicModule: LogicModule
  ) -> (MainView.Event) -> Void {
    return { event in
      switch event {
      case .downloadButtonPress:
        logicModule.perform(
          .asynchronously(.downloadOfData(from: URL(string: "fakeURL")!), on: .backgroundThread)
        ) {
          switch $0 {
          case .success:
            break
          case let .failure(error):
            print("Failed downloading data: \(error.localizedDescription)")
          }
        }
      case .errorMessageView(.buttonPress):
        logicModule.handle(.dismissalOfErrorMessage)
      }
    }
  }
}

final class UsageExampleSpec: QuickSpec {
  override class func spec() {
    context("minimal example application") {
      context("setup") {
        it("sets up application with logic module") {
          let logicModule: LogicModule = .newInstance()
          _ = App(with: logicModule)
        }

        it("sets up application with logic module and UI") {
          let (logicModule, view, observer) = LogicModule.newInstanceWithUI()
          _ = App(with: logicModule)

          connect(view)

          // Make sure to hold hold observer strongly to allow for UI updates.
          holdStrongly(observer)
        }

        // Dummy functions for example purposes.

        func connect(_ view: App.MainView) {}
        func holdStrongly(_ observer: Any) {}
      }

      context("state update and observation") {
        it("observes current state when adding observer") {
          let logicModule: LogicModule = .newInstance()
          var observedData: App.ArbitraryDownloadableResource? = .init()
          let observer: PropertyPathObserver = .observer(
            for: \App.State.downloadedData,
            initiallyObservedValue: {
              observedData = $0
            }
          ) { _ in
            fatalErrorDueToMissingImplementation()
          }
          logicModule.add(observer.modelObserver)

          expect(observedData).to(beNil())
        }

        it("observes state change triggered by request handling") {
          let logicModule: LogicModule = .newInstance()
          var observedData: App.ArbitraryDownloadableResource?
          let observer: PropertyPathObserver = .observer(for: \App.State.downloadedData) {
            observedData = $0
          }
          logicModule.add(observer.modelObserver)

          expect(observedData).to(beNil())

          logicModule.handle(.completionOfDataDownload(.success(.init())))

          expect(observedData).toNot(beNil())
        }

        it("observes state change triggered by side effect") {
          let logicModule: LogicModule = .newInstance()
          var observedData: App.ArbitraryDownloadableResource?
          let observer: PropertyPathObserver = .observer(for: \App.State.downloadedData) {
            observedData = $0
          }
          logicModule.add(observer.modelObserver)

          expect(observedData).to(beNil())

          logicModule.perform(
            .only(.downloadOfData(from: URL(string: "fakeURL")!), on: .backgroundThread)
          )

          expect(observedData).toEventuallyNot(beNil())
        }

        it("observes state change triggered by UI event") {
          let (logicModule, view, _) = LogicModule.newInstanceWithUI()
          var observedData: App.ArbitraryDownloadableResource?
          let dataObserver: PropertyPathObserver = .observer(for: \App.State.downloadedData) {
            observedData = $0
          }
          logicModule.add(dataObserver.modelObserver)

          expect(observedData).to(beNil())

          view.handle(.downloadButtonPress)

          expect(observedData).toEventuallyNot(beNil())
        }
      }
    }
  }
}

private extension App.LogicModule {
  static func newInstance() -> App.LogicModule {
    let coeffects = App.Coeffects()
    let model = App.Model(state: App.State(), reduce: App.reduce)
    let sideEffectPerformer = App.SideEffectPerformer(
      sideEffectClosure: App.sideEffectClosure(model.handle)
    )

    return LogicModule(
      model: model,
      sideEffectPerformer: sideEffectPerformer,
      coeffects: coeffects,
      staticObservers: []
    )
  }

  static func newInstanceWithUI() -> (App.LogicModule, App.MainView, Any) {
    let coeffects = App.Coeffects()
    let model = App.Model(state: App.State(), reduce: App.reduce)
    let sideEffectPerformer = App.SideEffectPerformer(
      sideEffectClosure: App.sideEffectClosure(model.handle)
    )
    let logicModule = LogicModule(
      model: model,
      sideEffectPerformer: sideEffectPerformer,
      coeffects: coeffects,
      staticObservers: []
    )

    let (view, observer) = App.MainView.instance(
      observing: \.self,
      of: model,
      using: coeffects,
      handlingEventsWith: App.eventClosure(logicModule)
    )

    return (logicModule, view, observer)
  }
}
