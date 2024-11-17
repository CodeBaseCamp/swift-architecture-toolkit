// Copyright © Rouven Strauss. MIT license.

import SwiftUI

/// Protocol to be implemented by views which can be updated by a corresponding static view model.
public protocol StaticModelView: View {
  /// Type of the model of this instance.
  associatedtype Model: Equatable & Sendable

  /// Type of the events this instance can send.
  associatedtype Event: Hashable & Sendable

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

  func context<OtherModel: Equatable & Sendable, OtherEvent: Equatable>(
    _ modelTransformation: @escaping (Model) -> OtherModel,
    _ eventTransformation: @escaping (OtherEvent) -> Event
  ) -> StaticViewContext<OtherModel, OtherEvent, Coeffects> {
    return self.context.context(modelTransformation, eventTransformation)
  }

  func context<OtherModel: Equatable & Sendable>(
    _ modelTransformation: @escaping (Model) -> OtherModel
  ) -> StaticViewContext<OtherModel, Event, Coeffects> {
    return self.context.context(modelTransformation, { $0 })
  }

  func context<OtherModel: Equatable & Sendable, OtherEvent: Equatable>(
    _ model: OtherModel,
    _ eventTransformation: @escaping (OtherEvent) -> Event
  ) -> StaticViewContext<OtherModel, OtherEvent, Coeffects> {
    return self.context.context(model, eventTransformation)
  }

  func context<OtherModel: Equatable & Sendable>(
    _ model: OtherModel
  ) -> StaticViewContext<OtherModel, Event, Coeffects> {
    return self.context.context(model)
  }

  func context<OtherModel: Equatable & Sendable>(
    _ modelTransformation: @escaping (Model) -> OtherModel
  ) -> StaticViewContext<OtherModel, Never, Coeffects> {
    return self.context.context(modelTransformation)
  }
}
