// Copyright © Rouven Strauss. MIT license.

/// Protocol to be implemented by value objects serving as immmutable, equatable representation of
/// side effects, such as the storing of a file to disk, the starting of a device camera, or the
/// mutating interaction with an application object other than the dedicated application state.
public protocol SideEffectProtocol: Equatable, HumanReadable {}
