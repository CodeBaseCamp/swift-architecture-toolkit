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

  var context: Context<Coeffects> { get }

  /// Initializes with the given `context`.
  init(context: Context<Coeffects>)
}

public extension ModelView {
  /// Initializes with the given `context`.
  init(_ context: Context<Coeffects>) {
    self.init(context: context)
  }

  init(withoutEvents context: ViewContext<Model, Never, Coeffects>) {
    self.init(context: context.context({ $0 }) { _ in fatalError("Must never be reached") })
  }

  var model: Model {
    return self.context.model
  }

  var coeffects: Coeffects {
    return self.context.coeffects
  }

  func handle(_ event: Event) {
    self.context.handle(event)
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
