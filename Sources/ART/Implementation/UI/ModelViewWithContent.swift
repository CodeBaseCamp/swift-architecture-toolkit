// Copyright © Rouven Strauss. MIT license.

import SwiftUI

/// Protocol to be implemented by views which can be updated by a corresponding view model.
public protocol ModelViewWithContent: ModelView {
  /// Type of the view of this instance.
  associatedtype Content: View

  /// Initializes with the given `context` and `content`.
  init(context: ViewContext<Model, Event, Coeffects>, content: @escaping () -> Content)
}

public extension ModelViewWithContent {
  /// Initializes with the given `context` and `content`.
  init(_ context: ViewContext<Model, Event, Coeffects>, content: @escaping () -> Content) {
    self.init(context: context, content: content)
  }

  init(context: ViewContext<Model, Event, Coeffects>) {
    self.init(context, content: { fatalError() })
  }
}
