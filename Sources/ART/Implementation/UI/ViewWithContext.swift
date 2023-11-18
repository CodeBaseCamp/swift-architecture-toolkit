// Copyright © Rouven Strauss. MIT license.

import SwiftUI

public struct ViewWithContext<
  Model: Equatable,
  Event: Hashable,
  Coeffects: CoeffectsProtocol,
  Content: View
>: View {
  public typealias Context = ViewContext<Model, Event, Coeffects>

  @ObservedObject
  private var context: Context

  private let content: (Context) -> Content

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
