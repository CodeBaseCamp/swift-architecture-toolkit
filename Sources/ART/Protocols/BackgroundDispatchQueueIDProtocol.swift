// Copyright © Rouven Strauss. MIT license.

/// Protocol to be implemented by the IDs of `DispatchQueue` instances executing in the background.
public protocol BackgroundDispatchQueueIDProtocol: CaseIterable, Hashable, Sendable {}
