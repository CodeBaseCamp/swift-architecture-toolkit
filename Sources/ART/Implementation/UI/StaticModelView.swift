// Copyright © Rouven Strauss. MIT license.

import SwiftUI

/// Protocol to be implemented by views which can be updated by a corresponding static view model.
public protocol StaticModelView: View {
  /// Type of the model of this instance.
  associatedtype Model: Equatable

  /// Type of the events this instance can send.
  associatedtype Event: Hashable

  /// Coeffects.
  associatedtype Coeffects: CoeffectsProtocol

  typealias Context<Coeffects: CoeffectsProtocol> = StaticViewContext<Model, Event, Coeffects>

  var context: Context<Coeffects> { get }

  /// Initializes with the given `context`.
  init(context: Context<Coeffects>)
}

public extension StaticModelView {
  /// Initializes with the given `context`.
  init(_ context: Context<Coeffects>) {
    self.init(context: context)
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

  func staticContext<OtherModel: Equatable, OtherEvent: Equatable>(
    _ modelTransformation: @escaping (Model) -> OtherModel,
    _ eventTransformation: @escaping (OtherEvent) -> Event
  ) -> StaticViewContext<OtherModel, OtherEvent, Coeffects> {
    return self.context.staticContext(modelTransformation, eventTransformation)
  }

  func staticContext<OtherModel: Equatable, OtherEvent: Equatable>(
    _ model: OtherModel,
    _ eventTransformation: @escaping (OtherEvent) -> Event
  ) -> StaticViewContext<OtherModel, OtherEvent, Coeffects> {
    return self.context.staticContext(model, eventTransformation)
  }

  func staticContext<OtherModel: Equatable>(
    _ model: OtherModel
  ) -> StaticViewContext<OtherModel, Event, Coeffects> {
    return self.context.staticContext(model)
  }

  func staticEventlessContext<OtherModel: Equatable>(
    _ modelTransformation: @escaping (Model) -> OtherModel
  ) -> StaticViewContext<OtherModel, Never, Coeffects> {
    return self.context.staticEventlessContext(modelTransformation)
  }
}
