// Copyright © Rouven Strauss. MIT license.

import SwiftUI

/// View observing a given `ViewContext` and wrapping another view of type `Content` which is recreated using changes of
/// aforementioned context.
public struct ViewWithObservedContext<
  Model: Equatable,
  Event: Hashable,
  Coeffects: CoeffectsProtocol,
  Content: View
>: View {
  /// Context of this view.
  public typealias Context = ViewContext<Model, Event, Coeffects>

  @ObservedObject
  private var context: Context

  private let content: (Context) -> Content

  /// Initializes with the given `context` and the given `content` closure. Upon changes of the `model` of the given
  /// `context`, the given `content` closure is invoked.
  public init(
    _ context: Context,
    @ViewBuilder content: @escaping (Context) -> Content
  ) {
    self.context = context
    self.content = content
  }

  public var body: some View {
    self.content(self.context)
  }
}
