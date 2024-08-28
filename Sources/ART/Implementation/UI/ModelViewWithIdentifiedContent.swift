// Copyright © Rouven Strauss. MIT license.

import SwiftUI

/// Protocol to be implemented by views which can be updated by a corresponding view model and which rely on identified
/// views.
public protocol ModelViewWithIdentifiedContent: ModelView {
  /// Type of the view of this instance.
  associatedtype Content: View

  /// Unique identifier of a view of type `Content`.
  associatedtype ID: Hashable

  /// Initializes with the given `context` and `content`.
  init(context: ViewContext<Model, Event, Coeffects>, content: @escaping (ID) -> Content)
}

public extension ModelViewWithIdentifiedContent {
  /// Initializes with the given `context` and `content`.
  init(_ context: ViewContext<Model, Event, Coeffects>, content: @escaping (ID) -> Content) {
    self.init(context: context, content: content)
  }

  init(context: ViewContext<Model, Event, Coeffects>) {
    self.init(context, content: { _ in fatalError() })
  }
}
