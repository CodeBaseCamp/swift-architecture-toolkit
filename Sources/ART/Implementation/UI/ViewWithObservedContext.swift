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

public extension View {
  /// Returns a copy of the receiver created by applying the given `content` closure to the receiver and the given
  /// `context`. The returned view observes the given `context` and updates whenever its `model` changes by being
  /// recreated using the given `content` closure.
  ///
  /// - note: If the receiver is a `ModelView`, the `withObservedContext` method without the `context` parameter should
  ///         be used.
  @inlinable func withObservedContext<
    Model: Equatable,
    Event: Hashable,
    Coeffects: CoeffectsProtocol
  >(
    _ context: ViewContext<Model, Event, Coeffects>,
    @ViewBuilder content: @escaping (Self, ViewContext<Model, Event, Coeffects>) -> some View
  ) -> some View {
    ViewWithObservedContext(context) { context in
      content(self, context)
    }
  }
}

public extension ModelView {
  /// Returns a copy of the receiver created by applying the given `content` closure to the receiver. The returned view
  /// observes the given `context` and updates whenever its `model` changes by being recreated using the given `content`
  /// closure.
  ///
  /// - note: There is no need to use this method on a `ModelView` which is already observing its `context`.
  @inlinable func withObservedContext(
    @ViewBuilder content: @escaping (Self) -> some View
  ) -> some View {
    ViewWithObservedContext(self.context) { _ in
      content(self)
    }
  }
}
