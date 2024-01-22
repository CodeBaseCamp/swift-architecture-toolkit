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
@MainActor
class TaskBasedApp {
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
    _ handle: @escaping (Request, Coeffects) -> Void
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

final class TaskBasedUsageExampleSpec: AsyncSpec {
  override class func spec() {
    context("minimal example application") {
      context("setup") {
        it("sets up application with logic module") {
          let logicModule: TaskBasedApp.LogicModule = await .newInstance()
          _ = await TaskBasedApp(with: logicModule)
        }

        it("sets up application with logic module and UI") {
          let (logicModule, view, observer) = await TaskBasedApp.LogicModule.newInstanceWithUI()
          _ = await TaskBasedApp(with: logicModule)

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
          let logicModule: TaskBasedApp.LogicModule = await .newInstance()
          var observedData: App.ArbitraryDownloadableResource? = .init()
          let observer: PropertyPathObserver = .observer(
            for: \App.State.downloadedData,
            initiallyObservedValue: {
              observedData = $0
            }
          ) { _ in
            fatalErrorDueToMissingImplementation()
          }
          await logicModule.add(observer.modelObserver)

          expect(observedData).to(beNil())
        }

        it("observes state change triggered by request handling") {
          let logicModule: TaskBasedApp.LogicModule = await .newInstance()
          var observedData: App.ArbitraryDownloadableResource?
          let observer: PropertyPathObserver = .observer(for: \App.State.downloadedData) {
            observedData = $0
          }
          await logicModule.add(observer.modelObserver)

          expect(observedData).to(beNil())

          logicModule.handle(.completionOfDataDownload(.success(.init())))

          expect(observedData).toNot(beNil())
        }

        it("observes state change triggered by side effect") {
          let logicModule: TaskBasedApp.LogicModule = await .newInstance()
          var observedData: App.ArbitraryDownloadableResource?
          let observer: PropertyPathObserver = .observer(for: \App.State.downloadedData) {
            observedData = $0
          }
          await logicModule.add(observer.modelObserver)

          expect(observedData).to(beNil())

          await logicModule.perform(
            .only(.downloadOfData(from: URL(string: "fakeURL")!), on: .backgroundThread)
          )

          await expect(observedData).toEventuallyNot(beNil())
        }

        it("observes state change triggered by UI event") {
          let (logicModule, view, _) = await TaskBasedApp.LogicModule.newInstanceWithUI()
          var observedData: App.ArbitraryDownloadableResource?
          let dataObserver: PropertyPathObserver = .observer(for: \App.State.downloadedData) {
            observedData = $0
          }
          await logicModule.add(dataObserver.modelObserver)

          expect(observedData).to(beNil())

          view.handle(.downloadButtonPress)

          await expect(observedData).toEventuallyNot(beNil())
        }
      }
    }
  }
}

private extension TaskBasedApp.LogicModule {
  @MainActor
  static func newInstance() -> TaskBasedApp.LogicModule {
    let coeffects = TaskBasedApp.Coeffects()
    let model = TaskBasedApp.Model(state: TaskBasedApp.State(), reduce: TaskBasedApp.reduce)
    let sideEffectPerformer = TaskBasedApp.SideEffectPerformer(
      sideEffectClosure: TaskBasedApp.sideEffectClosure(model.handle)
    )

    return TaskBasedApp.LogicModule(
      model: model,
      sideEffectPerformer: sideEffectPerformer,
      coeffects: coeffects,
      staticObservers: []
    )
  }

  @MainActor
  static func newInstanceWithUI() async -> (TaskBasedApp.LogicModule, TaskBasedApp.MainView, Any) {
    let coeffects = TaskBasedApp.Coeffects()
    let model = TaskBasedApp.Model(state: TaskBasedApp.State(), reduce: TaskBasedApp.reduce)
    let sideEffectPerformer = TaskBasedApp.SideEffectPerformer(
      sideEffectClosure: TaskBasedApp.sideEffectClosure(model.handle)
    )
    let logicModule = TaskBasedApp.LogicModule(
      model: model,
      sideEffectPerformer: sideEffectPerformer,
      coeffects: coeffects,
      staticObservers: []
    )
    let uiLogicModule = await logicModule.newUILogicModule()
    let (view, observer) = TaskBasedApp.MainView.instance(
      observing: \.self,
      of: model,
      using: coeffects
    ) { event in
      Task {
        await uiLogicModule.handle(event, given: model.state)
      }
    }

    return (logicModule, view, observer)
  }

  @MainActor
  private func newUILogicModule() async -> TaskBasedApp.UIEventLogicModule {
    return self.viewLogic { event, state, then, _ in
      switch event {
      case .downloadButtonPress:
        Task {
          let result = await then.perform(
            .asynchronously(.downloadOfData(from: URL(string: "fakeURL")!), on: .backgroundThread)
          )

          switch result {
          case .success:
            break
          case let .failure(error):
            print("Failed downloading data: \(error.localizedDescription)")
          }
        }
      case .errorMessageView(.buttonPress):
        self.handle(.dismissalOfErrorMessage)
      }
    }
  }
}
