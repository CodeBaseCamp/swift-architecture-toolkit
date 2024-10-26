// Copyright © Rouven Strauss. MIT license.

import SwiftUI

/// Protocol to be implemented by views which can be updated by a corresponding view model.
public protocol ModelView: View {
  /// Type of the model of this instance.
  associatedtype Model: Equatable

  /// Type of the events this instance can send.
  associatedtype Event: Hashable

  /// Coeffects.
  associatedtype Coeffects: CoeffectsProtocol

  typealias Context<Coeffects: CoeffectsProtocol> = ViewContext<Model, Event, Coeffects>

  @MainActor
  var context: Context<Coeffects> { get }

  /// Initializes with the given `context`.
  @MainActor
  init(context: Context<Coeffects>)
}

public extension ModelView {
  /// Initializes with the given `context`.
  @MainActor
  init(_ context: Context<Coeffects>) {
    self.init(context: context)
  }

  @MainActor
  var model: Model {
    return self.context.model
  }

  @MainActor
  var coeffects: Coeffects {
    return self.context.coeffects
  }

  @MainActor
  func handle(_ event: Event) {
    self.context.handle(event)
  }

  @MainActor
  func contextIgnoringEvents<OtherModel: Equatable, OtherEvent: Equatable>(
    _ modelTransformation: @escaping (Model) -> OtherModel
  ) -> ViewContext<OtherModel, OtherEvent, Coeffects> {
    self.context.contextIgnoringEvents(modelTransformation)
  }
}

public extension ModelView {
  func ARTButton<T: View>(_ event: Event, _ label: () -> T) -> some View {
    SwiftUI.Button(
      action: {
        self.handle(event)
      },
      label: label
    )
  }
}

public extension StaticModelView {
  func ARTButton<T: View>(_ event: Event, _ label: () -> T) -> some View {
    SwiftUI.Button(
      action: {
        self.handle(event)
      },
      label: label
    )
  }
}
