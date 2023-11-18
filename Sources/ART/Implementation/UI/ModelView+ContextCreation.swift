// Copyright © Rouven Strauss. MIT license.

import SwiftUI

public extension ModelView {
  func context<OtherModel: Equatable, OtherEvent: Equatable>(
    _ modelTransformation: @escaping (Model) -> OtherModel,
    _ eventTransformation: @escaping (OtherEvent) -> Event
  ) -> ViewContext<OtherModel, OtherEvent, Coeffects> {
    return self.context.context(modelTransformation, eventTransformation)
  }

  func context<OtherModel: Equatable>(
    _ modelTransformation: @escaping (Model) -> OtherModel,
    _ event: Event
  ) -> ViewContext<OtherModel, Event, Coeffects> {
    return self.context.context(modelTransformation, event)
  }

  // Eventless context.

  func eventlessContext<OtherModel: Equatable>(
    _ modelTransformation: @escaping (Model) -> OtherModel
  ) -> ViewContext<OtherModel, Never, Coeffects> {
    return self.context.eventlessContext(modelTransformation)
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
