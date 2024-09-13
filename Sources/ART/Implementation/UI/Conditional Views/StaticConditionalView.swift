// Copyright © Rouven Strauss. MIT license.

import SwiftUI

/// View allowing for the conditional display of one of two views of type `NonOptionalContent0` and
/// `NonOptionalContent1`, respectively. The view has a `StaticViewContext`.
///
/// Inspired by `IfLetStore` of `The Composable Architecture`.
internal struct StaticConditionalView<
  Model: Equatable,
  Event: Hashable,
  Coeffects: CoeffectsProtocol,
  Content: View
>: View {
  internal typealias Context = StaticViewContext<Model, Event, Coeffects>
  internal typealias OptionalModelContext = StaticViewContext<Model?, Event, Coeffects>

  private let context: OptionalModelContext
  private let content: (OptionalModelContext) -> Content

  internal init<NonOptionalContent0, NonOptionalContent1>(
    _ context: OptionalModelContext,
    @ViewBuilder then nonOptionalContent0: @escaping (Context) -> NonOptionalContent0,
    @ViewBuilder else nonOptionalContent1: () -> NonOptionalContent1
  ) where Content == _ConditionalContent<NonOptionalContent0, NonOptionalContent1> {
    self.context = context

    let nonOptionalContent1 = nonOptionalContent1()
    self.content = { context in
      if var model: Model = context.model {
        return ViewBuilder.buildEither(
          first: nonOptionalContent0(
            context.context(
              {
                model = $0 ?? model
                return model
              },
              { $0 }
            )
          )
        )
      } else {
        return ViewBuilder.buildEither(second: nonOptionalContent1)
      }
    }
  }

  internal init<NonOptionalContent>(
    _ context: OptionalModelContext,
    @ViewBuilder then nonOptionalContent: @escaping (Context) -> NonOptionalContent
  ) where Content == NonOptionalContent? {
    self.context = context
    self.content = { context in
      if var model: Model = context.model {
        return nonOptionalContent(
          context.context(
            {
              model = $0 ?? model
              return model
            },
            { $0 }
          )
        )
      } else {
        return nil
      }
    }
  }

  internal var body: some View {
    self.content(self.context)
  }
}
